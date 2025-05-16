# Data Aggregator

<!-- MDOC -->

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL%20v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

Data Aggregator is an open-source tool designed to integrate biodiversity data into a Darwin Core compatible format. It provides a robust framework for scientists, researchers, and biodiversity data managers to standardize and consolidate various data sources.

## Features

- Convert biodiversity data to Darwin Core format
- Validate and clean data entries
- Manage taxonomic hierarchies
- Geolocation support and validation
- Export data to various formats
- RESTful API for integration with other systems
- Interactive web interface using Phoenix LiveView

## Project

- Report a bug or request a feature by [creating an issue](https://github.com/zebbra/data_aggregator/issues/new)
- Contribute by submitting a [pull request](https://github.com/zebbra/data_aggregator/pulls)
- Explore the current [data model](https://dbdiagram.io/d/data-aggregator-basic-65393c35ffbf5169f071ed3f)
- View our development notes on [Miro](https://miro.com/app/board/uXjVMBLi0fk=/)

## Getting Started

### Prerequisites

- Elixir (see `.tool-versions` for the recommended version)
- Erlang (see `.tool-versions` for the recommended version)
- PostgreSQL
- Node.js and npm

### Installation

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/data_aggregator.git
   cd data_aggregator
   ```

2. Install dependencies
   ```bash
   mix deps.get
   cd assets && npm install && cd ..
   ```

3. Configure the database (copy `config/dev.exs.example` to `config/dev.exs` if available and update settings)

4. Create and migrate your database
   ```bash
   mix ecto.setup
   ```

5. Start the Phoenix server
   ```bash
   mix phx.server
   ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Documentation

### Project Documentation

- [Overview](./docs/overview.md)
- [Development](./docs/development.md)
- [Deployment](./docs/deployment.md)
- [API](./docs/api.md)
- [Security](./SECURITY.md)
- [License](./LICENSE.md)
- [Code Of Conduct](./CODE_OF_CONDUCT.md)
- [Contribution](./CONTRIBUTION.md)

### API Documentation

When running the application, you can access:
- [Swagger UI](http://localhost:4000/api/json/swagger) (local development)
- [ReDoc](http://localhost:4000/api/json/redoc) (local development)
- [HexDocs](http://localhost:4000/docs/index.html) (local development)

For production instances, replace the localhost URL with your deployment URL.

### Development Tools (Local Development Only)

- [Styleguide](http://localhost:4000/storybook/welcome)
- [Dashboard](http://localhost:4000/dev/dashboard/home)
- [Oban Job Queue](http://localhost:4000/dev/dashboard/oban)

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to get started.

Please note that this project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating in this project, you agree to abide by its terms.

By contributing to this project, you agree that your contributions will be licensed under the GNU AGPLv3 license.

## Security

For information about our security policy and how to report security vulnerabilities, please see our [Security Policy](SECURITY.md).

## License

This project is licensed under the GNU Affero General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

We provide additional documentation to help you understand and comply with the AGPLv3:
- [License Implications](LICENSE-IMPLICATIONS.md) - Understanding what AGPLv3 means for your use case
- [AGPLv3 Compliance Guide](docs/agpl_compliance.md) - Practical guide to compliance

## Acknowledgements

- Thanks to all our [contributors](https://github.com/zebbra/data_aggregator/graphs/contributors)
- Built with [Phoenix](https://www.phoenixframework.org/), [Ash Framework](https://ash-hq.org/), and [Tailwind CSS](https://tailwindcss.com/)
- Darwin Core standards by [TDWG](https://www.tdwg.org/standards/dwc/)
