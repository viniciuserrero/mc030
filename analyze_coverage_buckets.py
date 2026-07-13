"""
Coverage por "fatias" tematicas de um conjunto de arquivos lcov .info.

Diferente do analyze_coverage.py (que agrupa pelo modulo de topo), aqui cada
fatia e definida por um padrao no caminho do arquivo-fonte, permitindo comparar
sub-areas do PyTorch (ex.: codigo CUDA, autograd) lado a lado entre cenarios.

Uso:
    python analyze_coverage_buckets.py LABEL1 arq1.info LABEL2 arq2.info ...
"""
import sys
import re

# fatias: nome -> regex aplicada ao caminho do .cpp/.h (apos SF:)
BUCKETS = {
    "CUDA (host, /cuda/)":   re.compile(r"/cuda/"),
    "ATen native CPU":       re.compile(r"aten/src/ATen/native/cpu/"),
    "ATen native CUDA":      re.compile(r"aten/src/ATen/native/cuda/"),
    "Autograd":              re.compile(r"autograd"),
    "cuDNN (integração)":    re.compile(r"cudnn", re.IGNORECASE),
    "Distribuído (c10d)":    re.compile(r"c10d|/distributed/"),
}


def parse(info_file):
    """Retorna {bucket: [lines_hit, lines_found, fn_hit, fn_found]}."""
    res = {k: [0, 0, 0, 0] for k in BUCKETS}
    cf = None
    lh = lf = fnh = fnf = 0
    with open(info_file) as f:
        for line in f:
            if line.startswith("SF:"):
                cf = line[3:].strip()
                lh = lf = fnh = fnf = 0
            elif line.startswith("LH:"):
                lh = int(line[3:])
            elif line.startswith("LF:"):
                lf = int(line[3:])
            elif line.startswith("FNH:"):
                fnh = int(line[4:])
            elif line.startswith("FNF:"):
                fnf = int(line[4:])
            elif line.startswith("end_of_record") and cf:
                for name, rx in BUCKETS.items():
                    if rx.search(cf):
                        b = res[name]
                        b[0] += lh
                        b[1] += lf
                        b[2] += fnh
                        b[3] += fnf
                cf = None
    return res


def main():
    args = sys.argv[1:]
    if len(args) < 2 or len(args) % 2 != 0:
        print("Uso: python analyze_coverage_buckets.py LABEL1 arq1.info ...")
        sys.exit(1)

    labels = args[0::2]
    files = args[1::2]
    data = {lab: parse(fp) for lab, fp in zip(labels, files)}

    def pct(hit, found):
        return f"{100*hit/found:.1f}%" if found else "n/d"

    # tabela de LINHAS
    print("\n### Cobertura de LINHAS por fatia (%) ###")
    header = f"{'Fatia':<24} {'Total':>8} " + " ".join(f"{l:>10}" for l in labels)
    print(header)
    print("-" * len(header))
    for name in BUCKETS:
        total = data[labels[0]][name][1]
        cols = " ".join(f"{pct(data[l][name][0], data[l][name][1]):>10}" for l in labels)
        print(f"{name:<24} {total:>8} {cols}")

    # tabela de FUNCOES
    print("\n### Cobertura de FUNÇÕES por fatia (%) ###")
    print(header)
    print("-" * len(header))
    for name in BUCKETS:
        total = data[labels[0]][name][3]
        cols = " ".join(f"{pct(data[l][name][2], data[l][name][3]):>10}" for l in labels)
        print(f"{name:<24} {total:>8} {cols}")


if __name__ == "__main__":
    main()
