# vet - Security Vetting Tools

Security tools for vetting dependencies and packages before installation.

## Setup

Requires [mise](https://mise.jdx.dev/)

```bash
cd ~/.local/share/vet
mise install
```

## Usage

### Vet a tool before installing

```bash
./vet-tool.sh https://github.com/junegunn/fzf
./vet-tool.sh --deep https://github.com/charmbracelet/gum  # clone and scan
./vet-tool.sh npm:prettier
./vet-tool.sh pypi:requests
./vet-tool.sh go:github.com/charmbracelet/gum
```

### Scan project dependencies

```bash
./vet-deps.sh .
./vet-deps.sh ~/projects/my-app
./vet-deps.sh --skip-scorecard .  # faster, no API calls
```

## Tools

| Tool         | Purpose                                        |
| ------------ | ---------------------------------------------- |
| scorecard    | OpenSSF security scorecard for GitHub repos    |
| osv-scanner  | Google's vulnerability scanner                 |
| trivy        | Container and filesystem vulnerability scanner |
| gitleaks     | Secrets detection                              |
| gosec        | Go security linter                             |
| govulncheck  | Official Go vulnerability checker              |
| cargo-audit  | Rust security advisories                       |
| cargo-deny   | Rust license and dependency policy             |
| cargo-geiger | Rust unsafe code detection                     |
| semgrep      | Multi-language static analysis                 |
| bandit       | Python security linter                         |
| pip-audit    | Python dependency vulnerabilities              |
| guarddog     | Malicious PyPI/npm package detection           |
| socket       | Socket.dev supply chain security               |

## Environment Variables

- `GITHUB_TOKEN`
  - Avoids API rate limiting
- `SCORECARD_THRESHOLD`
  - Minimum acceptable score (default: 5)
