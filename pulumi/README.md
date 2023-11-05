# Pulumi

This example Pulumi project create Scheduler, PubSub, Cloud Functions to schedule start and stop GKE node pools, Compute Engine, SQL instances.

## Getting Started

### Prerequisites

- Pulumi
- Node.js ~> 18.x

### Usage

Create new stack:

```
pulumi stack init <your-stack-name>
```

Setup required stack configs:

```
pulumi config set gcp:project <project-id>
pulumi config set gcp:region <region>
pulumi config set scheduledProject <project-id>
```

Apply stack:

```
pulumi up
```