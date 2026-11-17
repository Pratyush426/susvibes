# Kimi Code CLI Evaluation Harness

This directory contains tools for running **Kimi Code CLI** evaluations on SusVibes benchmark tasks using Docker containers.

> **Note:** The original Python `kimi-cli` package was archived by Moonshot AI in September 2024. This harness now uses the [Kimi Code CLI](https://code.kimi.com) native binary — a single static binary with no Python or Node dependency.

## Overview

The evaluation harness executes Kimi Code CLI on benchmark code repositories packaged as Docker images, providing an isolated, reproducible testing environment.

## Files

- **`prompts.py`** - Prompt templates and example task definitions for Kimi Code CLI interactions
- **`run_docker.py`** - Core Docker integration class (`DockerIntegration`) for managing containerized Kimi Code CLI execution
- **`batch_run_docker.py`** - Processes multiple evaluation instances sequentially from a JSONL dataset
- **`parallel_batch_run.py`** - Runs batch evaluations in parallel across multiple processes
- **`setup-env.sh`** - Container setup script installing Kimi Code CLI via the official installer
- **`convert.py`** - Converts harness `final_results.json` into standard OpenAI message trajectory format
- **`.env.sample`** - Sample environment variables for Kimi Code CLI / Moonshot API
- **`examples/final_results.json`** - Example output from a real Kimi Code CLI run (non-empty `model_patch`)

## Usage

### Environment Setup

Copy `.env.sample` to `.env` and fill in your credentials, **or** export them in your shell:

```bash
export KIMI_MODEL_NAME="kimi-k2.7-code"
export KIMI_MODEL_API_KEY="your-moonshot-api-key"
export KIMI_CODE_TRUST_WORKSPACE=1
```

Available models on the Moonshot API: `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k2.7-code-highspeed`, `kimi-k3`, `kimi-k3.1-pro`, `kimi-k3.1-pro-highspeed`.

### Single Instance

Run a single evaluation using `run_docker.py`:

```bash
python run_docker.py
```

### Batch Processing

Process multiple instances sequentially from a JSONL file:

```bash
python batch_run_docker.py \
  --jsonl_file ../../datasets/default/susvibes_dataset.jsonl \
  --num_instances 10 \
  --model kimi-k2.7-code
```

### Parallel Batch Processing

Run batch evaluations across N parallel processes:

```bash
python parallel_batch_run.py \
  --jsonl_file ../../datasets/default/susvibes_dataset.jsonl \
  --num_processes 4 \
  --model kimi-k2.7-code
```

### Trajectory Conversion

A batch run writes `final_results.json` under `results/<model>/<timestamp>/`. Convert it into the standard trajectory format with:

```bash
python convert.py --input_dir results/kimi-k2.7-code/<timestamp>/
```

See [`../TRAJECTORY_FORMAT.md`](../TRAJECTORY_FORMAT.md) for the record specification. The converter writes the split layout: an index `<stem>.trials.json` referencing individual instance messages in `messages/<instance_id>.json`.

## Kimi Code CLI Command Reference

The harness invokes Kimi Code CLI as:

```bash
kimi -p "<prompt>" --output-format stream-json -m <model>
```

Key flags:
- `-p <prompt>` — deliver the task prompt (non-interactive mode, tools run without approval)
- `--output-format stream-json` — emit one JSON object per line (role-keyed)
- `-m <model>` — select the model (required; not read from environment)

> **Do not** combine `-p` with `--yolo` — the CLI rejects that combination with `Cannot combine --prompt with --yolo`.
