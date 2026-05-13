ARG CUDA_VERSION=13.1.2

FROM nvidia-egl-base:3.1-${CUDA_VERSION}

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

RUN apt-get update --fix-missing && \
    apt-get install -y wget bzip2 ca-certificates \
    socat \
    libglib2.0-0 libxext6 libsm6 libxrender1 git \
    # mujoco dependence
    libglew-dev patchelf \  
    inetutils-ping pciutils && \
    rm -rf /var/lib/apt/lists/*

RUN add-apt-repository ppa:deadsnakes/ppa -y && \
    apt-get update && \
    apt-get install python3.11 -y && \
    rm -rf /var/lib/apt/lists/*

RUN curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

RUN ln -s /usr/bin/python3.11 /usr/bin/python && \
    ln -sf /usr/bin/python3.11 /usr/bin/python3

RUN pip install torch torchvision --index-url https://download.pytorch.org/whl/cu130 && \
    pip cache purge

RUN pip install tensorboard matplotlib gymnasium \
    opencv-python tqdm pillow pyyaml grpcio grpcio-tools requests beautifulsoup4 scikit-learn sentence-transformers && \
    pip cache purge

RUN pip list

EXPOSE 6006

ENTRYPOINT ["/etc/entrypoint_sshd.sh"]

# RLVERSION=8.1.0 CUDA_VERSION=13.1.2

# docker build . -t rl:${RLVERSION}-${CUDA_VERSION} -f rl.dockerfile --network=host --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg "http_proxy=http://bluefisher.work:10808/" --build-arg "https_proxy=http://bluefisher.work:10808/" --progress=plain
# docker tag rl:${RLVERSION}-${CUDA_VERSION} harbor.n705.work/n705/rl:${RLVERSION}-${CUDA_VERSION}
# docker push harbor.n705.work/n705/rl:${RLVERSION}-${CUDA_VERSION}

# docker save -o ./rl-${RLVERSION}-${CUDA_VERSION}.tar rl:${RLVERSION}-${CUDA_VERSION}

# scp rl-${RLVERSION}-${CUDA_VERSION}.tar cs@10.0.6.249:/home/cs/

# docker load -i ./rl-${RLVERSION}-${CUDA_VERSION}.tar

# docker run -it --gpus=all --rm --entrypoint=bash rl:${RLVERSION}-${CUDA_VERSION}
# docker run -it -v /root/test:/data -p 31631:22 -p 30711:8080 -p 32295:6006 --shm-size="64g" rl:${RLVERSION}-${CUDA_VERSION}
