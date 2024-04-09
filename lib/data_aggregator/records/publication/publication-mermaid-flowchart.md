```mermaid
stateDiagram-v2
pending --> queued: enqueue
queued --> running: run
running --> done: set_done
done --> queued: enqueue
done --> running: run
running --> failed: set_failed
failed --> queued: enqueue
failed --> running: run
pending --> running: run
```
