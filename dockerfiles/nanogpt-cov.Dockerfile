# Treino nanoGPT sobre pytorch-cov, com análise de coverage no run.sh.
ARG BASE_IMAGE=pytorch-cov:cuda
FROM ${BASE_IMAGE}

LABEL org.opencontainers.image.title="nanogpt-cov" \
      org.opencontainers.image.description="Treino nanoGPT sobre pytorch-cov. Monta /workspace/data, /workspace/out e /workspace/coverage."


# Deps de treino do nanoGPT
RUN pip3 install --no-cache-dir --break-system-packages \
        numpy \
        transformers \
        datasets \
        tiktoken \
        wandb \
        tqdm \
        triton

WORKDIR /workspace

RUN apt-get update && \
    apt-get install -y --no-install-recommends git libjson-xs-perl && \
    git clone https://github.com/karpathy/nanoGPT.git /workspace/nanoGPT && \
    apt-get purge -y --auto-remove git && \
    rm -rf /var/lib/apt/lists/*

    
WORKDIR /workspace/nanoGPT
    
COPY run-cov.sh run.sh

# data  → datasets de entrada
# out   → checkpoints e artefatos do treino
# coverage → relatórios lcov/gcovr gerados em runtime
VOLUME ["/workspace/data", "/workspace/out", "/workspace/coverage"]

CMD ["bash", "run.sh"]
