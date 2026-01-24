#!/usr/bin/env bash
# shellcheck disable=SC2310 # check_command is designed for use in conditionals
# vet-deps.sh - Scan project dependencies for vulnerabilities
#
# Usage:
#   ./vet-deps.sh [project-directory]
#   ./vet-deps.sh .
#   ./vet-deps.sh ~/projects/my-app

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCORECARD_DEP_LIMIT="${SCORECARD_DEP_LIMIT:-5}"
SCORECARD_THRESHOLD="${SCORECARD_THRESHOLD:-5}"
SKIP_SCORECARD="${SKIP_SCORECARD:-false}"
VERBOSE="${VERBOSE:-false}"

log_info() { echo -e "${BLUE}ℹ ${NC} $*"; }
log_ok() { echo -e "${GREEN}✓ ${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠ ${NC} $*"; }
log_error() { echo -e "${RED}✗ ${NC} $*"; }
log_section() { echo -e "\n${BLUE}--- ${NC} $* ${BLUE} ---${NC}"; }
log_subsection() { echo -e "\n${BLUE}→ ${NC} $*"; }

check_command() {
  if ! command -v "$1" &>/dev/null; then
    log_warn "Command '$1' not found - skipping related checks"
    return 1
  fi
  return 0
}

VULNS_FOUND=0
WARNINGS_FOUND=0

