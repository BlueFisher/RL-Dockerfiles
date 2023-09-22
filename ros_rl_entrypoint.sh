#!/bin/bash -i
set -e

pip install -e /data/ros_ugv
pip install -e /data/asac

exec "$@"
