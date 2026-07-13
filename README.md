# mc030 — HPC

Medições sobre nanoGPT + PyTorch em 4 cenários (treino/inferência × GPU/CPU):
libs carregadas (`strace`), tempo de CPU (`perf`) e cobertura do PyTorch (`lcov`).

Resultados em `results/`. Dados brutos (`.info`, `perf.data`, HTML) não versionados.

## Reproduzir

```bash
# libs + perf
DEVICE=cuda ./run-perf.sh
DEVICE=cpu  ./run-perf.sh

# cobertura (gera .info)
DEVICE=cuda ./run-cov.sh
DEVICE=cpu  ./run-cov.sh

# resumir cobertura a partir do .info
python analyze_coverage.py train.info /opt/pytorch
python analyze_coverage_buckets.py GPU-Treino gt.info GPU-Inf gi.info CPU-Treino ct.info CPU-Inf ci.info
```

Containers em `dockerfiles/`: perfilamento (PyTorch padrão) e cobertura
(PyTorch com `--coverage`, builds `USE_CUDA=1` e `USE_CUDA=0`).

## Resultados

| Cenário         | Libs | Cobertura            |
|-----------------|------|----------------------|
| GPU, treino     | 94   | 88.815 / 1.331.061 (6,7%) |
| GPU, inferência | 64   | 73.362 / 1.331.061 (5,5%) |
| CPU, treino     | 111  | 82.187 / 1.264.666 (6,5%) |
| CPU, inferência | 40   | 70.480 / 1.264.666 (5,6%) |

- `results/perf/` — `dso.txt` (perf) e `libs.txt` (strace) por cenário.
- `results/coverage/` — `coverage_fatias.txt` e `modules_*.txt`.
