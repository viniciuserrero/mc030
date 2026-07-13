# Mesmo PyTorch da pytorch-cov, mas o wheel oficial otimizado (sem coverage/-O0).
# Parametrizado para gerar a variante GPU (com CUDA) ou CPU-only:
#   GPU (padrão): docker build -f pytorch.Dockerfile -t pytorch-perf:cuda .
#   CPU:          docker build -f pytorch.Dockerfile \
#                   --build-arg SOURCE_IMAGE=ubuntu:24.04 \
#                   --build-arg TORCH_INDEX_URL=https://download.pytorch.org/whl/cpu \
#                   -t pytorch-perf:cpu .
ARG SOURCE_IMAGE=nvidia/cuda:12.6.3-runtime-ubuntu24.04
FROM ${SOURCE_IMAGE}

ARG PYTHON_VERSION=3.12
ARG PYTORCH_VERSION=2.11.0
ARG TORCH_INDEX_URL="https://download.pytorch.org/whl/cu126"

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN set -eu && \
    apt-get update && apt-get install -y --no-install-recommends \
    python${PYTHON_VERSION} \
    python3-pip && \
    rm -rf /var/lib/apt/lists/* && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python${PYTHON_VERSION} 1 && \
    update-alternatives --install /usr/bin/python  python  /usr/bin/python${PYTHON_VERSION} 1

RUN python3 -m pip install --no-cache-dir --break-system-packages \
    torch==${PYTORCH_VERSION} --index-url ${TORCH_INDEX_URL}

CMD ["bash"]
