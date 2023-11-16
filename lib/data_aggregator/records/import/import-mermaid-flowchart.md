```mermaid
stateDiagram-v2
pending --> queued: enqueue
queued --> running: run
running --> imported: set_imported
imported --> queued: enqueue
imported --> running: run
running --> failed: set_failed
failed --> queued: enqueue
failed --> running: run
pending --> running: run
```
