# Treino nanoGPT sobre pytorch, medindo tempo de treino/inferência.
# Unificado GPU/CPU. O build-arg DEVICE controla o device padrão de execução:
#   GPU (padrão): docker build -f nanogpt-perf.Dockerfile \
#                   --build-arg KERNEL_VERSION=$(uname -r) -t nanogpt-perf:cuda .
#   CPU:          docker build -f nanogpt-perf.Dockerfile \
#                   --build-arg BASE_IMAGE=pytorch-perf:cpu \
#                   --build-arg DEVICE=cpu \
#                   --build-arg KERNEL_VERSION=$(uname -r) -t nanogpt-perf:cpu .
ARG BASE_IMAGE=pytorch-perf:cuda
FROM ${BASE_IMAGE}

ARG KERNEL_VERSION=6.17.0-35-generic
ARG DEVICE=cuda

LABEL org.opencontainers.image.title="nanogpt-perf" \
      org.opencontainers.image.description="Treino nanoGPT sobre pytorch-perf para medir performance."

RUN pip3 install --no-cache-dir --break-system-packages \
        numpy \
        transformers \
        datasets \
        tiktoken \
        wandb \
        tqdm

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        linux-tools-${KERNEL_VERSION} \
        linux-tools-generic \
        build-essential \
        python3.12-dev && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends strace && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends git && \
    git clone https://github.com/karpathy/nanoGPT.git /workspace/nanoGPT && \
    apt-get purge -y --auto-remove git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/nanoGPT
COPY run-perf.sh run-perf.sh

VOLUME ["/workspace/data", "/workspace/out"]

# Device padrão de execução (cuda no build GPU, cpu no build CPU).
ENV DEVICE=${DEVICE}
CMD ["bash", "run-perf.sh"]
