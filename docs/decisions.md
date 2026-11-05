# Configuration decisions

- Mise is the primary bootstrap, dotfile, task and developer-tool manager.
- Exact runtime/CLI versions belong in the config and lock, not duplicated
  operational inventories in public documentation.
- Public configuration and the private, non-secret overlay have separate roles.
  Credentials, login state, histories and sessions belong in neither repository.
- Pi Harness remains independent and owns its payloads and integration assets.
- Project environments select their own dependencies and runtimes without
  changing the shared workstation environment.
- Homebrew supplies native dependencies, services and GUI apps through mise
  bootstrap declarations. Installing a service does not authorize starting it.
- Neovim and VS Code are managed editors. Ghostty, Herdr and tmux remain
  available; Rex is an experimental, opt-in workflow rather than their removal.
- Public SSH/Rex examples use generic targets. Real mappings, host identifiers
  and operational acceptance notes stay private.
- Legacy runtime removal, application resets, database migration and restarts
  are separate reviewed operations, not side effects of configuration validation.
- Security exceptions are scoped; they do not silently weaken the general
  release-age, dependency-integrity or quarantine policies.
