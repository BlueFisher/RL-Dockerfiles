#!/bin/bash -e

/etc/entrypoint.sh

/usr/sbin/sshd -D
