# ML Researcher — Specification

> ML Research Engineer Agent for experiments, training, and evaluation

## Agent Role

ML Researcher is a specialized agent for machine learning research workflows. It handles:
- Experiment design and execution
- Training pipeline management
- Model evaluation and benchmarking
- Research documentation and reproducibility

## Architecture

```
ML Researcher
├── Core Agent (inherited from Gen Code)
│   ├── LLM Provider abstraction (multi-provider: Anthropic, OpenAI, Google, Moonshot, Alibaba, MiniMax)
│   ├── Tool system & MCP integration
│   └── Session management
├── ML-Specific Components
│   ├── Experiment Tracker
│   ├── Training Controller
│   └── Evaluation Engine
└── Knowledge Base (internal ML playbook)
```

## ML Agents

| Agent | Capability |
|-------|------------|
| **Researcher** | Literature review, architecture exploration, hypothesis generation |
| **Experimenter** | Run training, track metrics, manage hyperparameters |
| **Evaluator** | Benchmark models, generate evaluation reports |
| **DataHandler** | Data preprocessing, augmentation, pipeline management |

## Communication

All ML agents communicate via [Bell](https://github.com/genai-io/bell) event bus:

```
ml.experiment.started
ml.training.progress
ml.evaluation.completed
ml.model.registered
```

## Integration

- **Inherits from Gen Code**: Core agent functionality, tool system, session management
- **Managed by Orchestrator**: Lifecycle controlled by [orchestrator](https://github.com/genai-io/orchestrator)
- **Uses Bell**: Pub/sub for experiment events and inter-agent communication

## Knowledge Integration

ML Researcher embeds ML knowledge via:
- **Static playbook**: training tricks, model architectures, hyperparameter的经验值
- **Dynamic search**: integrate with search tools for latest papers/techniques
- **Auto-research**: ability to autonomously explore and update knowledge

## Related

- [Gen Code](https://github.com/genai-io/gen-code) — General-purpose coding agent (base)
- [Orchestrator](https://github.com/genai-io/orchestrator) — Agent lifecycle manager
- [Bell](https://github.com/genai-io/bell) — Event bus for inter-agent messaging
- [Spec](https://github.com/genai-io/spec) — Overall system architecture