run_scorecard_on_deps() {
  local deps=("$@")

  if [[ ${SKIP_SCORECARD} == "true" ]]; then
    log_info "Skipping Scorecard checks (SKIP_SCORECARD=true)"
    return
  fi

  if ! check_command scorecard; then
    return
  fi

  log_subsection "Scorecard Analysis (top ${SCORECARD_DEP_LIMIT} dependencies)"

  if [[ -z ${GITHUB_TOKEN-} ]]; then
    log_warn "GITHUB_TOKEN not set - may be rate limited"
  fi

  local count=0
  for dep in "${deps[@]}"; do
    [[ ${count} -ge ${SCORECARD_DEP_LIMIT} ]] && break

    if [[ ${dep} != *github.com* ]]; then
      continue
    fi

    local repo_url
    repo_url="https://github.com/$(echo "${dep#*github.com/}" | cut -d'/' -f1-2)"

    echo -e "\n  ${BLUE}${repo_url}${NC}"

    local result
    local stderr_file
    stderr_file=$(mktemp)
    local scorecard_cmd="scorecard --repo=${repo_url} --checks=Maintained,Vulnerabilities,Code-Review,Branch-Protection --format=json"

    log_info "Running: ${scorecard_cmd}"

    if result=$(scorecard --repo="${repo_url}" --checks=Maintained,Vulnerabilities,Code-Review,Branch-Protection --format=json 2>"${stderr_file}"); then
      local score
      score=$(echo "${result}" | jq -r '.score // 0')

      if (($(echo "${score} < ${SCORECARD_THRESHOLD}" | bc -l))); then
        log_warn "  Score: ${score}/10 (below threshold)"
        ((WARNINGS_FOUND++)) || true
      else
        echo "    Score: ${score}/10"
      fi

      echo "${result}" | jq -r '.checks[] | "    \(.name): \(.score)/10\(if .score < 5 then " ⚠" else "" end)"'
    else
      echo "    (could not fetch scorecard)"
      if [[ -s ${stderr_file} ]]; then
        sed 's/^/    /' "${stderr_file}" >&2
      fi
    fi
    rm -f "${stderr_file}"

    ((count++)) || true
  done

  if [[ ${#deps[@]} -gt ${SCORECARD_DEP_LIMIT} ]]; then
    log_info "Showing ${SCORECARD_DEP_LIMIT} of ${#deps[@]} dependencies. Set SCORECARD_DEP_LIMIT to check more."
  fi
}

scan_go_project() {
  log_section "Go Project Analysis"

  local deps=()

  if check_command govulncheck; then
    log_subsection "govulncheck (official Go vulnerability database)"
    log_info "Running: govulncheck ./..."
    if ! govulncheck ./... 2>&1; then
      ((VULNS_FOUND++)) || true
    else
      log_ok "No vulnerabilities found"
    fi
  fi

  if check_command osv-scanner; then
    log_subsection "OSV Scanner"
    if [[ -f "go.sum" ]]; then
      log_info "Running: osv-scanner --lockfile=go.sum"
      if ! osv-scanner --lockfile=go.sum 2>&1; then
        ((VULNS_FOUND++)) || true
      else
        log_ok "No vulnerabilities found in OSV database"
      fi
    else
      log_warn "go.sum not found - run 'go mod tidy' first"
    fi
  fi

  if check_command go && check_command jq; then
    mapfile -t deps < <(go list -m -json all 2>/dev/null | jq -r 'select(.Main != true) | .Path' | grep github.com || true)
  fi

  if [[ ${#deps[@]} -gt 0 ]]; then
    run_scorecard_on_deps "${deps[@]}"
  fi

  log_subsection "Supply Chain Checks"
  if grep -q "^replace" go.mod 2>/dev/null; then
    log_warn "Found 'replace' directives in go.mod - verify these are intentional:"
    grep "^replace" go.mod | head -5
    ((WARNINGS_FOUND++)) || true
  else
    log_ok "No replace directives found"
  fi

  if go list -m -retracted all 2>/dev/null | grep -v "^$" | head -5 | grep -q .; then
    log_warn "Some dependencies have retracted versions available:"
    go list -m -retracted all 2>/dev/null | grep -v "^$" | head -5
    ((WARNINGS_FOUND++)) || true
  fi
}

scan_rust_project() {
  log_section "Rust Project Analysis"

  local deps=()

  if check_command cargo-audit || check_command cargo; then
    log_subsection "cargo-audit (RustSec advisory database)"
    log_info "Running: cargo audit"
    if ! cargo audit 2>&1; then
      ((VULNS_FOUND++)) || true
    else
      log_ok "No vulnerabilities found"
    fi
  fi

  if command -v cargo-deny &>/dev/null || cargo deny --version &>/dev/null 2>&1; then
    log_subsection "cargo-deny (license, ban, and source checks)"

    if [[ -f "deny.toml" ]]; then
      log_info "Running: cargo deny check"
      if ! cargo deny check 2>&1; then
        ((VULNS_FOUND++)) || true
      else
        log_ok "All cargo-deny checks passed"
      fi
    else
      log_info "No deny.toml found - running with defaults"
      log_info "Running: cargo deny check advisories"
      cargo deny check advisories 2>&1 || ((VULNS_FOUND++)) || true
    fi
  fi

  if check_command osv-scanner; then
    log_subsection "OSV Scanner"
    if [[ -f "Cargo.lock" ]]; then
      log_info "Running: osv-scanner --lockfile=Cargo.lock"
      if ! osv-scanner --lockfile=Cargo.lock 2>&1; then
        ((VULNS_FOUND++)) || true
      else
        log_ok "No vulnerabilities found in OSV database"
      fi
    else
      log_warn "Cargo.lock not found - run 'cargo generate-lockfile' first"
    fi
  fi

  if check_command cargo && check_command jq; then
    mapfile -t deps < <(cargo metadata --format-version 1 2>/dev/null |
      jq -r '.packages[] | select(.source != null) | .repository // empty' |
      grep github.com | sort -u || true)
  fi

  if [[ ${#deps[@]} -gt 0 ]]; then
    run_scorecard_on_deps "${deps[@]}"
  fi

  log_subsection "Supply Chain Checks"
  if grep -q '\[dependencies\.' Cargo.toml 2>/dev/null && grep -A5 '\[dependencies' Cargo.toml | grep -q "git\s*="; then
    log_warn "Found git dependencies in Cargo.toml - verify these are intentional:"
    grep -B1 "git\s*=" Cargo.toml | head -10
    ((WARNINGS_FOUND++)) || true
  else
    log_ok "No git dependencies found"
  fi

  if grep -q 'path\s*=' Cargo.toml 2>/dev/null; then
    log_info "Found path dependencies (normal for workspaces):"
    grep 'path\s*=' Cargo.toml | head -5
  fi
}

scan_node_project() {
  log_section "Node.js Project Analysis"

  if check_command socket; then
    log_subsection "Socket.dev Security Scan"
    log_info "Running: socket scan create . --dry-run"
    if socket scan create . --dry-run 2>&1; then
      log_ok "Socket scan completed"
    else
      log_info "Running: socket npm audit"
      socket npm audit 2>&1 || ((VULNS_FOUND++)) || true
    fi
  elif check_command npm; then
    log_subsection "npm audit"
    log_info "Running: npm audit"
    if ! npm audit 2>&1; then
      ((VULNS_FOUND++)) || true
    else
      log_ok "No vulnerabilities found"
    fi
  fi

  if check_command osv-scanner; then
    log_subsection "OSV Scanner"
    if [[ -f "package-lock.json" ]]; then
      log_info "Running: osv-scanner --lockfile=package-lock.json"
      if ! osv-scanner --lockfile=package-lock.json 2>&1; then
        ((VULNS_FOUND++)) || true
      fi
    elif [[ -f "yarn.lock" ]]; then
      log_info "Running: osv-scanner --lockfile=yarn.lock"
      if ! osv-scanner --lockfile=yarn.lock 2>&1; then
        ((VULNS_FOUND++)) || true
      fi
    elif [[ -f "pnpm-lock.yaml" ]]; then
      log_info "Running: osv-scanner --lockfile=pnpm-lock.yaml"
      if ! osv-scanner --lockfile=pnpm-lock.yaml 2>&1; then
        ((VULNS_FOUND++)) || true
      fi
    fi
  fi

  if ! check_command socket && check_command guarddog && [[ -f "package.json" ]]; then
    log_subsection "GuardDog (malicious package detection)"
    log_info "Running: guarddog npm verify package.json"
    guarddog npm verify package.json 2>&1 || ((VULNS_FOUND++)) || true
  fi
}

print_summary() {
  log_section "Summary"

  if [[ ${VULNS_FOUND} -gt 0 ]]; then
    log_error "Vulnerabilities found: ${VULNS_FOUND}"
  else
    log_ok "No vulnerabilities found"
  fi

  if [[ ${WARNINGS_FOUND} -gt 0 ]]; then
    log_warn "Warnings: ${WARNINGS_FOUND}"
  fi

  echo ""
  if [[ ${VULNS_FOUND} -gt 0 || ${WARNINGS_FOUND} -gt 0 ]]; then
    log_info "Review the issues above before deploying"
    return 1
  else
    log_ok "All checks passed"
    return 0
  fi
}

print_tool_status() {
  log_section "Tool Status"

  local tools=(
    "scorecard:OpenSSF Scorecard"
    "osv-scanner:OSV Scanner"
    "govulncheck:Go Vulncheck"
    "cargo-audit:Cargo Audit"
    "cargo-deny:Cargo Deny"
    "guarddog:GuardDog"
    "socket:Socket CLI"
  )

  for tool_info in "${tools[@]}"; do
    IFS=':' read -r cmd name <<<"${tool_info}"
    if command -v "${cmd}" &>/dev/null; then
      echo -e "  ${GREEN}✓${NC} ${name}"
    else
      echo -e "  ${YELLOW}○${NC} ${name}"
    fi
  done
}

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] [project-directory]

Scan project dependencies for vulnerabilities and security issues.

Arguments:
  project-directory    Path to project (default: current directory)

Options:
  -h, --help          Show this help message
  -v, --verbose       Verbose output
  --status            Show tool installation status
  --skip-scorecard    Skip Scorecard checks (faster)

Environment Variables:
  GITHUB_TOKEN          GitHub token for API access (avoids rate limiting)
  SCORECARD_DEP_LIMIT   Max dependencies to run Scorecard on (default: 5)
  SCORECARD_THRESHOLD   Minimum acceptable Scorecard score (default: 5)
  SKIP_SCORECARD        Skip Scorecard checks if 'true'
  VERBOSE               Enable verbose output if 'true'

Examples:
  $(basename "$0")                    # Scan current directory
  $(basename "$0") ~/projects/myapp   # Scan specific project
  $(basename "$0") --skip-scorecard   # Fast scan without Scorecard
EOF
  exit 0
}

main() {
  local project_dir="."

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
      usage
      ;;
    -v | --verbose)
      VERBOSE=true
      shift
      ;;
    --status)
      print_tool_status
      exit 0
      ;;
    --skip-scorecard)
      SKIP_SCORECARD=true
      shift
      ;;
    -*)
      log_error "Unknown option: $1"
      usage
      ;;
    *)
      project_dir="$1"
      shift
      ;;
    esac
  done

  if [[ ! -d ${project_dir} ]]; then
    log_error "Directory not found: ${project_dir}"
    exit 1
  fi

  cd "${project_dir}"

  echo -e "${CYAN}╔════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}          Dependency Security Scan: $(basename "$(pwd)")          ${CYAN}║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
  log_info "Scanning: $(pwd)"

  local project_found=false

  if [[ -f "go.mod" ]]; then
    project_found=true
    scan_go_project
  fi

  if [[ -f "Cargo.toml" ]]; then
    project_found=true
    scan_rust_project
  fi

  if [[ -f "package.json" ]]; then
    project_found=true
    scan_node_project
  fi

  if [[ ${project_found} == "false" ]]; then
    log_error "No supported project files found (go.mod, Cargo.toml, package.json)"
    log_info "Supported project types: Go, Rust, Node.js"
    exit 1
  fi

  print_summary
}

main "$@"
