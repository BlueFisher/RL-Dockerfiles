FROM nvidia/cuda:12.0.0-cudnn8-runtime-ubuntu20.04
LABEL maintainer "Fisher <blue_fisher@qq.com>"
LABEL version "1.1"

# Make all NVIDIA GPUs visible, but we want to manually install drivers
ARG NVIDIA_VISIBLE_DEVICES=all
# Supress interactive menu while installing keyboard-configuration
ARG DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_DRIVER_CAPABILITIES all

ENV TZ Asia/Shanghai
ENV PASSWD 1234

RUN rm /etc/apt/sources.list.d/cuda.list && \
    cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY sources20.04.list /etc/apt/sources.list

# Install locales to prevent errors
RUN apt-get clean && \
    apt-get update && apt-get install --no-install-recommends -y locales && \
    rm -rf /var/lib/apt/lists/* && \
    locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    cmake \
    build-essential \
    curl \
    wget \
    gnupg2 \
    lsb-release \
    ca-certificates \
    iputils-ping && \
    rm -rf /var/lib/apt/lists/*

RUN echo "deb http://mirrors.tuna.tsinghua.edu.cn/ros/ubuntu/ focal main" > /etc/apt/sources.list.d/ros-latest.list && \
    curl -sSL 'http://keyserver.ubuntu.com/pks/lookup?op=get&search=0xC1CF6E31E6BADE8868B172B4F42ED6FBAB17C654' | apt-key add -

# install ros packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    ros-noetic-ros-base ros-noetic-cv-bridge ros-noetic-tf && \
    rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3-pip python3-opencv python3-tk && \
    rm -rf /var/lib/apt/lists/* && \
    ln -s /usr/bin/python3 /usr/bin/python

RUN pip install torch torchvision

RUN pip install matplotlib tensorboard

# Set root with password ${PASSWD}
RUN echo "root:${PASSWD}" | chpasswd && \
    ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime && echo "$TZ" > /etc/timezone

# Install ssh-server
RUN apt-get update && apt-get install -y openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /var/run/sshd && \
    sed -ri 's/^#?PermitRootLogin\s+.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config
ADD authorized_keys /root/.ssh/authorized_keys
RUN chmod 644 /root/.ssh/authorized_keys

RUN echo "source /data/ros_ws/devel/setup.bash" >> ~/.bashrc && \
    echo "export ROS_MASTER_URI=http://n605-master:11311" >> ~/.bashrc && \
    echo "export ROS_HOSTNAME=n605-master" >> ~/.bashrc && \
    echo 'export ROS_NAMESPACE=`echo $(hostname) | tr '-' '_'`' >> ~/.bashrc

ENTRYPOINT ["/usr/sbin/sshd", "-D"]


# docker build . -t ros-rl:1.1 -f ros-rl.dockerfile --network=host --build-arg "http_proxy=http://192.168.3.2:10809/" --build-arg "https_proxy=http://192.168.3.2:10809/"

# xhost +local:*
# sudo docker run -d --gpus=all --network=host -e DISPLAY=$DISPLAY -v /home/n705/ros_docker_data:/data -v /tmp/.X11-unix/:/tmp/.X11-unix/ --name dev-zzy ros-rl:1.1 -p 2222
# sudo docker run -it --gpus=all --rm --network=host -e DISPLAY=$DISPLAY -v /home/n705/ros_docker_data:/data -v /tmp/.X11-unix/:/tmp/.X11-unix/ --hostname LM-693 --entrypoint /data/ros_rl_entrypoints.sh ros-rl:1.1 bash