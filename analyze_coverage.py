import sys
import os
from collections import defaultdict


def parse_lcov(info_file):
    """
    Parses an lcov.info file and returns a dictionary mapping
    source file paths to (lines_hit, lines_found).
    """
    if not os.path.exists(info_file):
        print(f"Error: {info_file} not found.")
        return None

    coverage_data = {}
    current_file = None
    lh = lf = 0

    with open(info_file, 'r') as f:
        for line in f:
            line = line.strip()
            if line.startswith('SF:'):
                current_file = line[3:]
                lh = lf = 0
            elif line.startswith('LH:'):
                lh = int(line[3:])
            elif line.startswith('LF:'):
                lf = int(line[3:])
            elif line == 'end_of_record' and current_file:
                coverage_data[current_file] = (lh, lf)
                current_file = None

    return coverage_data


def module_name(file_path, base_path):
    relative = file_path[len(base_path):]
    parts = relative.split(os.sep)
    name = parts[0]
    if name == "third_party" and len(parts) > 1:
        name = f"third_party/{parts[1]}"
    return name


def summarize_by_module(coverage_data, base_path):
    module_lh = defaultdict(int)  # lines hit
    module_lf = defaultdict(int)  # lines found

    for file_path, (lh, lf) in coverage_data.items():
        if file_path.startswith(base_path):
            name = module_name(file_path, base_path)
            module_lh[name] += lh
            module_lf[name] += lf

    return module_lh, module_lf


def main():
    if len(sys.argv) < 3:
        print("Usage: python analyze_coverage.py <lcov.info> <base_path>")
        sys.exit(1)

    lcov_file = sys.argv[1]
    base_path = sys.argv[2].rstrip("/") + "/"

    data = parse_lcov(lcov_file)
    if not data:
        return

    lh_map, lf_map = summarize_by_module(data, base_path)

    # Sort by coverage % descending
    modules = [m for m in lf_map if lf_map[m] > 0]
    modules.sort(key=lambda m: lh_map[m] / lf_map[m], reverse=True)

    print(f"{'Module':<32} | {'Coverage %':<11} | {'Lines Hit':<11} | {'Lines Total'}")
    print("-" * 72)

    for m in modules:
        pct = lh_map[m] / lf_map[m] * 100
        print(f"{m:<32} | {pct:<10.1f}% | {lh_map[m]:<11} | {lf_map[m]}")

    # Total geral sobre todos os arquivos do .info (inclui headers de sistema
    # fora de base_path). Corresponde ao total do lcov e a cobertura global
    # relatada por cenario.
    total_lh = sum(lh for lh, lf in data.values())
    total_lf = sum(lf for lh, lf in data.values())
    if total_lf > 0:
        pct = total_lh / total_lf * 100
        print("-" * 72)
        print(f"{'TOTAL (todos os arquivos)':<32} | {pct:<10.1f}% | {total_lh:<11} | {total_lf}")


if __name__ == "__main__":
    main()