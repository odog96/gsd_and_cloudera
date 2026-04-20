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
- Node.js 22 (via NVM)
- GSD v2.73+: `npm install -g gsd-pi@latest`

## Setup

**1. Get your API token**
Open the CAII model endpoint UI and copy your API token. Paste it into `token.txt`:

```bash
nano token.txt
```

**2. Initialize a project directory**

```bash
mkdir my-project && cd my-project && git init
```

**3. Launch GSD**

```bash
bash ~/run-gsd.sh
```

## Run a Prompt

Prompts are in the `prompts/` folder. Each is self-contained and designed to complete in a single shot. Start with `attempt-01.md`, then try `attempt-02.md` for a more ambitious demo.

Copy the prompt block and paste it directly into the GSD session.

## Token Refresh

The API token expires after ~1 hour. To refresh:
1. Get a new token from the CAII model endpoint UI
2. Paste it into `token.txt`
3. Re-run `bash ~/run-gsd.sh`

## Project Structure

```
prompts/          # Self-contained GSD prompts — start here
run-gsd.sh        # Launcher: loads token, activates Node, starts GSD
token.txt         # Your API token — not committed, add to .gitignore
```

Generated output (patient files, scripts, reports) is created by GSD at runtime and is not tracked in this repo.
