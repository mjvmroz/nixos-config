# My environment

This repository contains my personal environment: a consistent zsh-based shell across systems, and a handful of general purpose applications. It is working on both macOS and NixOS, but the macOS configuration is more complete; my NixOS machine is primarily for gaming.

There is currently no secret management (though I still have Age floating around as a dependency; I may move my identity information to a private repo): I use 1Password as an agent for GPG/SSH, so I install for the first time on a new system by pulling via Git HTTPS, authenticate to 1Password with the streamlined QR flow and enable the SSH agent to complete the install.

## Layout

```
.
├── hosts     # Host-specific configuration
├── modules   # macOS and nix-darwin, NixOS, and shared configuration
├── overlays  # Automatically applied overlays
```

## Installing

### For NixOS

```sh
sudo nixos-rebuild switch --flake .
```

### For macOS

This configuration supports both Intel and Apple Silicon Macs.

Let Apple know that we'd like to use the computer:

```sh
xcode-select --install
```

And then install Nix. I mostly use the Determinate Systems distribution:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Finally, cut over to the new Nix:

```sh
# First time:
sudo nix run nix-darwin -- switch --flake .

# Subsequent times:
sudo nix-darwin switch --flake .
```

#### Manual steps:

**All systems:**

- **1Password**: Preferences > Developer > Use the SSH Agent

**macOS only:**

- **Ghostty** is the primary terminal and is fully declarative: the app comes from the
  Homebrew cask and its config from `modules/home/shell/ghostty.nix`, so there is nothing
  to do by hand. The quick terminal (cmd-`) needs Accessibility permission the first time
  it is triggered.
- **iTerm2** is kept only as a fallback and is no longer themed. If you want to use it,
  Preferences > General > Preferences > Load preferences from a custom folder or URL:
  - `~/.config/nix-iterm2` (read-only via nix), or
  - `${thisProject}/modules/darwin/config/nix-iterm` (read-write via git, not controlled by nix)

## Updating

Update Nix flakes with `nix flake update`, then install to apply changes.

Rebuilds can go through `nh`, which wraps `darwin-rebuild` with nix-output-monitor and
prints a diff of what changed between generations. `NH_FLAKE` is already set, so
`nh darwin switch` works from any directory.

On macOS, software managed through brew (mostly casks for graphical apps) should get the latest version on install. I have mutable brew management disabled.
