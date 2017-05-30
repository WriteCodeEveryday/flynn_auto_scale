Warning: This gem is in active development and may have some serious bugs.

# FlynnAutoScale
A gem that allows your Rails apps to self-scale as they need more and more resources under [Flynn](https://flynn.io/). Comes with an automated mode that can be used for "day to day" web hosting operations and a manual mode where you can control when scaling operations take place (for scripts, background jobs and anything else)

## Installation
Add this line to your application's Gemfile:

```ruby
gem 'flynn_auto_scale'
```

And then execute:
```bash
$ bundle
```

Make sure to migrate after installing this gem (it makes use of ActiveRecord to keep the autoscaler working)

In order to get up and running quickly, please set up the following ENV variables.
Failure to set up some of these could cause "bad things to happen", so ensure you read this section.

    # These are the minimum required items for [connecting to a cluster](https://flynn.io/docs/cli#adding-clusters)
    FLYNN_SETUP_CLUSTER_PIN
    FLYNN_SETUP_CLUSTER_NAME
    FLYNN_SETUP_CLUSTER_CONTROLLER_DOMAIN
    FLYNN_SETUP_CLUSTER_CONTROLLER_KEY
    FLYNN_SETUP_CLUSTER_APP_NAME - the app name to be scaled.


    # These are configuration variables that are used to customize how FlynnAutoScale will handle scaling events.
    FLYNN_AUTO_SCALE - If present, FlynnAutoScale will attempt auto scaling operations -> (default: do nothing)
    FLYNN_AUTO_SCALE_RAM - The amount of RAM in MB you'd like FlynnAutoScale to consider scaling at -> (default: 256)
    FLYNN_AUTO_SCALE_COOLDOWN - How long to wait after you have scaled (in seconds) before scaling again -> (default: 0)
    FLYNN_LIMIT_INSTANCES_MANUAL_MODE - If present, whether manual mode should follow the instance limits -> (default: ignore limits)
    FLYNN_MIN_INSTANCES - Minimum number of instances -> (default: 1)
    FLYNN_MAX_INSTANCES - Maximum number of instances -> (default: 2)
    
Add the following at the top of your application_controller.rb to get started with auto scaling.

```ruby
# This should be a single line
around_action def scale; yield; FlynnAutoScale::Scaler.auto_scale('web'); end
```

## Usage
For a more advanced use of the scaler, you can directly call the manual scaler yourself.
```ruby
# You can pass the process name: 'console', 'web', 'worker'.
FlynnAutoScale::Scaler.scale_manual('web', 2)
```
## Contributing
It's an open source repo, fork the thing, make some changes, and I'll put you on the list of cool people making Flynn + Rails great again.

I am also looking for a partner in crime or two to turn that database of scaling changes into a nice dashboard (a la sidekiq's web_ui). I can do it, but it's gonna be super butt ugly if I do it alone.

## License
The gem is available as open source under the CC0 terms.
