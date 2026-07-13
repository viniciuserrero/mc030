#!/bin/bash
set -eo pipefail

DEVICE=${DEVICE:-cuda}
OUTPUT_DIR=${OUTPUT_DIR:-/workspace/out}

if [ "$DEVICE" = "cpu" ]; then
    MAX_ITERS=50
    EXTRA_FLAGS="--eval_iters=5 --eval_interval=25 --block_size=64 --batch_size=12 --n_layer=4 --n_head=4 --n_embd=128"
else
    MAX_ITERS=300
    EXTRA_FLAGS=""
fi

if [ -z "$RUN_NAME" ]; then
    N=$(ls "$OUTPUT_DIR" 2>/dev/null | grep -c "^run-" || true)
    RUN_NAME=$(printf "run-%02d" $((N + 1)))
fi
RUN_DIR="$OUTPUT_DIR/$RUN_NAME"
mkdir -p "$RUN_DIR/train" "$RUN_DIR/inference"

python data/shakespeare_char/prepare.py

# --- treino ---

# Run 1: strace isolado — lista de libs sem dependências do perf contaminando
strace -f -e openat -o "$RUN_DIR/train/strace.txt" \
    python train.py config/train_shakespeare_char.py \
        --max_iters=$MAX_ITERS --device=$DEVICE $EXTRA_FLAGS

# Só conta libs efetivamente carregadas: o loader sonda vários caminhos e os
# openat que retornam "= -1 ENOENT" são tentativas que falharam. Mantém apenas
# as linhas cujo openat retornou um descritor válido (= <fd>).
grep -E '= [0-9]+$' "$RUN_DIR/train/strace.txt" \
    | grep -oE '"(/[^"]+\.so(\.[0-9]+)*)"' \
    | tr -d '"' | xargs -I{} basename {} | sort -u \
    > "$RUN_DIR/train/libs.txt"

# Run 2: perf isolado — amostras de CPU sem overhead do strace
perf record -o "$RUN_DIR/train/perf.data" -- \
    python train.py config/train_shakespeare_char.py \
        --max_iters=$MAX_ITERS --device=$DEVICE $EXTRA_FLAGS

perf report -i "$RUN_DIR/train/perf.data" --sort dso --stdio \
    > "$RUN_DIR/train/dso.txt"

# --- inferência ---

strace -f -e openat -o "$RUN_DIR/inference/strace.txt" \
    python sample.py --out_dir=out-shakespeare-char \
        --max_new_tokens=50 --device=$DEVICE

# Mesma filtragem do treino: descarta os openat que falharam (= -1 ENOENT).
grep -E '= [0-9]+$' "$RUN_DIR/inference/strace.txt" \
    | grep -oE '"(/[^"]+\.so(\.[0-9]+)*)"' \
    | tr -d '"' | xargs -I{} basename {} | sort -u \
    > "$RUN_DIR/inference/libs.txt"

perf record -o "$RUN_DIR/inference/perf.data" -- \
    python sample.py --out_dir=out-shakespeare-char \
        --max_new_tokens=50 --device=$DEVICE

perf report -i "$RUN_DIR/inference/perf.data" --sort dso --stdio \
    > "$RUN_DIR/inference/dso.txt"

echo "Saídas em $RUN_DIR/"
echo "  train/libs.txt      — .so abertos via openat (strace)"
echo "  train/dso.txt       — uso de CPU por lib (perf)"
echo "  inference/libs.txt"
echo "  inference/dso.txt"
