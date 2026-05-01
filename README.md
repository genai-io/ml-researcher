# ML Researcher

<p align="center">
  <h1 align="center">< ML ✦ /></h1>
  <p align="center">
    <strong>ML Research Engineer Agent for experiments, training, and evaluation</strong>
  </p>
  <p align="center">
    <a href="https://github.com/genai-io/ml-researcher/releases"><img src="https://img.shields.io/github/v/release/genai-io/ml-researcher?style=flat-square" alt="Release"></a>
    <a href="https://goreportcard.com/report/github.com/genai-io/ml-researcher"><img src="https://goreportcard.com/badge/github.com/genai-io/ml-researcher?style=flat-square" alt="Go Report Card"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue?style=flat-square" alt="License"></a>
  </p>
</p>

Multi-agent AI system for machine learning research. Orchestrates specialized agents for experiments, training pipelines, evaluation, and model lifecycle management — inspired by [Claude Code](https://claude.ai/code) but purpose-built for ML workflows.

## Features

- **Multi-agent orchestration** — Event-driven coordination of specialized ML agents
- **Experiment tracking** — Automated logging, metric capture, and run comparison
- **Training pipelines** — Build, execute, and monitor training workflows
- **Evaluation & benchmarking** — Systematic model assessment with customizable metrics
- **Multi-provider** — Anthropic, OpenAI, Google, Moonshot, Alibaba, MiniMax
- **Tools & MCP** — Built-in ML tools (data, training, eval) + [MCP](https://modelcontextprotocol.io) integration
- **Session & replay** — Auto-persist experiment sessions, resume, fork
- **Hooks** — Lifecycle extensibility via shell, LLM, agent, or HTTP hooks

### Agents

| Agent | Role |
|:------|:-----|
| **Researcher** | Literature review, architecture exploration, hypothesis generation |
| **Experimenter** | Run training, track metrics, manage hyperparameters |
| **Evaluator** | Benchmark models, generate evaluation reports |
| **DataHandler** | Data preprocessing, augmentation, pipeline management |

## Installation

```bash
go install github.com/genai-io/ml-researcher/cmd/mlr@latest
```

Or build from source:

```bash
git clone https://github.com/genai-io/ml-researcher.git
cd ml-researcher
go build -o mlr ./cmd/mlr
```

## Usage

```bash
# Interactive mode
mlr

# Run experiment
mlr "train a ResNet50 on CIFAR-10 with data augmentation"

# Resume session
mlr --resume
```

## Configuration

ML Researcher stores configuration in `~/.mlr/`:

```
~/.mlr/
├── providers.json    # LLM provider connections
├── settings.json     # User settings (permissions, hooks, env)
├── experiments/      # Experiment runs and logs
├── agents/           # Custom agent definitions
└── plugins/          # Installed plugins
```

## Related Projects

- [Gen Code](https://github.com/genai-io/gen-code) — General-purpose AI coding assistant
- [Claude Code](https://claude.ai/code) — Anthropic's AI coding assistant

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.