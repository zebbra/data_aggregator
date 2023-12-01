```mermaid
stateDiagram-v2
pending --> pending: update_mapping
pending --> import_queued: enqueue_import
import_queued --> importing: import
importing --> imported: import
imported --> pending: update_mapping
imported --> import_queued: enqueue_import
importing --> imported: set_imported
importing --> failed: set_failed
failed --> pending: update_mapping
failed --> import_queued: enqueue_import
pending --> importing: import
```
