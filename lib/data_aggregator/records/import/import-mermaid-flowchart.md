```mermaid
stateDiagram-v2
pending --> validate_queued: enqueue_validate
validate_queued --> validating: validate
validating --> valid: validate
valid --> import_queued: enqueue_import
import_queued --> importing: import
importing --> imported: set_imported
imported --> import_queued: enqueue_import
imported --> importing: import
importing --> failed: set_failed
failed --> validating: validate
valid --> importing: import
validating --> invalid: validate
invalid --> validate_queued: enqueue_validate
invalid --> validating: validate
validating --> failed: set_failed
pending --> validating: validate
```
