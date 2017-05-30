require "flynn_auto_scale/engine"
require "os"

module FlynnAutoScale
  class Scaler < Rails::Engine
    # START Setup Section
    def check_install
      # Check for existence of Flynn inside container.
      output = `flynn`
      if output.include? "usage: flynn"
        true
      else
        false
      end
    end
    
    def install
      # Install the Flynn CLI if it doesn't exist.
      if !check_install
        Logger.warn "Flynn Auto-Scale: Installing the Flynn CLI. This will take some time. This installer only works under Linux / Mac OS X."
        `L=/usr/local/bin/flynn && curl -sSL -A "\`uname -sp\`" https://dl.flynn.io/cli | zcat >$L && chmod +x $L`
        check_install
      else
        true
      end
    end
    
    def connect_cluster
      # Connect to the cluster and set as default.
      if !install
        # Warn the user something has gone terribly wrong.
        Logger.warn "Flynn Auto-Scale: There was an issue installing / verifying the Flynn installation. Auto Scaling functions will not work."
        false
      else
        # The bare minimum needed to connect to a cluster and manual scaling
        vars = [
        ENV['FLYNN_SETUP_CLUSTER_PIN'],
        ENV['FLYNN_SETUP_CLUSTER_NAME'],
        ENV['FLYNN_SETUP_CLUSTER_CONTROLLER_DOMAIN'],
        ENV['FLYNN_SETUP_CLUSTER_CONTROLLER_KEY'],
        ENV['FLYNN_SETUP_CLUSTER_APP_NAME']]
        
        # Verify the existance of all of the required variables.
        missing_vars = false
        vars.each do |var|
          if !var.present?
            Logger.warn "Flynn Auto-Scale: One of the environment variables required for connecting to the cluster is missing. Initialization will stop immediately."
            missing_vars = true
          end
        end
        
        # Abort if there are missing variables.
        if missing_vars
          return false
        end
        
        # Connect to the cluster.
        # Warning: this method of adding / defaulting the cluster is susceptible to Command Injection.
        # Do not pass params from the internet into any of this (you were warned!)
        # Source: http://brakemanscanner.org/docs/warning_types/command_injection/
        `flynn cluster add -p #{vars[0]} #{vars[1]} #{vars[2]} #{vars[3]}`
        
        output = `flynn cluster default #{vars[4]}`
        if !output.include? "is now the default cluster."
          Logger.warn "Flynn Auto-Scale: There was an issue connecting to the cluster. Please provide this output in a Github Issue: #{output}"
          false
        else
          true
        end
      end
    end
    # END Setup Section
    
    # START Auto Scaling Section
    def auto_scale(process='web')
      # This method will utilize the current RAM usage and some ENV variables to make a scaling decision.
      if !ENV['FLYNN_AUTO_SCALE'].present?
        Logger.warn "Flynn Auto-Scale: A call was made to the auto_scale method but the FLYNN_AUTO_SCALE ENV variable is not set. Nothing will be done."
        return
      end
      
      current_ram_use = (OS.rss_bytes / 1024).to_i
      max_ram_use = ENV['FLYNN_AUTO_SCALE_RAM'].present? ? ENV['FLYNN_AUTO_SCALE_RAM'].present?.to_i : 256
      
      if current_ram_use > max_ram_use
        # Consider scaling upwards.
        scale_up(process)
      elsif current_ram_use < (max_ram_use * 0.1).to_i
        # This is a hardcoded attempt at a "downscale".
        # We will attempt to shrink the instance count if using less than 10% of the max ram.
        scale_down(process)
      else
        # There is no need to execute a scale up / down event.
        return
      end
    end
    # END Auto Scaling Section
    
    # START Maintenance Section
    def can_scale_time(process='web')
      # Checks if scaling is appropriate or if it's limited by a time minimum.
      last_scale = FlynnAutoScale::ScalingEvent.where(process_type: process).last
      scaling_restriction = ENV['FLYNN_AUTO_SCALE_COOLDOWN'].present?
      
      if scaling_restriction
        if !last_scale
          # If this is the first time this process is scaled, just ignore the limit and push an initial scaling event into the DB.
          last_scale = FlynnAutoScale::ScalingEvent.create(process_type: process, event_type: 'initial', instances: 1)
          true
        else
          # Calculate if we have breached the cooldown.
          current_time = DateTime.now
          last_time = last_scale.created_at
          diff = (current_time.to_f - last_time.to_f).to_i
          
          # Scaling operations should occur if the cooldown has elapsed.
          if diff > ENV['FLYNN_AUTO_SCALE_COOLDOWN'].to_i
            true
          else
            false
          end
        end
      else
        # No limit, just scale.
        true
      end
    end
    def scale_up(process='web')
      # This method will scale the process count up. It assumes it was called from an "AUTO_SCALE" setup.
      if can_scale_time
        scale(process, FlynnAutoScale::ScalingEvent.where(process_type: process).last.instances + 1, 'scale_up')
      else
        Logger.warn "Flynn Auto-Scale: A scale_up event was aborted due to a time limitation."
      end
    end
    
    def scale_down(process='web')
      # This method will scale the process count down. It assumes it was called from an "AUTO_SCALE" setup.
      if can_scale_time
        scale(process, FlynnAutoScale::ScalingEvent.where(process_type: process).last.instances - 1, 'scale_down')
      else
        Logger.warn "Flynn Auto-Scale: A scale_down event was aborted due to a time limitation."
      end
    end
    
    def scale_manual(process='web', instances=1)
      # This method will just scale the process. 
      # This method will respect very little restrictions, make sure you know what this does.
      scale(process, instances)
    end
    
    # The foundation of the auto / manual scaling system.
    # You should not be calling this method unless you know what you are doing.
    def scale(process='web', instances=1, event_type='manual')
      if event_type == 'manual' && !ENV['FLYNN_LIMIT_INSTANCES_MANUAL_MODE'].present?
        # If the instances are not limited in manual mode, just let it rip (doesn't wait for confirmation)
        FlynnAutoScale::ScalingEvent.create(process_type: process, event_type: event_type, instances: instances)
        `flynn -a #{ENV['FLYNN_SETUP_CLUSTER_APP_NAME']} scale #{process}=#{instances} -n`
      else
        # This section is active in auto mode and in manual mode with limitations.
        if ENV['FLYNN_MIN_INSTANCES'].present? && ENV['FLYNN_MAX_INSTANCES'].present? 
          if instances < ENV['FLYNN_MIN_INSTANCES'].to_i
            Logger.warn "Flynn Auto-Scale: A scale event was stopped due to being below the minimum instance count"
            return
          end
          
          # Do the min and max instance checks
            
          if instances > ENV['FLYNN_MAX_INSTANCES'].to_i
            Logger.warn "Flynn Auto-Scale: A scale event was stopped due to being above the maximum instance count"
            return
          end
        elsif ENV['FLYNN_MIN_INSTANCES'].present?
          # Do the min instance check
          if instances < ENV['FLYNN_MIN_INSTANCES'].to_i
            Logger.warn "Flynn Auto-Scale: A scale event was stopped due to being below the minimum instance count"
            return
          end
        elsif ENV['FLYNN_MAX_INSTANCES'].present?
          # Do the max instance check
          if instances > ENV['FLYNN_MAX_INSTANCES'].to_i
            Logger.warn "Flynn Auto-Scale: A scale event was stopped due to being above the maximum instance count"
            return
          end
        elsif instances < 1 || instances > 2
          Logger.warn "Flynn Auto-Scale: A scale event was stopped due to exceeding the default values"
          return
        end
        # Okay, we checked, it's a good scaling event, hold on to your butts.
        FlynnAutoScale::ScalingEvent.create(process_type: process, event_type: event_type, instances: instances)
        `flynn -a #{ENV['FLYNN_SETUP_CLUSTER_APP_NAME']} scale #{process}=#{instances} -n`
      end
    end
    # END Maintenance Section
  end
end
