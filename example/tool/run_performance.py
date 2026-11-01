#!/usr/bin/env python3
"""Run the 20-pair performance matrix on one connected physical iPhone."""
import argparse
import json
from pathlib import Path
import subprocess
import sys


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('device', help='Physical iPhone ID from flutter devices')
    parser.add_argument('output', type=Path, help='New directory for logs and JSONL')
    args = parser.parse_args()
    example = Path(__file__).resolve().parents[1]
    devices = json.loads(subprocess.check_output(
        ['flutter', 'devices', '--machine'], cwd=example, text=True,
    ))
    device = next((device for device in devices if device['id'] == args.device), None)
    if not device or device.get('emulator') or device.get('targetPlatform') != 'ios':
        parser.error('Select a connected physical iPhone, not a simulator.')
    args.output.mkdir(parents=True, exist_ok=False)
    metadata = {
        'device': device,
        'flutter': subprocess.check_output(['flutter', '--version'], cwd=example, text=True),
        'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=example, text=True).strip(),
        'status': subprocess.check_output(['git', 'status', '--short'], cwd=example, text=True),
        'note': 'Cold app process each invocation; SF Symbols/iOS system caches may remain warm.',
    }
    (args.output / 'environment.json').write_text(json.dumps(metadata, indent=2) + '\n')
    matrix = [
        ('switches', 5, ['baseline', 'optimized']),
        ('switches', 20, ['baseline', 'optimized']),
        ('surfaces', 1, ['baseline', 'optimized']),
        ('surfaces', 10, ['baseline', 'optimized']),
        ('symbols', 12, ['baseline', 'png', 'precache']),
    ]
    with (args.output / 'results.jsonl').open('w') as results:
        for run in range(1, 21):
            for scenario, count, variants in matrix:
                # Alternate pairs; rotate all three symbol orders across runs.
                shift = (run - 1) % len(variants)
                order = variants[shift:] + variants[:shift]
                for variant in order:
                    name = f'{run:02}-{scenario}-{count}-{variant}'
                    command = [
                        'flutter', 'drive', '--profile', '--no-pub',
                        '--driver=test_driver/integration_test.dart',
                        '--target=integration_test/performance_test.dart', '-d', args.device,
                        f'--dart-define=MJN_SCENARIO={scenario}',
                        f'--dart-define=MJN_VARIANT={variant}',
                        f'--dart-define=MJN_COUNT={count}',
                        f'--dart-define=MJN_RUN={run}',
                    ]
                    print(name, flush=True)
                    completed = subprocess.run(command, cwd=example, text=True,
                                               stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
                    (args.output / f'{name}.log').write_text(completed.stdout)
                    if completed.returncode:
                        sys.exit(f'{name} failed; inspect its log before continuing.')
                    lines = [line.split('MJN_PERFORMANCE ', 1)[1] for line in completed.stdout.splitlines()
                             if 'MJN_PERFORMANCE ' in line]
                    if len(lines) != 1:
                        sys.exit(f'{name}: expected one JSON result, got {len(lines)}.')
                    report = json.loads(lines[0])
                    results.write(json.dumps(report) + '\n')
                    results.flush()


if __name__ == '__main__':
    main()
