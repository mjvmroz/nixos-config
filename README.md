# My environment

Based on [dustinlyons/nix-config](https://github.com/dustinlyons/nixos-config), this repository contains my personal environment.

It's currently only tested on macOS, but it should mostly work on NixOS. I'm moving toward 1Password as an agent for GPG/SSH, but haven't yet fully implemented that for NixOS.

## Layout

```
.
├── apps         # Nix commands used to bootstrap and build configuration
├── hosts        # Host-specific configuration
├── modules      # macOS and nix-darwin, NixOS, and shared configuration
├── overlays     # Drop an overlay file in this dir, and it runs. So far, mainly patches.
├── templates    # Starter versions of this configuration
```

## Installing

### For macOS

This configuration supports both Intel and Apple Silicon Macs.

Let Apple know that we'd like to use the computer:

```sh
xcode-select --install
```

And then install Nix. I use the Determinate Systems distribution:

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

Finally, cut over to the new Nix:

```sh
./switch.sh
```

#### Manual steps:

- **iTerm2**: Preferences -> General -> Preferences -> Load preferences from a custom folder or URL:
  - `~/.config/nix-iterm2` (read-only via nix), or
  - `${thisProject}/modules/darwin/config/nix-iterm` (read-write via git, not controlled by nix)
- **1Password**: Preferences -> Developer -> Use the SSH Agent

### For NixOS

```sh
./switch.sh # I think it's that easy??
```
