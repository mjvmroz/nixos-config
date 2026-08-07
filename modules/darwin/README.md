# Darwin

macOS and nix-darwin configuration. Hosts pull this in via `hosts/darwin`, which
imports `apps`, `profiles`, `home-manager.nix` and `postgres.nix`; the rest is
reached from there.

## Layout

```
.
├── apps               # The app registry: every cask, brew and App Store app, declared once
│   ├── default.nix    # The mroz.apps option, rendered into homebrew and the dock
│   └── catalog.nix    # The apps themselves, each tagged with the bundles it belongs to
├── profiles           # What kind of machine this is, rather than which machine it is
│   ├── default.nix    # The mroz.machine.profile and mroz.machine.mdm options
│   ├── work.nix       # Bundles and concessions common to the managed work laptops
│   ├── personal.nix   # Bundles for the personal machines
│   └── kandji.nix     # Workarounds for what the Kandji agent insists on owning
├── config             # Config files not written in Nix, copied out by files.nix
├── files.nix          # Non-Nix, static configuration files (now immutable!)
├── home-manager.nix   # How apps get installed, and the user's home-manager config
├── lix.nix            # Runs Lix as the interpreter; imported per-host, not globally
├── packages.nix       # Nix packages for macOS, on top of the shared set
└── postgres.nix       # Local PostgreSQL
```
