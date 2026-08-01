{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.home.mroz.shell;
  stateHome =
    if config ? xdg && config.xdg ? stateHome then
      config.xdg.stateHome
    else
      "${config.home.homeDirectory}/.local/state";
  # Stylix owns the vivid theme; bake the result at build time so interactive
  # shells read a file instead of forking vivid.
  vividTheme = config.xdg.configFile."vivid/themes/${config.programs.vivid.activeTheme}.yml".source;
  lsColors = pkgs.runCommand "ls-colors" { } ''
    ${lib.getExe pkgs.vivid} generate ${vividTheme} | tr -d '\n' > $out
  '';
  onePass =
    if pkgs.stdenv.hostPlatform.isLinux then
      {
        sshAgentSock = "~/.1password/agent.sock";
        gpgProgram = lib.getExe' pkgs._1password-gui "op-ssh-sign";
      }
    else if pkgs.stdenv.hostPlatform.isDarwin then
      {
        sshAgentSock = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
        gpgProgram = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
      }
    else
      throw "Unsupported platform for 1Password agent socket";
in
{

  options = {
    home.mroz.shell.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Michael Mroz's shell configuration.";
      example = true;
    };

    home.mroz.shell.identity.name = mkOption {
      type = types.str;
      description = "Git user name.";
      example = "Your Name";
    };

    home.mroz.shell.identity.gitEmail = mkOption {
      type = types.str;
      description = "Git user email.";
      example = "your@email.com";
    };

    home.mroz.shell.identity.signingKey = mkOption {
      type = types.str;
      description = "Git signing key.";
      example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJRQgKmvXGkbgTLFTCT0gtm6/fojgXcJhfcvNW2n6+WB";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      # Shared shell configuration
      zsh = {
        enable = true;
        dotDir = "${config.home.homeDirectory}/dotfiles";
        autocd = true;
        enableCompletion = true;
        syntaxHighlighting = {
          enable = true;
        };
        autosuggestion = {
          enable = true;
          strategy = [ "history" ];
        };
        plugins = [
          {
            name = "fzf-tab";
            src = pkgs.fetchFromGitHub {
              owner = "Aloxaf";
              repo = "fzf-tab";
              rev = "2abe1f2f1cbcb3d3c6b879d849d683de5688111f";
              sha256 = "zc9Sc1WQIbJ132hw73oiS1ExvxCRHagi6vMkCLd4ZhI=";
            };
          }
        ];

        shellAliases = {
          ll = "eza -l --git --icons --group-directories-first";
          la = "eza -la --git --icons --group-directories-first";
          gl = "git pull";
          gp = "git push";
          gco = "git checkout";
          top = "btop";
          # Thin wrappers over the git aliases defined in programs.git.settings.alias below.
          glg = "git lg";
          glgp = "git lgp";
          glgg = "git lgg";
          glgga = "git lgga";
          glgm = "git lgm";
          glo = "git lo";
          glol = "git lol";
          glola = "git lola";
          glog = "git lgo";
          gloga = "git lgoa";
          cf = "code $(fzf)";
          "c." = "cursor .";
          "co." = "code .";
          dr = "ndr-universal";
          da = "direnv allow";
          cb = "cabal build";
          cr = "cabal-reset";
          ns = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history"; # Search Nix packages with nix-search-tv
        };
        cdpath = [ "~/.local/share/src" ];
        # Cache the completion dump under XDG and skip the fpath security scan when
        # it is less than a day old; the scan is the bulk of zsh startup cost.
        completionInit = ''
          autoload -Uz compinit
          () {
            emulate -L zsh -o extended_glob
            local dump="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-''${ZSH_VERSION}"
            mkdir -p "''${dump:h}"
            if [[ -f $dump && -n $dump(#qN.md-1) ]]; then
              compinit -C -d $dump
            else
              compinit -d $dump
            fi
          }
        '';

        history = {
          size = 100000;
          save = 100000;
          expireDuplicatesFirst = true;
          ignoreSpace = true;
        };

        initContent =
          let
            earlyInit = ''
              if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
                . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
                . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
              fi

              # Define variables for directories
              export PATH=$HOME/.local/bin:$HOME/.local/share/bin:$PATH
            ''
            + lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
              # Docker Desktop for Mac installs its CLI tools here
              export PATH="$PATH:/Applications/Docker.app/Contents/Resources/bin/"
            ''
            + ''

              export LESS="-R -M -i -J -z-4 --mouse"

              # Generated by vivid at build time. Drives eza/ls output and, through
              # the list-colors zstyle below, the completion menu.
              export LS_COLORS="$(< ${lsColors})"

              # nix-direnv makes this warning a virtual certainty, and I know about ctrl-c
              export DIRENV_WARN_TIMEOUT=100000h

              # nix shortcuts
              shell() {
                nix-shell '<nixpkgs>' -A "$1"
              }

              expand_tilde() {
                tilde_less="''${1#\~/}"
                [ "$1" != "$tilde_less" ] && tilde_less="$HOME/$tilde_less"
                printf '%s' "$tilde_less"
              }

              port_info() {
                setopt pipefail
                lsof -i -P | grep LISTEN | grep :$1
              }

              port_pid() {
                setopt pipefail
                port_info $1 | awk '{print $2}'
              }

              port_kill() {
                setopt pipefail
                port_pid $1 | xargs kill
              }

              csvless () {
                column -s, -t < $1 | less -#2 -N -S
              }

              tree () {
                eza --tree --color=always $1 | less
              }

              ndr-universal() {
                if command -v nix-direnv-reload >/dev/null 2>&1; then
                  nix-direnv-reload "$@"
                else
                  direnv reload "$@"
                fi
              }

              # Hard-reset and rebuild the current project
              cabal-reset() {
                rm -rf dist-newstyle            # remove every cached artefact
                cabal clean -v0                 # wipe local component dirs
                cabal build  "$@"               # full recompilation
              }

              # Remove cache for the package dependencies given as arguments.
              # This is a targeted alternative to `cabal-reset`, and might be
              # flaky but might also save time in some extreme cases.
              # Usage: cabal-prune <package1> <package2> ...
              cabal-prune() {
                for pkg in "$@"; do
                  find dist-newstyle -type d -name "''${pkg}-*" -prune -exec rm -rf {} +
                done
              }

              export SSH_AUTH_SOCK=$(expand_tilde "${onePass.sshAgentSock}")
            '';

            # Ordered after atuin (1000) so these bindings win, but before
            # zsh-syntax-highlighting (1200), which has to see every custom widget.
            completionAndKeys = ''
              bindkey '^[[1;9D' beginning-of-line
              bindkey '^[[1;9C' end-of-line

              # Prefix-aware history on the arrows. Atuin runs with --disable-up-arrow
              # so it only owns ^R and leaves these to us.
              autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
              zle -N up-line-or-beginning-search
              zle -N down-line-or-beginning-search
              bindkey '^[[A' up-line-or-beginning-search
              bindkey '^[[B' down-line-or-beginning-search
              bindkey '^P' up-line-or-beginning-search
              bindkey '^N' down-line-or-beginning-search

              #####
              # Completion behaviour
              #####
              # Exact, then case-insensitive, then partial-word (f.b -> foo.bar), then substring.
              zstyle ':completion:*' matcher-list "" \
                'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' \
                'r:|[._-]=* r:|=*' \
                'l:|=* r:|=*'
              # Suppress zsh's own menu so fzf-tab can capture the unambiguous prefix.
              zstyle ':completion:*' menu no
              zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
              # NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
              zstyle ':completion:*:descriptions' format '[%d]'
              zstyle ':completion:*' group-name ""
              zstyle ':completion:*' squeeze-slashes true
              zstyle ':completion:*' special-dirs true
              zstyle ':completion:*' use-cache yes
              zstyle ':completion:*' cache-path "''${XDG_CACHE_HOME:-$HOME/.cache}/zsh/compcache"
              zstyle ':completion:*:git-checkout:*' sort false
              zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories

              #####
              # fzf-tab
              #####
              zstyle ':fzf-tab:*' use-fzf-default-opts yes
              zstyle ':fzf-tab:*' fzf-bindings 'tab:down' 'btab:up' 'ctrl-space:toggle'
              zstyle ':fzf-tab:*' switch-group '<' '>'
              zstyle ':fzf-tab:*' fzf-min-height 15
              zstyle ':fzf-tab:complete:*:*' fzf-preview '
                if [[ -d $realpath ]]; then
                  eza -1 --color=always --icons --group-directories-first -- $realpath
                elif [[ -f $realpath ]]; then
                  bat --color=always --style=numbers --line-range=:200 -- $realpath
                fi'
              zstyle ':fzf-tab:complete:git-(add|diff|restore|checkout|show):*' fzf-preview \
                'git diff --color=always $word'
            '';
          in
          lib.mkMerge [
            (lib.mkOrder 500 earlyInit)
            (lib.mkOrder 1180 completionAndKeys)
          ];
      };

      starship = {
        enable = true;
        enableZshIntegration = true;
        # Configuration written to ~/.config/starship.toml
        settings = {
          add_newline = true;

          character = {
            success_symbol = "[λ](bold green)"; # The 'success_symbol' segment is being set to '➜' with the color 'bold green'
            error_symbol = "[λ](bold red)";
          };

          command_timeout = 600000; # milliseconds (10 minutes)
        };
      };

      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv = {
          enable = true;
        };
      };

      atuin = {
        enable = true;
        enableZshIntegration = true;
        # Leave the arrow keys to zsh's own prefix search; atuin only owns ^R.
        flags = [ "--disable-up-arrow" ];
        daemon.enable = true;
        settings = {
          # Enter puts the command on the line to edit rather than running it outright.
          enter_accept = false;
          inline_height = 20;
          style = "compact";
          show_preview = true;
          filter_mode_shell_up_key_binding = "session";
          workspaces = true;
          secrets_filter = true;
          update_check = false;
        };
      };

      git = {
        enable = true;
        ignores = [ "*.swp" ];
        signing = {
          signByDefault = true;
          key = cfg.identity.signingKey;
          format = "ssh";
          signer = onePass.gpgProgram;
        };
        settings = {
          alias = {
            lg = "log --stat";
            lgp = "log --stat -p";
            lgg = "log --graph";
            lgga = "log --graph --decorate --all";
            lgm = "log --graph --max-count 10";
            lo = "log --oneline --decorate";
            lgo = "log --oneline --decorate --graph";
            lgoa = "log --oneline --decorate --graph --all";
            lol = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
            lola = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
          };
          user = {
            name = cfg.identity.name;
            email = cfg.identity.gitEmail;
          };
          push = {
            autoSetupRemote = true;
          };
          init.defaultBranch = "main";
          core = {
            editor = "vim";
            autocrlf = "input";
          };
          pull.rebase = true;
          rebase.autoStash = true;
        };
        lfs = {
          enable = true;
        };
      };

      delta = {
        enable = true;
        enableGitIntegration = true;
        options = {
          features = "decorations line-numbers side-by-side";
          # tmTheme generated by Stylix's bat target, which delta reads from
          # bat's theme cache.
          syntax-theme = "base16-stylix";
          whitespace-error-style = "22 reverse";
          decorations = {
            commit-decoration-style = "bold yellow box ul";
            file-style = "bold yellow ul";
            file-decoration-style = "none";
          };
        };
      };

      fzf = {
        enable = true;
        # Home-manager emits this at order 910 and atuin at 1000, so atuin keeps ^R
        # while we get back ^T and M-c.
        enableZshIntegration = true;
        defaultCommand = "fd --type f --hidden --follow --exclude .git";
        defaultOptions = [
          "--height=60%"
          "--layout=reverse"
          "--border"
          "--info=inline"
        ];
        fileWidgetCommand = "fd --type f --hidden --follow --exclude .git";
        fileWidgetOptions = [
          "--preview 'bat --color=always --style=numbers --line-range=:200 {}'"
        ];
        changeDirWidgetCommand = "fd --type d --hidden --follow --exclude .git";
        changeDirWidgetOptions = [
          "--preview 'eza -1 --color=always --icons {}'"
        ];
      };

      eza.enable = true;

      # Enabled so Stylix has somewhere to write its theme. The LS_COLORS export
      # is baked into the store above, so the per-shell integration stays off.
      vivid = {
        enable = true;
        enableZshIntegration = false;
      };

      bat.enable = true;

      btop.enable = true;

      zoxide = {
        enable = true;
        enableZshIntegration = true;
      };

      vim = {
        enable = true;
        plugins = with pkgs.vimPlugins; [
          vim-airline
          vim-airline-themes
          vim-startify
          vim-tmux-navigator
        ];
        settings = {
          ignorecase = true;
        };
        extraConfig = ''
          "" General
          set number
          set history=1000
          set nocompatible
          set modelines=0
          set encoding=utf-8
          set scrolloff=3
          set showmode
          set showcmd
          set hidden
          set wildmenu
          set wildmode=list:longest,list:full
          set cursorline
          set ttyfast
          set nowrap
          set ruler
          set backspace=indent,eol,start
          set laststatus=2
          set clipboard=autoselect

          " Dir stuff
          set nobackup
          set nowritebackup
          set noswapfile
          set backupdir=~/.config/vim/backups
          set directory=~/.config/vim/swap

          " Relative line numbers for easy movement
          set relativenumber
          set rnu

          "" Whitespace rules
          set tabstop=8
          set shiftwidth=2
          set softtabstop=2
          set expandtab

          "" Searching
          set incsearch
          set gdefault

          "" Statusbar
          set nocompatible " Disable vi-compatibility
          set laststatus=2 " Always show the statusline
          let g:airline_theme='bubblegum'
          let g:airline_powerline_fonts = 1

          "" Local keys and such
          let mapleader=","
          let maplocalleader=" "

          "" Change cursor on mode
          :autocmd InsertEnter * set cul
          :autocmd InsertLeave * set nocul

          "" File-type highlighting and configuration
          syntax on
          filetype on
          filetype plugin on
          filetype indent on

          "" Paste from clipboard
          nnoremap <Leader>, "+gP

          "" Copy from clipboard
          xnoremap <Leader>. "+y

          "" Move cursor by display lines when wrapping
          nnoremap j gj
          nnoremap k gk

          "" Map leader-q to quit out of window
          nnoremap <leader>q :q<cr>

          "" Move around split
          nnoremap <C-h> <C-w>h
          nnoremap <C-j> <C-w>j
          nnoremap <C-k> <C-w>k
          nnoremap <C-l> <C-w>l

          "" Easier to yank entire line
          nnoremap Y y$

          "" Move buffers
          nnoremap <tab> :bnext<cr>
          nnoremap <S-tab> :bprev<cr>

          "" Like a boss, sudo AFTER opening the file to write
          cmap w!! w !sudo tee % >/dev/null

          let g:startify_lists = [
            \ { 'type': 'dir',       'header': ['   Current Directory '. getcwd()] },
            \ { 'type': 'sessions',  'header': ['   Sessions']       },
            \ { 'type': 'bookmarks', 'header': ['   Bookmarks']      }
            \ ]

          let g:startify_bookmarks = [
            \ '~/.local/share/src',
            \ ]

          let g:airline_theme='bubblegum'
          let g:airline_powerline_fonts = 1
        '';
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
        includes = [
          "${config.home.homeDirectory}/.ssh/config_external"
        ];
        settings."*" = {
          IdentityAgent = "\"${onePass.sshAgentSock}\"";
          ForwardAgent = false;
          AddKeysToAgent = "no";
          Compression = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          HashKnownHosts = false;
          UserKnownHostsFile = "${config.home.homeDirectory}/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "${config.home.homeDirectory}/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
      };

      tmux = {
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
        terminal = "screen-256color";
        prefix = "C-x";
        escapeTime = 10;
        historyLimit = 50000;
        extraConfig = ''
          # Stylix emits 24-bit hex colours; without this tmux quantises them
          # down to the 256-colour cube and the pastels go muddy.
          set -ga terminal-features ",*:RGB"

          # Remove Vim mode delays
          set -g focus-events on

          # Enable full mouse support
          set -g mouse on

          # -----------------------------------------------------------------------------
          # Key bindings
          # -----------------------------------------------------------------------------

          # Unbind default keys
          unbind C-b
          unbind '"'
          unbind %

          # Split panes, vertical or horizontal
          bind-key x split-window -v
          bind-key v split-window -h

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
        '';
      };

      bun = {
        enable = true;
      };

      ripgrep = {
        enable = true;
      };

      ripgrep-all = {
        enable = true;
      };

      ############################################################

      yt-dlp = {
        enable = true;
      };
    };

    # Extra completion functions for tools nixpkgs doesn't ship completions for.
    # Picked up via the $fpath entry for the home-manager profile.
    home.packages = [ pkgs.zsh-completions ];

    # One-time migration: import existing zsh history into atuin, preserving it.
    # Guarded by a marker file to keep rebuilds idempotent.
    home.activation.atuinImportZshHistory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      atuin_bin="${lib.getExe pkgs.atuin}"
      zsh_hist="${config.home.homeDirectory}/.zsh_history"
      marker_dir="${stateHome}/atuin"
      marker_file="$marker_dir/imported-zsh-history"

      if [ -x "$atuin_bin" ] && [ -f "$zsh_hist" ] && [ ! -f "$marker_file" ]; then
        echo >&2 "Importing zsh history into atuin (one-time)..."
        mkdir -p "$marker_dir"
        if HISTFILE="$zsh_hist" "$atuin_bin" import zsh; then
          touch "$marker_file"
          echo >&2 "Atuin history import complete."
        else
          echo >&2 "WARNING: atuin import failed; not writing marker file."
        fi
      fi
    '';
  };
}
