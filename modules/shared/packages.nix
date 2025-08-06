{ pkgs }:

with pkgs;
[
  # Nix
  nixfmt-rfc-style # Opinionated Nix style
  nil # Nix language server
  devenv # Toolchain for project-specific development environments
  nix-output-monitor # Prettify builds with pipes
  cachix # Binary cache for Nix

  # Languages
  rustup # Rust programming language

  # Databases
  sqlite # Single-threaded file-based database
  pgcli # PostgreSQL command line interface

  # General packages for development and system management
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
  zip # Compress files
  graphite-cli # Graphite (friendly git stacking) command line interface
  nix-search-tv # Search for Nix packages

  # Network
  wget # Download files
  httpie # HTTP client
  trippy # Network diagnostics

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
  xan # CSV viewing, querying, joining, etc
  hunspell
  # jetbrains-mono
  jq
  # tree
  tmux
  # unrar
  # unzip
]
