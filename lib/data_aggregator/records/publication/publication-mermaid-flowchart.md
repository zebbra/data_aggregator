```mermaid
stateDiagram-v2
pending --> queued: enqueue
queued --> running: run
running --> done: set_done
done --> queued: enqueue
done --> running: run
done --> running: set_running
running --> failed: set_failed
failed --> queued: enqueue
failed --> running: run
failed --> running: set_running
running --> failed: cancel_publication
queued --> running: set_running
queued --> failed: cancel_publication
pending --> running: run
pending --> running: set_running
```
