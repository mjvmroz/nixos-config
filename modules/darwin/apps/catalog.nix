_:

# Every app declared once. Bundles say who wants it by default; hosts override
# individual entries. Apps in no bundle are deliberately parked: they are kept
# here so the reason they aren't installed doesn't get lost.

{
  mroz.apps = {
    ##### Development tools

    ghostty = {
      displayName = "Ghostty";
      cask = "ghostty"; # Configured by modules/home/shell/ghostty.nix
      bundles = [ "core" ];
      dock = {
        enable = true;
        order = 20;
      };
    };

    iterm2 = {
      cask = "iterm2"; # Fallback terminal emulator
      bundles = [ "core" ];
    };

    visual-studio-code = {
      displayName = "Visual Studio Code";
      cask = "visual-studio-code";
      bundles = [ "dev" ];
      dock = {
        enable = true;
        order = 40;
      };
    };

    cursor = {
      cask = "cursor"; # Code editor with advanced AI features
      bundles = [ "dev" ];
    };

    zed = {
      cask = "zed";
      bundles = [ "dev" ];
    };

    texstudio = {
      cask = "texstudio"; # LaTeX editor
      bundles = [ "dev" ];
    };

    # Parked: needs a neovim version fix, and it took over my default apps.
    neovide = {
      cask = "neovide";
      bundles = [ ];
    };

    # Parked in favour of texstudio.
    texifier = {
      cask = "texifier";
      bundles = [ ];
    };

    postico = {
      cask = "postico"; # Global DB client
      bundles = [ "dev" ];
    };

    blender = {
      cask = "blender"; # 3D modelling
      bundles = [ "personal" ];
    };

    k3d = {
      brew = "k3d";
      bundles = [ "dev" ];
    };

    kubectl = {
      brew = "kubectl";
      bundles = [ "dev" ];
    };

    gh = {
      brew = "gh";
      bundles = [ "core" ];
    };

    ##### Communication

    slack = {
      cask = "slack";
      bundles = [ "core" ];
    };

    zoom = {
      cask = "zoom";
      bundles = [ "work" ];
    };

    messages = {
      displayName = "Messages";
      # Ships with macOS, so there is nothing to install; this entry exists
      # purely to keep it off the Dock on work machines.
      bundles = [ "personal" ];
      dock = {
        enable = true;
        order = 15;
        path = "/System/Applications/Messages.app";
      };
    };

    discord = {
      cask = "discord";
      bundles = [ ];
    };

    notion = {
      cask = "notion";
      bundles = [ ];
    };

    ##### Utilities

    "1password" = {
      displayName = "1Password";
      cask = "1password";
      bundles = [ "core" ];
      dock = {
        enable = true;
        order = 30;
      };
    };

    "1password-cli" = {
      cask = "1password-cli"; # Terminal integration for 1Password
      bundles = [ "core" ];
    };

    chatgpt = {
      displayName = "ChatGPT";
      cask = "chatgpt";
      bundles = [ "core" ];
      dock = {
        enable = true;
        order = 60;
      };
    };

    linearmouse = {
      cask = "linearmouse"; # Mouse acceleration fix
      bundles = [ "core" ];
    };

    raycast = {
      cask = "raycast"; # Spotlight alternative
      bundles = [ "core" ];
    };

    magnet = {
      displayName = "Magnet";
      masId = 441258766; # Window tiling
      bundles = [ "core" ];
    };

    apple-configurator = {
      displayName = "Apple Configurator";
      masId = 1037126344;
      bundles = [ "core" ];
    };

    ##### Browsers

    google-chrome = {
      cask = "google-chrome"; # Evil. I should switch to Firefox. But hassle.
      bundles = [ "core" ];
    };

    "firefox@developer-edition" = {
      displayName = "Firefox Developer Edition";
      cask = "firefox@developer-edition";
      bundles = [ "core" ];
      dock = {
        enable = true;
        order = 10;
      };
    };

    ##### Entertainment

    spotify = {
      displayName = "Spotify";
      cask = "spotify";
      bundles = [ "media" ];
      dock = {
        enable = true;
        order = 50;
      };
    };

    # Parked: "Cask 'iina' definition is invalid: Only a single 'depends_on
    # macos' is allowed."
    iina = {
      cask = "iina"; # Video player
      bundles = [ ];
    };
  };
}
