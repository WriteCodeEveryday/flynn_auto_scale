# This initializer will attempt to connect to the cluster as soon as the app is brought online.
# The internals of the gem should prevent errors but if you get an error, just comment out this line.
FlynnAutoScale::Scaler.connect_cluster
