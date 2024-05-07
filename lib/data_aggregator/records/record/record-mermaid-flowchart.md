```mermaid
stateDiagram-v2
imported --> imported: set_imported
imported --> queued: enqueue_encoder
queued --> encoding: set_encoding
encoding --> imported: set_imported
encoding --> queued: enqueue_encoder
encoding --> encoded: set_encoded
encoded --> imported: set_imported
encoded --> queued: enqueue_encoder
encoded --> encoding: set_encoding
encoding --> failed: set_encoding_failed
failed --> imported: set_imported
failed --> queued: enqueue_encoder
failed --> encoding: set_encoding
imported --> encoding: set_encoding
```
