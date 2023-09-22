ARG UBUNTU_RELEASE=20.04
ARG CUDA_VERSION=11.4.1

FROM nvidia/cudagl:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_RELEASE}

LABEL maintainer "Fisher <blue_fisher@qq.com>"

ARG UBUNTU_RELEASE
ARG CUDA_VERSION

LABEL version "3.2-${UBUNTU_RELEASE}-${CUDA_VERSION}"

# Make all NVIDIA GPUs visible by default
ARG NVIDIA_VISIBLE_DEVICES=all
# Use noninteractive mode to skip confirmation when installing packages
ARG DEBIAN_FRONTEND=noninteractive
# All NVIDIA driver capabilities should preferably be used, check `NVIDIA_DRIVER_CAPABILITIES` inside the container if things do not work
ENV NVIDIA_DRIVER_CAPABILITIES all
# Enable AppImage execution in a container
ENV APPIMAGE_EXTRACT_AND_RUN 1
# System defaults that should not be changed
ENV DISPLAY :0
ENV XDG_RUNTIME_DIR /tmp/runtime-user
ENV PULSE_SERVER unix:/run/pulse/native
ENV LD_LIBRARY_PATH /usr/lib/x86_64-linux-gnu:/usr/lib/i386-linux-gnu${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

# Default environment variables (password is "1234")
ENV TZ Asia/Shanghai
ENV SIZEW 1920
ENV SIZEH 1080
ENV REFRESH 60
ENV DPI 96
ENV CDEPTH 24
ENV VIDEO_PORT DFP
ENV PASSWD 1234

RUN rm /etc/apt/sources.list.d/cuda.list && \
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY sources${UBUNTU_RELEASE}.list /etc/apt/sources.list

# Install locales to prevent errors
RUN apt-get clean && \
    apt-get update && apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Install Xorg, and others
RUN dpkg --add-architecture i386 && \
    apt-get update && apt-get install --no-install-recommends -y \
        software-properties-common \
        apt-utils \
        build-essential \
        ca-certificates \
        kmod \
        libc6:i386 \
        libc6-dev \
        curl \
        file \
        wget \
        gzip \
        zip \
        unzip \
        gcc \
        git \
        jq \
        make \
        python \
        python-numpy \
        python3 \
        python3-numpy \
        mlocate \
        nano \
        vim \
        htop \
        net-tools \
        libpci3 \
        libelf-dev \
        libglvnd-dev \
        pkg-config \
        mesa-utils \
        mesa-utils-extra \
        libglu1 \
        libglu1:i386 \
        libsm6 \
        libxv1 \
        libxv1:i386 \
        libxtst6 \
        libxtst6:i386 \
        x11-xkb-utils \
        x11-xserver-utils \
        x11-apps \
        dbus-x11 \
        libdbus-c++-1-0v5 \
        xauth \
        xinit \
        xfonts-base \
        xkb-data \
        libxrandr-dev \
        xorg-dev \
        xserver-xorg-core && \
    if [ "${UBUNTU_RELEASE}" = "18.04" ]; then apt-get install --no-install-recommends -y vulkan-utils; else apt-get install --no-install-recommends -y vulkan-tools; fi && \
    # Remove Bluetooth packages that throw errors
    apt-get autoremove --purge -y \
        blueman \
        pulseaudio-module-bluetooth && \
    rm -rf /var/lib/apt/lists/*

# Install latest noVNC web interface for fallback
ARG X11VNC_VERSION=0.9.16
ARG NOVNC_VERSION=1.3.0
RUN apt-get update && apt-get install --no-install-recommends -y \
        autoconf \
        automake \
        autotools-dev \
        chrpath \
        debhelper \
        jq \
        python \
        python-numpy \
        python3 \
        python3-numpy \
        libc6-dev \
        libcairo2-dev \
        libjpeg-turbo8-dev \
        libssl-dev \
        libv4l-dev \
        libvncserver-dev \
        libtool-bin \
        libxdamage-dev \
        libxinerama-dev \
        libxrandr-dev \
        libxss-dev \
        libxtst-dev \
        libavahi-client-dev && \
    rm -rf /var/lib/apt/lists/* && \
    curl -fsSL https://github.com/LibVNC/x11vnc/archive/refs/tags/${X11VNC_VERSION}.tar.gz | tar -xzf - -C /tmp && \
    cd /tmp/x11vnc-${X11VNC_VERSION} && autoreconf -fi && ./configure && make install && cd / && rm -rf /tmp/* && \
    curl -fsSL https://github.com/novnc/noVNC/archive/v${NOVNC_VERSION}.tar.gz | tar -xzf - -C /opt && \
    mv /opt/noVNC-${NOVNC_VERSION} /opt/noVNC && \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify

# Set root with password ${PASSWD}
RUN echo "root:${PASSWD}" | chpasswd && \
    rm -rf /tmp/.X* && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

# Install ssh-server
RUN apt-get update && apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
ADD authorized_keys /root/.ssh/authorized_keys
RUN chmod 644 /root/.ssh/authorized_keys

ARG DRIVER_VERSION
LABEL version "3.2-${UBUNTU_RELEASE}-${CUDA_VERSION}-${DRIVER_VERSION}"

COPY install_nvidia_driver.sh /etc/install_nvidia_driver.sh
COPY NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run /tmp/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
RUN chmod 755 /etc/install_nvidia_driver.sh && /etc/install_nvidia_driver.sh

COPY bootstrap.sh /etc/bootstrap.sh
RUN chmod 755 /etc/bootstrap.sh

COPY bootstrap_sshd.sh /etc/bootstrap_sshd.sh
RUN chmod 755 /etc/bootstrap_sshd.sh

ENTRYPOINT ["/etc/bootstrap.sh"]

# DRIVER_VERSION=470.57.02
# DRIVER_VERSION=525.85.12
# DRIVER_VERSION=535.104.05

# docker build . -t nvidia-glx-base:3.2-20.04-11.4.1-${DRIVER_VERSION} -f nvidia-glx-base.dockerfile --network=host --build-arg DRIVER_VERSION=${DRIVER_VERSION} --build-arg "http_proxy=http://192.168.3.2:10809/" --build-arg "https_proxy=http://192.168.3.2:10809/"

# docker run -it --rm nvidia-glx-base:3.2-20.04-11.4.1-${DRIVER_VERSION}
