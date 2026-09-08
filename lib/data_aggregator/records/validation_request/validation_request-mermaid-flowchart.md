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
running --> failed: cancel_validation_request
queued --> running: set_running
queued --> failed: set_failed
queued --> failed: cancel_validation_request
pending --> running: run
pending --> running: set_running
```
