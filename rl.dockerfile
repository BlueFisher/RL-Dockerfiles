ARG CUDA_VERSION=12.2.0

FROM nvidia-egl-base:2.0-${CUDA_VERSION}

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

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-py311_24.1.2-0-Linux-x86_64.sh -O ~/miniconda.sh && \
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
    conda install -y pytorch torchvision pytorch-cuda=12.1 -c pytorch -c nvidia && \
    conda clean -apy

RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate base && \
    conda install -y gymnasium \
    tensorboard opencv matplotlib pillow pyyaml numpy grpcio=1.62 requests beautifulsoup4 scikit-learn -c conda-forge && \
    conda clean -apy

RUN conda list

EXPOSE 6006

ENTRYPOINT ["/etc/entrypoint_sshd.sh"]

# RLVERSION=7.6.0
# CUDA_VERSION=12.2.0

# docker build . -t rl:${RLVERSION}-${CUDA_VERSION} -f rl.dockerfile --network=host --build-arg CUDA_VERSION=${CUDA_VERSION} --build-arg "http_proxy=http://192.168.3.2:10809/" --build-arg "https_proxy=http://192.168.3.2:10809/" --progress=plain --no-cache
# docker tag rl:${RLVERSION}-${CUDA_VERSION} harbor.n705.work/n705/rl:${RLVERSION}-${CUDA_VERSION}
# docker push harbor.n705.work/n705/rl:${RLVERSION}-${CUDA_VERSION}

# docker save -o ./rl-${RLVERSION}-${CUDA_VERSION}.tar rl:${RLVERSION}-${CUDA_VERSION}

# scp rl-${RLVERSION}-${CUDA_VERSION}.tar cs@10.0.6.249:/home/cs/

# docker load -i ./rl-${RLVERSION}-${CUDA_VERSION}.tar

# docker run -it --rm --entrypoint=bash rl:${RLVERSION}-${CUDA_VERSION}
# docker run -it -v /root/test:/data -p 31631:22 -p 30711:8080 -p 32295:6006 --shm-size="64g" rl:${RLVERSION}-${CUDA_VERSION}
