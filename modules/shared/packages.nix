{ pkgs }:

with pkgs;
[
  # System packages
  tailscale # Private VPN

  # Nix
  nixfmt-rfc-style # Opinionated Nix style
  nil # Nix language server

  # Languages
  rustup # Rust programming language

  # General packages for development and system management
  alacritty # Terminal emulator
  silver-searcher # Nice search tool
  aspell # Spell checker
  aspellDicts.en # English dictionary
  bash-completion # Better bash completion
  bat # Nice cat replacement
  btop # Better top
  coreutils # GNU core utilities
  killall # Kill processes by name
  neofetch # System info
  openssh # Secure shell
  sqlite # Single-threaded file-based database
  wget # Download files
  httpie # HTTP client
  zip # Compress files
  graphite-cli # Graphite (friendly git stacking) command line interface

  # Encryption and security tools
  age
  age-plugin-yubikey
  gnupg
  libfido2

  # Cloud-related tools and SDKs
  docker # Containerization
  docker-compose # Docker orchestration

  # Media-related packages
  dejavu_fonts
  ffmpeg # Video and audio processing
  fd # Better find
  font-awesome # Icon font
  hack-font
  noto-fonts
  noto-fonts-emoji
  meslo-lgs-nf

  # Node.js development tools
  # nodePackages.npm # globally install npm
  # nodePackages.prettier
  # nodejs

  # Text and terminal utilities
  xsv # CSV toolkit
  hunspell
  iftop
  # jetbrains-mono
  jq
  # tree
  tmux
  # unrar
  # unzip
]
