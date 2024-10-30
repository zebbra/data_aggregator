```mermaid
stateDiagram-v2
new --> extraction_queued: enqueue_extraction
extraction_queued --> extracting: extract
extracting --> extracted: extract
extracted --> mapping_queued: enqueue_mapping
mapping_queued --> mapping: map
mapping --> mapped: map
mapped --> mapping_queued: enqueue_mapping
mapping --> mapped: set_mapped
mapping --> mapping_failed: set_mapping_failed
mapping_failed --> mapping_queued: enqueue_mapping
mapping --> mapping_failed: cancel_mapping
mapping_queued --> mapping: set_mapping
mapping_queued --> mapping_failed: set_mapping_failed
mapping_queued --> mapping_failed: cancel_mapping
extracted --> mapping: map
extracted --> mapping: set_mapping
extracting --> extracted: set_extracted
extracting --> extraction_failed: set_extraction_failed
extraction_queued --> extracting: set_extracting
extraction_queued --> extraction_failed: set_extraction_failed
new --> extracting: extract
new --> extracting: set_extracting
```
