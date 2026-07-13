# PyTorch from-source instrumentado com gcov para análise de cobertura.
# Parametrizado para gerar tanto a variante GPU (com CUDA) quanto a CPU-only a
# partir do mesmo arquivo:
#   GPU (padrão): docker build -f pytorch-cov.Dockerfile -t pytorch-cov:cuda .
#   CPU:          docker build -f pytorch-cov.Dockerfile \
#                   --build-arg SOURCE_IMAGE=ubuntu:24.04 --build-arg USE_CUDA=0 \
#                   -t pytorch-cov:cpu .
ARG SOURCE_IMAGE=nvidia/cuda:12.6.3-devel-ubuntu24.04
FROM ${SOURCE_IMAGE}

ARG PYTORCH_VERSION=2.11.0
ARG PYTHON_VERSION=3.12
ARG USE_CUDA=1
# https://developer.nvidia.com/cuda/gpus
ARG TORCH_CUDA_ARCH_LIST="8.6"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    CUDA_HOME=/usr/local/cuda \
    PATH=/usr/local/cuda/bin:$PATH \
    LD_LIBRARY_PATH=/usr/local/cuda/lib64:${LD_LIBRARY_PATH:-}

RUN set -eu && \
    apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python${PYTHON_VERSION}-dev \
    python3-pip \
    build-essential \
    git \
    cmake \
    ninja-build \
    ccache \
    libopenblas-dev \
    libssl-dev \
    lcov \
    gcovr \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python  python  /usr/bin/python${PYTHON_VERSION} 1

WORKDIR /opt/pytorch
RUN set -eu && \
        git clone https://github.com/pytorch/pytorch.git . && \
        git checkout v${PYTORCH_VERSION} && \
        git submodule update --init --recursive

RUN python3 -m pip install --no-cache-dir --break-system-packages --ignore-installed setuptools wheel
RUN python3 -m pip install --no-cache-dir --break-system-packages \
    pyyaml \
    typing_extensions \
    numpy \
    cmake \
    ninja \
    six

ENV CMAKE_BUILD_TYPE=Debug \
    CMAKE_C_FLAGS="--coverage -O0 -fopenmp" \
    CMAKE_CXX_FLAGS="--coverage -O0 -fopenmp" \
    CMAKE_SHARED_LINKER_FLAGS="--coverage -fopenmp" \
    CMAKE_EXE_LINKER_FLAGS="--coverage -fopenmp" \
    TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST}" \
    BUILD_TEST=0 \
    USE_CUDA=${USE_CUDA} \
    MAX_JOBS=8


# pipefail sozinho não funciona com tee — usa PIPESTATUS para preservar o exit code do python
RUN bash -c 'set -euo pipefail && \
    export PIP_BREAK_SYSTEM_PACKAGES=1 && \
    python setup.py develop 2>&1 | tee /opt/build.log ; \
    exit ${PIPESTATUS[0]}'


# Volume para relatórios lcov gerados em runtime
VOLUME ["/workspace/coverage"]

CMD ["bash"]