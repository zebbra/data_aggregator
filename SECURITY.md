# Security Policy

## Reporting a Vulnerability

The Data Aggregator team takes security issues seriously. We appreciate your efforts to responsibly disclose your findings and will make every effort to acknowledge your contributions.

To report a security vulnerability, please **DO NOT** open a public GitHub issue. Instead, please send an email to [security@zebbra.ch](mailto:security@zebbra.ch) with the following information:

* A description of the vulnerability
* Steps to reproduce the issue
* Potential impact of the vulnerability
* Suggested fix (if available)

## What to Expect

Here's what you can expect after reporting a vulnerability:

1. **Acknowledgment**: We will acknowledge receipt of your vulnerability report within 3 business days.

2. **Verification**: Our security team will work to verify the vulnerability and determine its impact.

3. **Remediation**: We will develop and test a fix for the vulnerability.

4. **Disclosure**: Once the vulnerability has been fixed, we will publish a security advisory detailing the vulnerability, its impact, and steps users should take to update their installations.

## Security Updates

Security updates will be released as part of our regular release cycle or as emergency patches, depending on severity.

We encourage all users to keep their installations up to date with the latest security patches.

## Supported Versions

Generally, only the most recent major version of Data Aggregator is supported with security updates. We recommend always using the latest version of the software.

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |
| < latest | :x:                |

## Security Best Practices

When deploying Data Aggregator, we recommend following these security best practices:

1. Keep your installation up to date with the latest security patches
2. Use strong, unique passwords for all administrator accounts
3. Implement proper access controls and user permissions
4. Use HTTPS for all production deployments
5. Restrict access to your database and API endpoints
6. Regularly review logs for suspicious activity
7. Store sensitive configuration values in environment variables, not in code
8. Be aware of the AGPLv3 license requirements, particularly regarding network use and providing source code access to users

## Thank You

We value the security researcher community and believe that responsible disclosure of security vulnerabilities helps us ensure the security and privacy of our users. Thank you for helping keep Data Aggregator and our users safe!
