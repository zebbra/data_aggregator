```mermaid
classDiagram
    class Attachment {
        UUID id
        String filename
        String url
        String cached_file
        read()
        import_from_path(String path)
        destroy()
    }



```
