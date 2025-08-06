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

### For NixOS

```sh
./switch.sh # I think it's that easy??
```

## Manage secrets (not used rn, might drop)

To create a new secret `secret.age`, first [create a `secrets.nix` file](https://github.com/ryantm/agenix#tutorial) at the root of your [`nix-secrets`](https://github.com/dustinlyons/nix-secrets-example) repository. Use this code:

> [!NOTE] > `secrets.nix` is interpreted by the imperative `agenix` commands to pick the "right" keys for your secrets.
>
> Think of this file as the config file for `agenix`. It's not part of your system configuration.

**secrets.nix**

```nix
let
  user1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL0idNvgGiucWgup/mP78zyC23uFjYq0evcWdjGQUaBH";
  users = [ user1 ];

  system1 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPJDyIr/FSz1cJdcoW69R+NrWzwGK/+3gJpqD1t8L2zE";
  systems = [ system1 ];
in
{
  "secret.age".publicKeys = [ user1 system1 ];
}
```

Values for `user1` should be your public key, or if you prefer to have keys attached to hosts, use the `system1` declaration.

Now that we've configured `agenix` with our `secrets.nix`, it's time to create our first secret.

Run the command below.

```
EDITOR=vim nix run github:ryantm/agenix -- -e secret.age
```

This opens an editor to accept, encrypt, and write your secret to disk.

The command will look up the public key for `secret.age`, defined in your `secrets.nix`, and check for its private key in `~/.ssh/.`

> To override the SSH path, provide the `-i` flag with a path to your `id_ed25519` key.

Write your secret in the editor, save, and commit the file to your [`nix-secrets`](https://github.com/dustinlyons/nix-secrets-example) repo.

Now we have two files: `secrets.nix` and our `secret.age`.
