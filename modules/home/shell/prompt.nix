{ config, lib, ... }:

# Starship, driven entirely off the palette Stylix installs for it. Stylix's
# starship target sets `palette = "base16"` and binds every base16 slot plus the
# usual colour names, so every style below is really Tokyo Night Storm Pastel
# and follows any change to modules/shared/theme.nix.
let
  cfg = config.home.mroz.shell;
in
{
  config = lib.mkIf cfg.enable {
    programs.starship = {
      enable = true;
      enableZshIntegration = true;

      settings = {
        add_newline = true;

        # Starship only evaluates modules that appear in a format string, so
        # spelling these out is both the layout and the opt-out list: no Python,
        # Go, Java, Kubernetes or cloud probes running on every prompt.
        format = lib.concatStrings [
          "$username"
          "$hostname"
          "$directory"
          "$git_branch"
          "$git_state"
          "$git_status"
          "$nix_shell"
          "$direnv"
          "$haskell"
          "$bun"
          "$nodejs"
          "$rust"
          "$line_break"
          "$jobs"
          "$status"
          "$character"
        ];

        # Rendered as zsh's RPROMPT, which means zsh drops it automatically when
        # the command line grows long enough to collide.
        right_format = lib.concatStrings [
          "$cmd_duration"
          "$time"
        ];

        continuation_prompt = "[∙](base03) ";

        # Kept from the previous config: cabal and ghc probes inside a cold nix
        # shell can take a very long time, and a timeout warning mid-build is
        # worse than a slow prompt.
        command_timeout = 600000;

        # Only interesting over SSH, where knowing which box you are on matters.
        username = {
          show_always = false;
          style_user = "bold yellow";
          style_root = "bold red";
          format = "[$user]($style)@";
        };

        hostname = {
          ssh_only = true;
          ssh_symbol = " ";
          style = "bold yellow";
          format = "[$ssh_symbol$hostname]($style) ";
        };

        directory = {
          style = "bold blue";
          repo_root_style = "bold bright-blue";
          before_repo_root_style = "base04";
          truncation_length = 4;
          truncation_symbol = "…/";
          truncate_to_repo = true;
          read_only = "󰌾 ";
          read_only_style = "red";
        };

        git_branch = {
          symbol = " ";
          style = "bold magenta";
          format = "[$symbol$branch]($style) ";
          truncation_length = 32;
          truncation_symbol = "…";
        };

        # Loud on purpose: with stacked branches it is easy to forget a rebase
        # is half-finished.
        git_state = {
          style = "bold yellow";
          format = "\\([$state( $progress_current/$progress_total)]($style)\\) ";
          rebase = "REBASING";
          merge = "MERGING";
          revert = "REVERTING";
          cherry_pick = "PICKING";
          bisect = "BISECTING";
          am = "AM";
          am_or_rebase = "AM/REBASE";
        };

        git_status = {
          style = "bold red";
          format = "([$all_status$ahead_behind]($style) )";
          conflicted = "=$count";
          ahead = "⇡$count";
          behind = "⇣$count";
          diverged = "⇕⇡$ahead_count⇣$behind_count";
          up_to_date = "";
          untracked = "?$count";
          stashed = "≡$count";
          modified = "!$count";
          staged = "+$count";
          renamed = "»$count";
          deleted = "✘$count";
        };

        # Just the snowflake. Which kind of nix shell it is has never been the
        # useful bit; whether one is active is.
        nix_shell = {
          symbol = "❄";
          style = "bold cyan";
          format = "[$symbol$state]($style)";
          heuristic = true;
          impure_msg = "";
          pure_msg = "";
          unknown_msg = "";
        };

        # Silent when the environment is loaded, noisy when it needs allowing,
        # which is the only time this is worth prompt real estate.
        direnv = {
          disabled = false;
          symbol = " ";
          style = "bold base0F";
          format = "[$symbol$allowed]($style)";
          allowed_msg = "";
          not_allowed_msg = "needs allow";
          denied_msg = "denied";
        };

        haskell = {
          symbol = " ";
          style = "bold magenta";
          format = "[$symbol($version )]($style)";
        };

        bun = {
          symbol = " ";
          style = "bold base06";
          format = "[$symbol($version )]($style)";
        };

        nodejs = {
          symbol = " ";
          style = "bold green";
          format = "[$symbol($version )]($style)";
        };

        rust = {
          symbol = "󱘗 ";
          style = "bold orange";
          format = "[$symbol($version )]($style)";
        };

        jobs = {
          symbol = " ";
          style = "bold blue";
          number_threshold = 1;
          format = "[$symbol$number]($style) ";
        };

        status = {
          disabled = false;
          symbol = "✘";
          style = "bold red";
          format = "[$symbol$status]($style) ";
          # The mapped symbols are emoji, which sit badly next to a nerd-font
          # prompt; the raw exit code carries the same information.
          map_symbol = false;
          pipestatus = true;
        };

        character = {
          success_symbol = "[λ](bold green)";
          error_symbol = "[λ](bold red)";
          vimcmd_symbol = "[λ](bold yellow)";
        };

        cmd_duration = {
          min_time = 2000;
          style = "yellow";
          format = "[ $duration]($style) ";
        };

        time = {
          disabled = false;
          time_format = "%H:%M";
          style = "base03";
          format = "[$time]($style)";
        };
      };
    };
  };
}
