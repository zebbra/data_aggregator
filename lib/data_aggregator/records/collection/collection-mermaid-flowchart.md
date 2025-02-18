```mermaid
stateDiagram-v2
idle --> mapping: set_mapping
mapping --> idle: set_idle
idle --> importing: set_importing
importing --> idle: set_idle
idle --> exporting: set_exporting
exporting --> idle: set_idle
idle --> encoding: set_encoding
encoding --> idle: set_idle_encoding
idle --> fast_track_publishing: set_fast_track_publishing
fast_track_publishing --> idle: set_idle
idle --> validating: set_validating
validating --> idle: set_idle
idle --> deleting: set_deleting
```
