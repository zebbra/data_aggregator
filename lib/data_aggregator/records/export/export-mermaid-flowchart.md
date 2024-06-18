```mermaid
stateDiagram-v2
pending --> queued: enqueue
queued --> running: run
running --> exported: set_exported
exported --> queued: enqueue
exported --> running: run
exported --> running: set_running
running --> failed: set_failed
failed --> queued: enqueue
failed --> running: run
failed --> running: set_running
queued --> running: set_running
pending --> running: run
pending --> running: set_running
```
