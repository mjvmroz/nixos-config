{ lib, ... }:

# What kind of machine this is, kept separate from which machine it is. Two work
# laptops share a set of concessions to a managed environment; saying so once
# here beats copying the same overrides into every host file.

{
  imports = [
    ./work.nix
    ./personal.nix
    ./kandji.nix
  ];

  options.mroz.machine = {
    profile = lib.mkOption {
      type = lib.types.enum [
        "work"
        "personal"
      ];
      description = ''
        Whose machine this is. Selects the default app bundles and, for work
        machines, the workarounds their managed environment needs.
      '';
      example = "work";
    };

    mdm = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "kandji" ]);
      default = null;
      description = ''
        Which MDM agent, if any, also manages this machine. Some of them insist
        on owning things nix-darwin would otherwise manage.
      '';
    };
  };
}
