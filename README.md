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

- **[GSD-2](https://github.com/gsd-build/gsd-2)** — An open-source agentic coding CLI built on the Pi SDK. Supports spec-driven workflows with research, plan, execute, and verify phases.
- **[Pi SDK](https://github.com/badlogic/pi-mono)** — The agent runtime underneath GSD-2. Connects to any OpenAI-compatible provider via a simple JSON config.
- **Cloudera AI Inference Service** — Hosts the model privately and exposes an OpenAI-compatible `/v1/chat/completions` endpoint. Supports NVIDIA NIM and Hugging Face model runtimes. Deployable on-prem, in VPC, or in air-gapped environments.
- **Nemotron 49B** (`nvidia/llama-3.3-nemotron-super-49b-v1.5`) — An open-source model with tool-calling support, making it a strong candidate for agentic workflows. This is one of several models deployable on CAII; it was chosen for this demo because of its reasoning capabilities and function-calling support.

> **Note:** Model deployment on Cloudera AI Inference Service (selecting a model from the hub, choosing an optimization strategy, registering, and deploying to a resource profile) is outside the scope of this project. A walkthrough of that process is coming in a follow-up article.

## What This Proves

Using this setup, GSD successfully generated working Python code from single-prompt instructions — including patient data generation, file I/O, and basic healthcare logic — with Nemotron 49B handling the reasoning and code generation entirely on private infrastructure.

<!-- Screenshots: insert GSD prompt + Nemotron output here -->

This is early-stage. The goal is not to replicate Claude Code feature-for-feature, but to demonstrate that the foundational experience — describe what you want, agent builds it — works on models and infrastructure you fully control.

## Known Limitations

- **Single-shot prompts only.** Prompts are designed to complete in one shot. Multi-turn, multi-session project builds (e.g. "add a feature to yesterday's app") are not yet reliable due to GSD's context compaction behavior across sessions.
- **No web browsing or external lookups.** The agent operates entirely within the local environment — no internet access during inference.

## What's Next

- Multi-turn project builds as GSD session management matures
- Testing additional open-source models on CAII for agentic quality comparison
- The full Patient Drug Interaction Checker demo — a Flask app built end-to-end by GSD on private infrastructure

## Prerequisites

- Cloudera AI Workbench session
- Access to a Nemotron 49B deployment on Cloudera AI Inference Service

## Setup

**1. Install Node.js 22 and GSD** *(one-time per workbench session)*

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 22
npm install -g gsd-pi@latest
```

**2. Get your API token**

Open the CAII model endpoint UI and copy your API token. Open `token.txt` in this repo, delete the placeholder, and paste your token in.

**3. Load your token**

```bash
bash refresh-token.sh
```

This writes your token to GSD's auth config and prints the exact command to launch GSD.

**4. Initialize a project directory**

GSD requires a git repo as its working directory. Create one before launching:

```bash
mkdir my-project && cd my-project && git init
```

**5. Launch GSD**

```bash
gsd --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"
```

When GSD prompts you to sign in, select **"Skip for now"** — auth is handled by the token you loaded in step 3.

When GSD asks about web search, select **"Skip for now"** — no external search is needed.

## Run a Prompt

Prompts are in the `prompts/` folder. Each is self-contained and designed to complete in a single shot.

Copy the prompt and paste it directly into the GSD session.

## Token Refresh

The API token expires after ~1 hour. When it expires:

1. Get a new token from the CAII model endpoint UI
2. Open `token.txt` and replace the old token with the new one
3. Re-run `bash refresh-token.sh`
4. Re-launch GSD: `gsd --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"`

If GSD is already running when the token expires, open a second terminal tab, refresh the token, then `Ctrl+C` in the GSD tab and resume with:

```bash
gsd -c --provider cloudera-ai --model "nvidia/llama-3.3-nemotron-super-49b-v1.5"
```

The `-c` flag resumes your last session without losing progress.

## Project Structure

```
prompts/            # Self-contained GSD prompts — start here
refresh-token.sh    # Loads token from token.txt into GSD's auth config
token.txt           # Placeholder — replace with your real token from CAII endpoint UI
```

Generated output (scripts, data files, reports) is created by GSD at runtime in your project directory and is not tracked in this repo.
