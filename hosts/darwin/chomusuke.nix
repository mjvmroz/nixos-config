_:

# Previous work laptop. Everything a managed machine needs lives in the work
# profile; nothing here is specific to this one.

{
  imports = [ ../../modules/darwin/lix.nix ];

  networking.hostName = "chomusuke";
  mroz.machine.profile = "work";
}
