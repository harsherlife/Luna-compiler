#!/usr/bin/env python3

import argparse
import re
import subprocess
import statistics


# usage python3 tools/profiler.py tokens/ast -n {iters}

def run_benchmark(name, iterations = 15):
    pattern = re.compile(
        rf"^{re.escape(name)}\s*=\s*([0-9]+(?:\.[0-9]+)?)\s*microseconds",
        re.MULTILINE
    )

    times = []

    for i in range(iterations):
        print(f"Run {i + 1}/{iterations}...", end=" ", flush=True)

        result = subprocess.run(
            ["make", "profile"],
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            print("FAILED")
            print(result.stderr)
            raise RuntimeError("make profile failed")

        match = pattern.search(result.stdout)

        if not match:
            print("NO MATCH")
            print(result.stdout)
            raise RuntimeError(
                f"Could not find timing for '{name}'"
            )

        time_us = float(match.group(1))
        times.append(time_us)

        print(f"{time_us:.3f} us")

    average = statistics.mean(times)

    print("\nResults")
    print("-------")
    print(f"Iterations : {iterations}")
    print(f"Average    : {average:.3f} microseconds")
    print(f"Min        : {min(times):.3f} microseconds")
    print(f"Max        : {max(times):.3f} microseconds")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="Profile name, e.g. sort")
    parser.add_argument(
        "-n",
        "--iterations",
        type=int,
        default = 15,
        help="Number of iterations (default: 15)",
    )

    args = parser.parse_args()

    run_benchmark(args.name, args.iterations)


if __name__ == "__main__":
    main()