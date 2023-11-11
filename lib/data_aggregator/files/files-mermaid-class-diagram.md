```mermaid
classDiagram
    class Attachment {
        UUID id
        String filename
        String url
        read()
        import_from_path(String path)
        destroy()
    }



```
