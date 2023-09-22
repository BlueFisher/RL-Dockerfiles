ARG UBUNTU_RELEASE=20.04
ARG CUDA_VERSION=11.4.1
ARG DRIVER_VERSION=525.85.12

FROM nvidia-glx-base:3.2-${UBUNTU_RELEASE}-${CUDA_VERSION}-${DRIVER_VERSION}

LABEL version "7.2-${DRIVER_VERSION}"

# miniconda
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH /opt/conda/bin:$PATH

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates \
    libglib2.0-0 libxext6 libsm6 libxrender1 git \
    # mujoco dependence
    libglew-dev patchelf \  
    inetutils-ping pciutils && \
    rm -rf /var/lib/apt/lists/*

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py38_23.3.1-0-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh && \
    /opt/conda/bin/conda clean -ay && \
    ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc && \
    echo "conda activate base" >> ~/.bashrc && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate base && \
    conda install -y pytorch torchvision pytorch-cuda=11.7 -c pytorch -c nvidia && \
    conda clean -apy

RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate base && \
    conda install -y gymnasium \
    tensorboard matplotlib pillow pyyaml numpy grpcio requests beautifulsoup4 scikit-learn -c conda-forge && \
    conda clean -apy

# dm-control 依赖有问题

RUN conda list

EXPOSE 22
EXPOSE 8080
EXPOSE 6006 6007
EXPOSE 61000 61001 61002

ENTRYPOINT ["/etc/bootstrap_sshd.sh"]

# RLVERSION=7.2
# DRIVER_VERSION=470.57.02
# DRIVER_VERSION=525.85.12
# DRIVER_VERSION=535.104.05

# docker build . -t rl:${RLVERSION}-${DRIVER_VERSION} -f rl.dockerfile --network=host --build-arg DRIVER_VERSION=${DRIVER_VERSION} --build-arg "http_proxy=http://192.168.3.2:10809/" --build-arg "https_proxy=http://192.168.3.2:10809/"

# docker save -o ./rl-${RLVERSION}-${DRIVER_VERSION}.tar rl:${RLVERSION}-${DRIVER_VERSION}

# scp rl-${RLVERSION}-${DRIVER_VERSION}.tar cs@10.0.6.249:/home/cs/

# docker load -i ./rl-${RLVERSION}-${DRIVER_VERSION}.tar

# docker run -it --rm --entrypoint=bash rl:${RLVERSION}-${DRIVER_VERSION}
# docker run -it -v /root/test:/data -p 31631:22 -p 30711:8080 -p 32295:6006 --shm-size="64g" rl:${RLVERSION}-${DRIVER_VERSION}
