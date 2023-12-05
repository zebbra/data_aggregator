```mermaid
classDiagram
    class Job {
        Integer id
        Atom state
        String queue
        String worker
        Map args
        Map[] errors
        Integer attempt
        String[] attempted_by
        Integer max_attempts
        read()
    }



```
