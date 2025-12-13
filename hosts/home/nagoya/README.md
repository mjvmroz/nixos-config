## `nagoya` (Fedora) — standalone Home Manager

This host is **not NixOS**. It assumes Fedora manages:

- NVIDIA driver + CUDA stack (for best compatibility/performance)
- GNOME + desktop apps

Nix/Home Manager manages:

- Shell + CLI tooling
- Dotfiles / GNOME preferences (via `dconf`)
- Reproducible project environments (via `devShells`)

### Bootstrap

- Install Nix (recommended: Determinate Nix).
- Enable flakes (`nix-command` + `flakes`).

### Apply the Home Manager config

From the repo root:

```bash
nix run github:nix-community/home-manager -- switch --flake .#nagoya
```

### 1Password (installed via Nix)

This config installs:

- `1password` GUI (`_1password-gui`)
- `op` CLI (`_1password-cli`)

Your shell config expects the 1Password SSH agent socket at `~/.1password/agent.sock`.

### CUDA shells

This repo intentionally **does not** provide a global CUDA devShell.

Keep CUDA toolchains **per project** (in that project’s flake/dev environment) so you can pin versions and avoid accidental mixing across workloads.
