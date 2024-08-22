```mermaid
stateDiagram-v2
idle --> importing: set_importing
importing --> idle: set_idle
idle --> exporting: set_exporting
exporting --> idle: set_idle
idle --> encoding: set_encoding
encoding --> idle: set_idle_encoding
idle --> fast_track_publishing: set_fast_track_publishing
fast_track_publishing --> idle: set_idle
idle --> approving: set_approving
approving --> idle: set_idle
idle --> deleting: set_deleting
```
