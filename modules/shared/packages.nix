{ pkgs }:

with pkgs; [
  # System packages
  tailscale

  # Nix
  nixfmt-rfc-style
  nil # Nix language server

  # General packages for development and system management
  alacritty
  aspell
  aspellDicts.en
  bash-completion
  bat # Nice cat replacement
  btop # Better top
  coreutils
  killall
  neofetch
  openssh
  sqlite
  wget
  zip

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Cloud-related tools and SDKs
  docker
  docker-compose

  # Media-related packages
  dejavu_fonts
  ffmpeg
  fd
  font-awesome
  hack-font
  noto-fonts
  noto-fonts-emoji
  meslo-lgs-nf

  # Node.js development tools
  # nodePackages.npm # globally install npm
  # nodePackages.prettier
  # nodejs

  # Text and terminal utilities
  htop
  hunspell
  iftop
  # jetbrains-mono
  jq
  # tree
  tmux
  # unrar
  # unzip
]
