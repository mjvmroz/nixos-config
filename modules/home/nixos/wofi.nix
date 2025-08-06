{
  config,
  spaghetti,
  ...
}:
{
  programs.wofi = {
    enable = true;
    settings = {
      width = 500;
      height = 300;
      always_parse_args = true;
      show_all = false;
      print_command = true;
      insensitive = true;
    };
  };
  #
  home.file.".config/hypr/per-app/wofi.conf" = {
    text = ''
      bind = ALT, SPACE, exec, wofi --show run
    '';
  };
  stylix.targets.wofi.enable = true;
}
