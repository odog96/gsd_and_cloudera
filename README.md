# Private Agentic Coding on Cloudera AI

Tools like Claude Code and Cursor have changed how developers write software — an AI agent that lives in your codebase, understands context, and builds alongside you. But for regulated industries — healthcare, financial services, government — sending code, prompts, and data to an external provider is a non-starter.

This project demonstrates that the agentic coding experience can run **entirely on infrastructure you control**. No code leaves the environment. No prompts hit an external API. The model is hosted privately, and inference stays behind your firewall.

## The Stack

```
┌─────────────────────────────────────────────────┐
│  Cloudera AI Workbench Session                  │
│                                                 │
│  ┌──────────┐    ┌──────────────┐               │
│  │  GSD-2   │───>│  Pi SDK      │               │
│  │  (gsd-pi)│    │  (agent      │               │
│  │          │    │   runtime)   │               │
│  └──────────┘    └──────┬───────┘               │
│                         │ OpenAI-compatible API  │
│                         ▼                        │
│  ┌──────────────────────────────────────────┐   │
│  │  Cloudera AI Inference Service            │   │
│  │  Nemotron 49B (private, on-cluster GPU)   │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

* **[GSD-2](https://github.com/gsd-build/gsd-2)** — An open-source agentic coding CLI built on the Pi SDK. Supports spec-driven workflows with research, plan, execute, and verify phases.
* **[Pi SDK](https://github.com/badlogic/pi-mono)** — The agent runtime underneath GSD-2. Connects to any OpenAI-compatible provider via a simple JSON config.
* **Cloudera AI Inference Service** — Hosts the model privately and exposes an OpenAI-compatible `/v1/chat/completions` endpoint. Supports NVIDIA NIM and Hugging Face model runtimes. Deployable on-prem, in VPC, or in air-gapped environments.
* **Nemotron 49B** (`nvidia/llama-3.3-nemotron-super-49b-v1.5`) — An open-source model with tool-calling support, making it a strong candidate for agentic workflows.

> **Note:** Model deployment on Cloudera AI Inference Service (selecting a model from the hub, choosing an optimization strategy, registering, and deploying to a resource profile) is outside the scope of this project.

## What This Proves

Using this setup, GSD successfully generated working Python code from single-prompt instructions — including patient data generation, file I/O, and basic healthcare logic — with Nemotron 49B handling the reasoning and code generation entirely on private infrastructure.

## Prerequisites

* Cloudera AI Workbench session
* Access to a Nemotron 49B deployment on Cloudera AI Inference Service
* The CAII model endpoint base URL (ends in `/v1`)

## Setup

### 1. Configure your endpoint

Open `models.json` and replace `CAII_ENDPOINT_URL` with your actual CAII model endpoint base URL:

```json
"baseUrl": "https://ml-XXXXX.your-cluster.cloudera.site/namespaces/serving-default/endpoints/your-model/v1"
```

### 2. Add your token

Open `token.txt`, delete the placeholder, and paste your API token from the CAII model endpoint UI.

### 3. Run setup

```bash
bash setup.sh
```

This installs Node.js 22, GSD, writes the provider config, loads your token, and generates `launch-gsd.sh`.

### 4. Initialize a project directory

GSD requires a git repo as its working directory:

```bash
mkdir my-project && cd my-project && git init
```

### 5. Launch GSD

```bash
bash launch-gsd.sh
```

When GSD prompts you to sign in, select **"Skip for now"** — auth is handled by the token you loaded.

When GSD asks about web search, select **"Skip for now"**.

## Run a Prompt

The demo prompt is in `prompt.md`. Copy the prompt block and paste it directly into the GSD session.

## Token Refresh

The API token expires after ~1 hour. When it expires:

1. Get a new token from the CAII model endpoint UI
2. Paste it into `token.txt`
3. Run `bash refresh-token.sh`
4. Restart GSD: `bash launch-gsd.sh`

If GSD is already running, open a second terminal, refresh the token, then `Ctrl+C` in the GSD tab and resume:

```bash
bash launch-gsd.sh -c
```

The `-c` flag resumes your last session without losing progress.

## Important: AWS Bedrock Isolation

GSD ships with an "AWS Auth" extension that auto-discovers Bedrock credentials from the environment. Since CAI workbench sessions run on AWS infrastructure (EKS), GSD will silently find Bedrock credentials and offer 90+ hosted models — defeating the entire private inference narrative.

`launch-gsd.sh` handles this by unsetting AWS credential environment variables before starting GSD, ensuring only the `cloudera-ai` provider is available.

If you launch GSD manually (without the wrapper), always include the provider flag:

```bash
gsd --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"
```

## Known Limitations

* **Single-shot prompts only.** Multi-turn project builds are not yet reliable due to context compaction behavior across sessions.
* **No web browsing or external lookups.** The agent operates entirely within the local environment.
* **Token expiry.** The 1-hour token lifecycle requires manual refresh. A platform-level DNS fix (CoreDNS or FreeIPA) would enable use of the auto-provisioned session JWT instead.

## What's Next

* Multi-turn project builds as GSD session management matures
* Testing additional open-source models on CAII for agentic quality comparison
* The full Patient Drug Interaction Checker demo — a Flask app built end-to-end by GSD on private infrastructure

## Project Structure

```
models.json         # Cloudera AI provider config — edit baseUrl before setup
token.txt           # Placeholder — replace with your real token from CAII
setup.sh            # One-time setup: Node.js, GSD, provider config, token
refresh-token.sh    # Quick token reload (no reinstall)
launch-gsd.sh       # Generated by setup.sh — starts GSD with Bedrock blocked
prompt.md           # Demo prompt — paste into GSD
```
