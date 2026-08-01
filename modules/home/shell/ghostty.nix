{
  config,
  lib,
  pkgs,
  ...
}:

# Ghostty is the primary terminal on every host. Colours, font and opacity all
# come from Stylix's ghostty target, so everything set here is behaviour.
let
  cfg = config.home.mroz.shell;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in
{
  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;

      # nixpkgs' ghostty is Linux-only; on macOS the app comes from the Homebrew
      # cask and home-manager only owns the config file. Null also turns off the
      # config validation hook and the bat syntax install, both of which need
      # the binary.
      package = if isDarwin then null else pkgs.ghostty;

      enableZshIntegration = true;

      settings = {
        window-padding-x = 12;
        window-padding-y = 8;
        window-padding-balance = true;
        window-inherit-working-directory = true;
        window-save-state = "always";

        cursor-style = "block";
        cursor-style-blink = false;
        mouse-hide-while-typing = true;
        copy-on-select = "clipboard";
        confirm-close-surface = false;

        # Dims whichever split is not focused, which is the cheapest way to make
        # a split layout readable at a glance.
        unfocused-split-opacity = 0.92;

        # zsh is the login shell everywhere, so skip the detection dance.
        shell-integration = "zsh";
        shell-integration-features = "cursor,sudo,title";
      }
      // lib.optionalAttrs isDarwin {
        # Without this the Option key emits macOS's composed characters and the
        # M-h/M-j/M-k/M-l pane bindings in tmux never arrive.
        macos-option-as-alt = true;
        macos-titlebar-style = "tabs";
        macos-non-native-fullscreen = "visible-menu";
        quit-after-last-window-closed = false;
        font-thicken = true;

        # Pairs with stylix.opacity.terminal; without blur the transparency
        # just reads as muddy text.
        background-blur = 20;

        # A drop-down terminal on the same key regardless of which app has
        # focus. Needs Accessibility permission the first time it is used.
        quick-terminal-position = "top";
        quick-terminal-screen = "mouse";
        quick-terminal-autohide = true;
        keybind = [
          # cmd+grave_accent is left to macOS so same-app window cycling keeps
          # working; the quick terminal takes the shifted variant instead.
          "global:cmd+shift+grave_accent=toggle_quick_terminal"
          "cmd+shift+enter=toggle_split_zoom"
        ];
      };
    };
  };
}
