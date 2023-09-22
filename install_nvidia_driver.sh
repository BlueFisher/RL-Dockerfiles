#!/bin/bash -e

trap "echo TRAPed signal" HUP INT QUIT KILL TERM

# Install NVIDIA drivers, including X graphic drivers by omitting --x-{prefix,module-path,library-path,sysconfig-path}
if ! command -v nvidia-xconfig &> /dev/null; then
  cd /tmp
  sh NVIDIA-Linux-x86_64-$DRIVER_VERSION.run -x
  cd NVIDIA-Linux-x86_64-$DRIVER_VERSION
  ./nvidia-installer --silent \
                    --no-kernel-module \
                    --install-compat32-libs \
                    --no-nouveau-check \
                    --no-nvidia-modprobe \
                    --no-rpms \
                    --no-backup \
                    --no-check-for-alternate-installs \
                    --no-libglx-indirect \
                    --no-install-libglvnd
  rm -rf /tmp/NVIDIA* && cd ~
fi

if grep -Fxq "allowed_users=console" /etc/X11/Xwrapper.config; then
  sed -i "s/allowed_users=console/allowed_users=anybody/;$ a needs_root_rights=yes" /etc/X11/Xwrapper.config
fi

if [ -f "/etc/X11/xorg.conf" ]; then
  rm "/etc/X11/xorg.conf"
fi