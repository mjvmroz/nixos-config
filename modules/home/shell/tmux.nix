{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.home.mroz.shell;
  colors = config.lib.stylix.colors.withHashtag;

  # Powerline separators. Present in Hasklug Nerd Font, which Stylix sets as the
  # monospace font everywhere.
  sepRight = "";
  sepLeft = "";

  # sesh unifies live tmux sessions and zoxide's directory history behind one
  # picker, so this jumps to a project whether or not it already has a session.
  # Written out as a script because tmux config lines cannot span newlines.
  seshPicker = pkgs.writeShellScript "sesh-picker" ''
    session=$(
      ${lib.getExe pkgs.sesh} list --icons | ${pkgs.fzf}/bin/fzf-tmux -p 80%,60% \
        --no-sort --ansi --border-label ' sessions ' --prompt '⚡ ' \
        --header '^a all · ^t tmux · ^g config · ^x zoxide · ^d kill' \
        --bind 'tab:down,btab:up' \
        --bind 'ctrl-a:change-prompt(⚡ )+reload(${lib.getExe pkgs.sesh} list --icons)' \
        --bind 'ctrl-t:change-prompt(t )+reload(${lib.getExe pkgs.sesh} list -t --icons)' \
        --bind 'ctrl-g:change-prompt(g )+reload(${lib.getExe pkgs.sesh} list -c --icons)' \
        --bind 'ctrl-x:change-prompt(z )+reload(${lib.getExe pkgs.sesh} list -z --icons)' \
        --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡ )+reload(${lib.getExe pkgs.sesh} list --icons)'
    ) || exit 0
    [ -n "$session" ] || exit 0
    exec ${lib.getExe pkgs.sesh} connect "$session"
  '';
in
{
  config = lib.mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      plugins = with pkgs.tmuxPlugins; [
        vim-tmux-navigator
        sensible
        yank
        prefix-highlight
        {
          plugin = resurrect; # Used by tmux-continuum

          # Use XDG data directory
          # https://github.com/tmux-plugins/tmux-resurrect/issues/348
          extraConfig = ''
            set -g @resurrect-dir '$HOME/.cache/tmux/resurrect'
            set -g @resurrect-capture-pane-contents 'on'
            set -g @resurrect-pane-contents-area 'visible'
          '';
        }
        {
          plugin = continuum;
          extraConfig = ''
            set -g @continuum-restore 'on'
            set -g @continuum-save-interval '5' # minutes
          '';
        }
      ];

      # screen-256color has no italics entry and understates what tmux can do;
      # tmux-256color is the terminfo tmux actually ships for.
      terminal = "tmux-256color";
      prefix = "C-x";
      escapeTime = 10;
      historyLimit = 50000;
      baseIndex = 1;
      # The copy-mode-vi bindings below were already written for this, but
      # mode-keys defaulted to emacs, so none of them were reachable.
      keyMode = "vi";
      mouse = true;

      # mkAfter so the status bar below lands after the base16 colour file that
      # Stylix's tmux target sources into this same option.
      extraConfig = lib.mkAfter ''
        # Stylix emits 24-bit hex colours; without this tmux quantises them
        # down to the 256-colour cube and the pastels go muddy.
        set -ga terminal-features ",*:RGB"

        # Remove Vim mode delays
        set -g focus-events on

        setw -g pane-base-index 1
        set -g renumber-windows on
        set -g set-titles on
        set -g set-titles-string "#S · #W"

        # -----------------------------------------------------------------------------
        # Key bindings
        # -----------------------------------------------------------------------------

        # Unbind default keys
        unbind C-b
        unbind '"'
        unbind %

        # Split panes, vertical or horizontal, inheriting the current directory
        bind-key x split-window -v -c "#{pane_current_path}"
        bind-key v split-window -h -c "#{pane_current_path}"

        # Move around panes with vim-like bindings (h,j,k,l)
        bind-key -n M-k select-pane -U
        bind-key -n M-h select-pane -L
        bind-key -n M-j select-pane -D
        bind-key -n M-l select-pane -R

        # Smart pane switching with awareness of Vim splits.
        # This is copy paste from https://github.com/christoomey/vim-tmux-navigator
        is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|n?vim?x?)(diff)?$'"
        bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
        bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
        bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
        bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
        tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
        if-shell -b '[ "$(echo "$tmux_version < 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\'  'select-pane -l'"
        if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
          "bind-key -n 'C-\\' if-shell \"$is_vim\" 'send-keys C-\\\\'  'select-pane -l'"

        bind-key -T copy-mode-vi 'C-h' select-pane -L
        bind-key -T copy-mode-vi 'C-j' select-pane -D
        bind-key -T copy-mode-vi 'C-k' select-pane -U
        bind-key -T copy-mode-vi 'C-l' select-pane -R
        bind-key -T copy-mode-vi 'C-\' select-pane -l
        bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
        bind-key -T copy-mode-vi 'C-v' send-keys -X rectangle-toggle

        # Reload without leaving the session
        bind-key R source-file "${config.xdg.configHome}/tmux/tmux.conf" \; display-message "tmux.conf reloaded"

        # Session/project picker, replacing the default choose-tree on `s`
        bind-key s run-shell "${seshPicker}"

        # -----------------------------------------------------------------------------
        # Status bar
        # -----------------------------------------------------------------------------

        set -g status-position bottom
        set -g status-interval 5
        set -g status-justify left
        set -g status-left-length 48
        set -g status-right-length 96
        set -g status-style "bg=${colors.base01},fg=${colors.base04}"

        set -g status-left "#[fg=${colors.base00},bg=${colors.base0D},bold] #S #[fg=${colors.base0D},bg=${colors.base01},nobold]${sepRight}"
        set -g status-right "#{prefix_highlight}#[fg=${colors.base02},bg=${colors.base01}]${sepLeft}#[fg=${colors.base04},bg=${colors.base02}] #{b:pane_current_path} #[fg=${colors.base0D},bg=${colors.base02}]${sepLeft}#[fg=${colors.base00},bg=${colors.base0D},bold] #h "

        setw -g window-status-separator ""
        setw -g window-status-format "#[fg=${colors.base04},bg=${colors.base01}]  #I ${sepLeft} #W  "
        setw -g window-status-current-format "#[fg=${colors.base01},bg=${colors.base02}]${sepRight}#[fg=${colors.base0C},bg=${colors.base02},bold] #I ${sepLeft} #W #[fg=${colors.base02},bg=${colors.base01},nobold]${sepRight}"
        setw -g window-status-activity-style "fg=${colors.base09},bg=${colors.base01}"

        set -g pane-border-style "fg=${colors.base02}"
        set -g pane-active-border-style "fg=${colors.base0D}"
        set -g message-style "bg=${colors.base0A},fg=${colors.base00}"
        set -g mode-style "bg=${colors.base02},fg=${colors.base06}"

        set -g @prefix_highlight_fg "${colors.base00}"
        set -g @prefix_highlight_bg "${colors.base0A}"
        set -g @prefix_highlight_prefix_prompt "PREFIX"
      '';
    };

    home.packages = [ pkgs.sesh ];
  };
}
