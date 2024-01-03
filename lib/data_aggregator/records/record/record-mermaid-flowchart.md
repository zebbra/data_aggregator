```mermaid
stateDiagram-v2
imported --> imported: set_imported
imported --> queued: enqueue_encoder
queued --> encoding: set_encoding
encoding --> encoded: set_encoded
encoded --> imported: set_imported
encoded --> encoding: set_encoding
encoding --> failed: set_failed
failed --> imported: set_imported
failed --> encoding: set_encoding
imported --> encoding: set_encoding
```
