Rails.application.routes.draw do
  mount FlynnAutoScale::Engine => "/flynn_auto_scale"
end
