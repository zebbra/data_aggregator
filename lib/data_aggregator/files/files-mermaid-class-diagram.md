```mermaid
classDiagram
    class Attachment {
        UUID id
        String filename
        Integer byte_size
        String url
        String cached_file
        read()
        import_from_path(String path, String filename)
        destroy()
    }



```
