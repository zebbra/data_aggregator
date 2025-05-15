# Contributing to Data Aggregator

First of all, thank you for considering contributing to Data Aggregator! It's people like you that make this project better. This document provides guidelines and instructions for contributing to this project.

## Code of Conduct

By participating in this project, you are expected to uphold our Code of Conduct. Please report unacceptable behavior to the project maintainers.

## Getting Started

get a brief [overview](docs/overview.md) about the project itself.

### Prerequisites

- Elixir (see `.tool-versions` for the recommended version)
- Erlang (see `.tool-versions` for the recommended version)
- PostgreSQL
- Node.js and npm (for asset compilation)
- Docker (optional, for running dependencies in containers)

### Setting Up Your Development Environment

follow the [instructions](docs/development.md) to setup your development environment

## Development Workflow

1. Create a new branch for your feature or bugfix:
   ```
   git checkout -b feature/your-feature-name
   ```
   or
   ```
   git checkout -b fix/issue-you-are-fixing
   ```

2. Make your changes, following our coding standards

3. Write tests that verify your changes

4. Run the test suite to ensure all tests pass:
   ```
   mix test
   ```

5. Update documentation as needed

6. Commit your changes with a clear commit message:
   ```
   git commit -m "feat: your feature description"
   ```

7. Push to your fork:
   ```
   git push origin feature/your-feature-name
   ```

8. Submit a Pull Request through GitHub

## Pull Request Guidelines

- PRs should focus on a single concern
- Include tests for any new functionality
- Update documentation as needed
- Follow our code style guidelines
- Write a descriptive PR title and detailed description
- Reference any related issues using GitHub's issue linking
- Be ready to address review feedback

## Coding Standards

### Elixir Code

- Follow the official [Elixir Formatting Guidelines](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html)
- Run `mix format` before committing to ensure consistent code style
- Use `mix credo` to check for code quality issues
- Follow the [Phoenix Best Practices](https://hexdocs.pm/phoenix/overview.html)
- Adhere to the [Ash Framework Guidelines](https://hexdocs.pm/ash/readme.html)

### Web Assets

- Follow Tailwind CSS conventions
- Organize CSS using utility-first approach as recommended by Tailwind
- Use daisyUI components when appropriate

## Testing

- Write tests for all new functionality
- Maintain or improve test coverage
- Tests should be fast and deterministic
- Use appropriate testing tools:
  - ExUnit for unit tests
  - Phoenix LiveViewTest for LiveView tests
  - Ash Test Helpers for resource tests

## Documentation

- Update documentation for any changed functionality
- Document new features, API endpoints, or configuration options
- Keep README and other documentation in sync with code changes
- Use clear, concise language and examples

## Releases

Our project follows [Semantic Versioning](https://semver.org/). Please consider the impact of your changes for versioning:

- MAJOR version for incompatible API changes
- MINOR version for backward-compatible functionality additions
- PATCH version for backward-compatible bug fixes

## Community and Communication

- Join our discussions in GitHub issues
- Ask questions if you're unsure about anything
- Be respectful and considerate in all communications
- Help others who have questions about the project

## License

By contributing to Data Aggregator, you agree that your contributions will be licensed under the project's [GNU AGPL-3.0 License](LICENSE).

## Questions?

If you have any questions about contributing, please open an issue or contact one of the project maintainers.

Thank you for contributing to Data Aggregator!
