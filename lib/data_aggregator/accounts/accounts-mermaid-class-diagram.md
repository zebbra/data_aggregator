```mermaid
classDiagram
    class User {
        UUID id
        CiString email
        String first_name
        String last_name
        String phone
        UtcDatetime terms_accepted_at
        sign_in_with_token(String token)
        sign_in_with_password(CiString email, String password)
        get_by_subject(String subject)
        destroy()
        read()
        update(String password, String[] roles, String first_name, String last_name, ...)
        accept_terms(CiString email, String first_name, String last_name, String phone, ...)
        set_password(String password, CiString email, String first_name, String last_name, ...)
        register_with_password(String password, String[] roles, String first_name, String last_name, ...)
    }
    class Token {
        Map extra_data
        String purpose
        UtcDatetime expires_at
        String subject
        String jti
        get_token(String token, String jti, String purpose)
        store_token(String token, Map extra_data, String purpose)
        store_confirmation_changes(String token, Map extra_data, String purpose)
        get_confirmation_changes(String jti)
        revoked?(String token, String jti)
        revoke_all_stored_for_subject(String subject, Map extra_data)
        revoke_jti(String jti, String subject, Map extra_data)
        revoke_token(String token, Map extra_data)
        read_expired()
        expunge_expired()
    }



```
