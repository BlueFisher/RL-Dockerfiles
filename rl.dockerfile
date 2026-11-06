ARG CUDA_VERSION=13.0.3

FROM nvidia-egl-base:3.1-${CUDA_VERSION}

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates \
    socat \
    libglib2.0-0 libxext6 libsm6 libxrender1 git \
    # mujoco dependence
    libglew-dev patchelf \  
    inetutils-ping pciutils \
    tmux && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install python3.11 -y && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

RUN ln -s /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

RUN pip install torch==2.14.1 torchvision==0.29.1 --index-url https://download.pytorch.org/whl/cu126 && \
    pip cache purge

RUN pip install tensorboard matplotlib gymnasium \
    opencv-python tqdm pillow pyyaml grpcio grpcio-tools requests beautifulsoup4 scikit-learn sentence-transformers && \
    pip cache purge

RUN pip list

EXPOSE 6006

ENTRYPOINT ["/etc/entrypoint_sshd.sh"]
