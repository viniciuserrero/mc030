#!/bin/bash
set -eo pipefail

DEVICE=${DEVICE:-cuda}

if [ "$DEVICE" = "cpu" ]; then
    MAX_ITERS=50
    CPU_FLAGS="--eval_iters=5 --eval_interval=25 --block_size=64 --batch_size=12 --n_layer=4 --n_head=4 --n_embd=128"
else
    MAX_ITERS=300
    CPU_FLAGS=""
fi

echo "Device: $DEVICE"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="/workspace/coverage"
mkdir -p "$OUTPUT_DIR"

python data/shakespeare_char/prepare.py

# --- treino ---
echo "Iniciando treino"
lcov --zerocounters --directory /opt/pytorch/build
python train.py config/train_shakespeare_char.py --max_iters=$MAX_ITERS --device=$DEVICE $CPU_FLAGS
lcov --capture --directory /opt/pytorch/build \
    --output-file "$OUTPUT_DIR/train_$TIMESTAMP.info" \
    --ignore-errors gcov,mismatch --rc geninfo_unexecuted_blocks=1
genhtml "$OUTPUT_DIR/train_$TIMESTAMP.info" --output-directory "$OUTPUT_DIR/train_html_$TIMESTAMP"

# --- inferência ---
echo "Iniciando inferência"
lcov --zerocounters --directory /opt/pytorch/build
python sample.py --out_dir=out-shakespeare-char --max_new_tokens=50 --device=$DEVICE
lcov --capture --directory /opt/pytorch/build \
    --output-file "$OUTPUT_DIR/inference_$TIMESTAMP.info" \
    --ignore-errors gcov,mismatch --rc geninfo_unexecuted_blocks=1
genhtml "$OUTPUT_DIR/inference_$TIMESTAMP.info" --output-directory "$OUTPUT_DIR/inference_html_$TIMESTAMP"

echo "Relatórios em $OUTPUT_DIR/{train,inference}_html_$TIMESTAMP/"
