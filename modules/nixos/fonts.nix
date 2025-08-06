{ pkgs, ... }:
{
  fonts.packages = with pkgs.nerd-fonts; [
    hasklug
    jetbrains-mono
    fira-code
    fira-mono
    inconsolata
    sauce-code-pro
    comic-shanns-mono
  ];
}
