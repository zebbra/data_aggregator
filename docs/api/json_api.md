## JSON Rest API

### Accessible Resources

The application exposes a REST API that gives the user access to the following resources:

#### Datasets

```
GET /api/json/datasets
POST /api/json/datasets
DELETE /api/json/datasets/{id}
GET /api/json/datasets/{id}
PATCH /api/json/datasets/{id}
```

#### Records

```
GET /api/json/datasets/{collection_id}/records
POST /api/json/datasets/{collection_id}/records
DELETE /api/json/datasets/{collection_id}/records/{id}
GET /api/json/datasets/{collection_id}/records/{id}
PATCH /api/json/datasets/{collection_id}/records/{id}
GET /api/json/datasets/{collection_id}/record_versions
GET /api/json/datasets/{collection_id}/record_versions/{id}
```

#### EncodedRecords

```
GET /api/json/datasets/{collection_id}/encoded_records
DELETE /api/json/datasets/{collection_id}/encoded_records/{id}
GET /api/json/datasets/{collection_id}/encoded_records/{id}
PATCH /api/json/datasets/{collection_id}/encoded_records/{id}
GET /api/json/datasets/{collection_id}/encoded_record_versions
GET /api/json/datasets/{collection_id}/encoded_record_versions/{id}
```

#### Imports

```
GET /api/json/datasets/{collection_id}/imports
POST /api/json/datasets/{collection_id}/imports
DELETE /api/json/datasets/{collection_id}/imports/{id}
GET /api/json/datasets/{collection_id}/imports/{id}
PATCH /api/json/datasets/{collection_id}/imports/{id}
```

#### Exports

```
GET /api/json/datasets/{collection_id}/exports
POST /api/json/datasets/{collection_id}/exports
DELETE /api/json/datasets/{collection_id}/exports/{id}
GET /api/json/datasets/{collection_id}/exports/{id}
PATCH /api/json/datasets/{collection_id}/exports/{id}
```

#### Publications

```
GET /api/json/datasets/{collection_id}/publications
POST /api/json/datasets/{collection_id}/publications
DELETE /api/json/datasets/{collection_id}/publications/{id}
GET /api/json/datasets/{collection_id}/publications/{id}
PATCH /api/json/datasets/{collection_id}/publications/{id}
```

#### Validations

```
GET /api/json/datasets/{collection_id}/validations
POST /api/json/datasets/{collection_id}/validations
DELETE /api/json/datasets/{collection_id}/validations/{id}
GET /api/json/datasets/{collection_id}/validations/{id}
PATCH /api/json/datasets/{collection_id}/validations/{id}
PATCH /api/json/datasets/{collection_id}/validations/{id}/enqueue
```

#### Validated Records

```
GET /api/json/datasets/{collection_id}/validated_records
DELETE /api/json/datasets/{collection_id}/validated_records/{id}
GET /api/json/datasets/{collection_id}/validated_records/{id}
PATCH /api/json/datasets/{collection_id}/validated_records/{id}
```

#### Swiss Species

```
GET /api/json/swiss_species
POST /api/json/swiss_species
DELETE /api/json/swiss_species/{id}
GET /api/json/swiss_species/{id}
PATCH /api/json/swiss_species/{id}
```

#### Users

```
GET /api/json/users
POST /api/json/users
POST /api/json/users/sign_in
DELETE /api/json/users/{id}
GET /api/json/users/{id}
PATCH /api/json/users/{id}
```

### General Usage

To use the Rest API, you need to authenticate with a valid user. The authentication is done via a API Token, which you can obtain by signing in with your credentials.

```bash
# Request Headers
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json

# Request path and body
POST /api/json/users/sign_in

{
  "data": {
    "attributes": {
      "email": "your-user",
      "password": "your-password"
    },
    "type": "users"
  }
}
```

This will give you:

```bash
"data": {
        "attributes": {
            "email": "dagi@zebbra.ch"
            ...
        },
        "id": "usr_02yBOPLbXO8Psxd6Pe8jA8",
        "type": "users",
        ...
  },
  "meta": {
      "token": "eyJhbGciOiJfj8dsbiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJ-PiA0LjYiLCJleHAiOjE3NDM4NTYzNTEsImlhdCI6MTc0Mzc2OTk1MSwiaXNzIjoiQXNoQXV0aGVudGskdi7ab24gdjQuNi4zIiwianRpIjoiMzBwaHIyMG40MzQwY2syaTlzMDAwcG0xIiwibmJmIjoxNzQzNzY5OTUxLCJwdXJwb3NldmLS9FNlciIsInN1YiI6InVzZXI_aWQ9dXNyXzAyeUJPUExiWE84UHN4ZDZQZThqQTgifQ.OrF4eb2NkM2OwNcy0TkV8ihSDMWoB33NW2l58fur7ew"
  },
  ...
}
```

You can use the API Token under `meta.token` to authenticate your requests by adding it to the `authorization` header of your subsequent requests, like:

```bash
# Authorization header
authorization: "eyJhbGciOiJ..."

# Other headers
Content-Type: application/vnd.api+json
Accept: application/vnd.api+json
...

# Request path and body
GET /api/json/datasets
```

### Open API Spec

The API is documented with [OpenAPI](https://swagger.io/specification/) and can be accessed [here](https://dagi.gbif.ch/api/json/open_api)

### Postman Collection

The [Postman Collection](./postman_collection) gives you a better usability to test and explore the API. You need an active user to login, to use the API.
