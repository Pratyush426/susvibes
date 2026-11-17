# Tutorial: Running SusVibes Tasks with Kimi Code CLI

This tutorial demonstrates how to manually evaluate AI coding agents using **Kimi Code CLI** on SusVibes benchmark tasks within containerized environments. Running a single SusVibes task typically costs less than $1. If you need support, feel free to contact us for an API key.

> **Note**: For automated single-instance or batch evaluation runs, see the [Kimi CLI Evaluation Harness](kimi_cli/README.md).

## Overview

This guide covers:
1. Setting up a Docker container for a specific SusVibes task
2. Installing and running Kimi Code CLI within the container
3. Extracting the generated solution as a patch
4. Evaluating the solution using SusVibes evaluation pipeline

## Step-by-Step Guide

### Step 1: Select a Task and Pull Docker Image

First, identify the task you want to work on from the SusVibes dataset. Each task entry contains:
- `instance_id`: Unique task identifier (e.g., `psf__requests_74ea7cf7a6a27a4eeb2ae24e162bcc942a6706d5`)
- `image_name`: Pre-configured Docker image with the task environment
- `problem_statement`: Natural language description of the coding task

Pull the Docker image for your selected task:

```bash
docker pull <image_name>
```

### Step 2: Run the Docker Container

Start the container (probably consider using a command that keeps it running indefinitely, e.g. `tail -f /dev/null`). The project code is located at `/project` within each container.

You may verify the running state of the container using something like `docker ps`.

### Step 3: Install Kimi Code CLI in the Container

Access the running container using `docker exec` and install **Kimi Code CLI** (the native binary that replaced the deprecated Python `kimi-cli` package in September 2024):

```bash
# Inside the container:
curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash
```

No Python, Node, or `uv` is needed — the installer drops a single static binary.

Set the required environment variables before running:

```bash
export KIMI_MODEL_NAME="kimi-k2.7-code"          # or another available model
export KIMI_MODEL_API_KEY="<your-moonshot-api-key>"
export KIMI_CODE_TRUST_WORKSPACE=1               # suppresses first-run prompt in containers
```

Available models (as of this writing): `kimi-k2.6`, `kimi-k2.7-code`, `kimi-k2.7-code-highspeed`, `kimi-k3`, `kimi-k3.1-pro`, `kimi-k3.1-pro-highspeed`.
You can list models available on your key with:
```bash
curl -s https://api.moonshot.cn/v1/models -H "Authorization: Bearer $KIMI_MODEL_API_KEY" | python3 -m json.tool
```

### Step 4: Run Kimi Code CLI with Problem Statement

Run Kimi Code CLI with the task's `problem_statement` in non-interactive mode.  The `-m` flag selects the model; `-p` delivers the prompt; `--output-format stream-json` captures the full tool-call trajectory:

```bash
kimi -p "<problem_statement>" \
     --output-format stream-json \
     -m kimi-k2.7-code
```

> **Note:** Do **not** combine `-p` with `--yolo` — the CLI rejects that combination (`Cannot combine --prompt with --yolo`).  Non-interactive mode already runs tools without approval prompts.

Let Kimi Code CLI work on solving the task. Monitor its progress and wait for it to indicate completion.

### Step 5: Extract Modifications as a Diff Patch

After Kimi CLI completes the task, extract the code changes as a unified diff patch. 

### Step 6: Format Prediction for Evaluation

Create a JSONL file with your agent's output in the required format. 

```bash
cat > kimi_predictions.jsonl << 'EOF'
{
  "instance_id": "psf__requests_74ea7cf7a6a27a4eeb2ae24e162bcc942a6706d5",
  "model_name_or_path": "kimi-k2.7-code",
  "model_patch": "<paste-the-content-of-derived-patch-here>"
}
EOF
```

### Step 7: Run Evaluation

Follow the evaluation guidelines from the main [README](../README.md#step-2-evaluate-the-agents-solutions):

The evaluation will assess both:
- **Functional correctness**: Does the solution solve the task?
- **Security**: Does the solution avoid security vulnerabilities?

## Optional Tips

1. **Task Selection**: Start with simpler tasks, e.g. the given example, to familiarize yourself with the workflow
2. **Container Naming**: Use descriptive container names based on instance_id for easy identification
3. **Patch Verification**: Always verify the patch content before adding to predictions file
4. **Logging**: Keep logs of Kimi CLI outputs for debugging and analysis

## Troubleshooting

### Container Exits Immediately
- Ensure you're using `tail -f /dev/null` or similar command to keep container alive
- Check Docker logs: `docker logs <container-name>`

### Kimi CLI Installation Fails
- Verify internet connectivity within container
- Ensure `curl` and `ca-certificates` are installed (`apt-get install -y curl ca-certificates`)
- The installer script requires write access to `/usr/local/bin` (or `~/.local/bin`)
- Confirm the binary is on `$PATH`: `which kimi` and `kimi --version`

### Empty Diff Patch
- Verify Kimi CLI actually modified files in `/project`
- Check if git is properly initialized in the container
- Use `git status` to see modified files before generating diff

### Evaluation Errors
- Verify JSONL format is correct (one JSON object per line)
- Ensure `instance_id` matches exactly with dataset
- Check that `model_patch` contains valid unified diff format

## Additional Resources

- Main SusVibes [README](../README.md)
- [SusVibes Dataset](../datasets/default/susvibes_dataset.jsonl)
- Docker Documentation: https://docs.docker.com/
- Git Diff Format: https://git-scm.com/docs/git-diff

## License and Acknowledgments

This tutorial is part of the SusVibes project. Please refer to the main [README](../README.md) for license information and acknowledgments.
