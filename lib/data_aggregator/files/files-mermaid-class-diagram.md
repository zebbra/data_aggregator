```mermaid
classDiagram
    class Attachment {
        UUID id
        String filename
        String url
        Function stream
        read()
        import_from_path(String path, UUID id, String filename)
        destroy()
    }



```
