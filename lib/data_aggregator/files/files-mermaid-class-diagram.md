```mermaid
classDiagram
    class Attachment {
        UUID id
        String filename
        Integer byte_size
        UtcDatetimeUsec inserted_at
        UtcDatetimeUsec updated_at
        read()
        import_from_path(String path, String filename)
        destroy()
    }



```
