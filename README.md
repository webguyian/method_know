# Method Know

_Real-Time Knowledge Sharing with Phoenix LiveView_

## Tech Stack

- [Elixir](https://elixir-lang.org/) (>= 1.16)
- [Phoenix Framework](https://www.phoenixframework.org/) (>= 1.8)
- [Ecto](https://hexdocs.pm/ecto/Ecto.html) (database wrapper)
- [SQLite](https://www.sqlite.org/) (database)
- [Tailwind CSS](https://tailwindcss.com/) (utility-first styling)
- [Lucide Icons](https://lucide.dev/) (icon set)
- [Req](https://hexdocs.pm/req/Req.html) (HTTP client)
- [Mox](https://hexdocs.pm/mox/Mox.html) (test mocking)

## Getting Started

### Prerequisites

- Elixir and Erlang installed ([see guide](https://elixir-lang.org/install.html))
- Phoenix (`mix archive.install hex phx_new`)

### Setup

Install dependencies:

```sh
mix deps.get
```

### Database Setup

```sh
mix ecto.setup
```

### Running the Server

```sh
mix phx.server
```

### Running Tests

```sh
mix test
```

### Linting & Formatting

```sh
mix format
```

### Pre-commit Checks

```sh
mix precommit
```

---

For more, see the [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html).
