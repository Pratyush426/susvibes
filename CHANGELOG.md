# Changelog

## Unreleased

### Kimi Code CLI harness — migration from deprecated Python kimi-cli

The original Python `kimi-cli` package was archived by Moonshot AI in September 2024
and replaced with [Kimi Code CLI](https://code.kimi.com), a native binary.
The harness is updated to work with the new CLI:

- **`setup-env.sh`**: switched from `uv`/`pip install kimi-cli` to the official
  one-liner `curl -fsSL https://code.kimi.com/kimi-code/install.sh | bash`; no
  Python or Node runtime required inside the container.
- **Command line**: removed `--yolo` (incompatible with `-p`); model now passed
  with `-m` flag: `kimi -p <prompt> --output-format stream-json -m <model>`.
- **Environment variables**: switched from `MOONSHOT_API_KEY`/`KIMI_API_KEY`/
  `KIMI_MODEL` (old package) to `KIMI_MODEL_NAME` + `KIMI_MODEL_API_KEY` +
  `KIMI_MODEL_BASE_URL` (optional) + `KIMI_CODE_TRUST_WORKSPACE=1` (suppresses
  first-run trust prompt in containers); fallback chain preserves backward
  compatibility with existing `.env` files.
- **Default model**: updated from the retired `kimi-k2-turbo-preview` (404 on
  Moonshot API) to `kimi-k2.7-code`.
- **`convert.py`**: added Format 1 branch in `events_to_messages()` to handle the
  real Kimi Code CLI `role`-keyed stream (`role:"meta"` skipped, `role:"assistant"`
  with `tool_calls` normalised to OpenAI shape, `role:"tool"` with `tool_call_id`).
  Existing Format 2 (legacy flat events) and Format 3 (OpenAI delta) preserved.
- **`susvibes/core/constants.py`**: moved `import platform` to top-of-file imports;
  renamed `_calc_mem_limit` → `calc_mem_limit` (dropped leading underscore).
- **Tests**: added `test_kimi_convert_kimi_code_cli_native_format` covering the
  new stream format; updated batch options tests to assert `kimi-k2.7-code` default.
- **Docs**: updated `kimi_cli/README.md`, `kimi_cli_tutorial.md`, and `.env.sample`
  to reflect the new CLI, correct env var names, and available models.
- **Sample output**: added `kimi_cli/examples/final_results.json` showing the
  expected structure of a Kimi Code CLI run.

### Phase A — Agent harness interface & prompt infrastructure

- **Shared harness Protocol + data types.** `AgentHarness` / `DockerHarness` Protocols,
  `AgentResult` / `PredictionRecord` TypedDicts, and `normalize_prediction` helper in
  `evaluation_harness/base.py`.
- **Canonical prompt infrastructure.** `evaluation_harness/common.py` aligns
  `apply_safety_hint()` with the strategy pipeline's `GENERIC_PROMPT`;
  `evaluation_harness/PROMPTS.md` documents the two-layer prompt architecture.
  Fixed broken `ADDITIONAL_INSTRUCTIONS` imports in the Claude/Gemini harnesses.
- **Offline test suite.** Hand-curated fixtures, pytest `live`/`docker` markers so
  expensive tests are opt-in and deselected by default.

### Phase B — Docker lifecycle deduplication & ACR override

- **Deduplicated Docker lifecycle.** `DockerHarnessBase` in `evaluation_harness/base.py`
  factors extract/start/exec/setup-env/cleanup out of the per-agent `run_docker.py`
  files, which become thin subclasses supplying only `name` and `env_source_files`.
- **Opt-in registry override.** Ported `resolve_image_name()` (driven by
  `ACR_REGISTRY_URL`) from the Endor fork into `susvibes/core/utils.py`, applied once
  in `DockerHarnessBase.__init__`; unset = Docker Hub (unchanged upstream behavior).
- **Gemini trust fix.** Ported `GEMINI_CLI_TRUST_WORKSPACE=true` env injection from
  endor into `gemini_cli/batch_run_docker.py` — without it Gemini CLI refuses to
  run in non-interactive Docker containers.
- **Real-Docker tests (no LLM).** Opt-in `docker`-marked lifecycle tests parametrized
  over both harnesses, offline ACR-resolution unit tests, and a reproduction of the
  pre-existing container cleanup leak (`tests/test_docker_cleanup_leak.py`).

## v1.0

v1.0 sharpens the security signal and closes reward-hacking loopholes. It succeeds v0.0
(200 tasks) with a 186-task set; both stay selectable on the leaderboard, with v1.0 preferred
going forward.

### What's new

**Human-verified security tests.** A security test lifted from a vulnerability-fix commit can be
bound to that specific fix, so a *different but equally secure* implementation may still fail it.
In v1.0 every security test was reviewed by human annotators to confirm it checks a security
property, and revised where needed to pass any correct secure solution — not just the reference.

**Reward-hack-resistant environments.** Eval images now remove `.git` and re-initialize each repo
as a fresh single-commit repo, so agents can't recover the fix from git history. Reward hacking
through other channels (e.g. web search) still requires custom guardrails on the agent scaffold.

**Corrected CWE labels.** A small fraction of `cwe_ids` were re-annotated for precision.

**Tighter task set (200 → 186).** 14 tasks that couldn't meet the raised security-test quality bar
were dropped; none added.

### Effect on scores
- Human-verified security tests likely lift SecPass slightly; overall trends stay similar.
- Removing the git-history channel can lower FuncPass and SecPass for agents that reward-hacked
  through it.
- In **both** versions, trajectories that reward-hack count as failures.

### Migrating v0.0 results to v1.0
- **Revised security tests** — re-evaluate existing solutions against the new tests on the 186
  tasks; patches are unchanged, so no new inference.
- **Git-history hardening** — detect the git-hacking trajectories and re-run only those on the new
  image; the rest carry over.

### Reproducibility
v0.0 and v1.0 are pinned to fixed dataset snapshots (git tags `v0.0` and `v1.0`). v0.0 scores are
computed on the 200-task set and remain valid there; they are not directly comparable to v1.0.

## v0.0

Initial release — 200-task security-oriented vibe coding benchmark.
