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
      }
    else if pkgs.stdenv.hostPlatform.isDarwin then
      {
        sshAgentSock = "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
      }
    else
      throw "Unsupported platform for 1Password agent socket";

  # Expanded in place on space and enter, so what lands in history (and in
  # atuin) is the command that actually ran. Anything here is deliberately not
  # also a shell alias: an alias would shadow the expansion and make
  # zsh-you-should-use nag about the command it just produced.
  abbreviations = {
    # git
    gs = "git status";
    ga = "git add";
    gd = "git diff";
    gds = "git diff --staged";
    gc = "git commit";
    gca = "git commit --amend";
    gl = "git pull";
    gp = "git push";
    gpf = "git push --force-with-lease";
    gco = "git checkout";
    gsw = "git switch";
    gst = "git stash";
    grb = "git rebase";
    gab = "git ab";
    gdf = "git dft";
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

    # build and environment
    cb = "cabal build";
    cr = "cabal-reset";
    ct = "cabal test";
    dr = "ndr-universal";
    da = "direnv allow";
    nd = "nix develop";
  };

  abbreviationTable = lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      key: expansion: "  ${lib.escapeShellArg key} ${lib.escapeShellArg expansion}"
    ) abbreviations
  );
in
{
  imports = [ ./shell ];

  options = {
    home.mroz.shell.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Michael Mroz's shell configuration.";
      example = true;
    };

    home.mroz.shell.flakePath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/workspace/mjvmroz/nixos-config";
      description = ''
        Where this flake lives on the host. Used as nh's default flake, so
        `nh darwin switch` and friends work from any directory.
      '';
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
          # you-should-use and zsh-autopair are deliberately not listed here;
          # they are loaded lazily further down, since between them they cost
          # about 60ms of startup and neither is needed to draw a prompt.
        ];

        shellAliases = {
          ll = "eza -l --git --icons --group-directories-first";
          la = "eza -la --git --icons --group-directories-first";
          lt = "eza --tree --level=2 --git --icons --group-directories-first";
          top = "btop";
          "c." = "cursor .";
          "co." = "code .";
          ghd = "gh-dash";
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

              # Read by zsh-you-should-use, which is sourced at order 900.
              export YSU_MESSAGE_POSITION="after"
              export YSU_MODE=BESTMATCH

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

              # Pick a file with a preview and open it in Cursor. A function
              # rather than an alias so cancelling the picker does nothing
              # instead of opening the working directory.
              cf() {
                local file
                file=$(fd --type f --hidden --follow --exclude .git \
                  | fzf --preview 'bat --color=always --style=numbers --line-range=:200 {}') || return
                [[ -n $file ]] && cursor "$file"
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

              #####
              # Abbreviations
              #####
              typeset -gA ZSH_ABBREVIATIONS
              ZSH_ABBREVIATIONS=(
              ${abbreviationTable}
              )

              # Rewrites the word under the cursor if it is an abbreviation and
              # sits in command position, so `ga` becomes `git add` but the `gd`
              # in `git add gd` is left alone.
              _abbr_expand() {
                emulate -L zsh
                local -a tokens
                tokens=(''${(z)LBUFFER})
                (( $#tokens )) || return 1
                # A trailing space means the word is already finished.
                [[ $LBUFFER = *[[:space:]] ]] && return 1
                local word=$tokens[-1]
                local expansion=''${ZSH_ABBREVIATIONS[$word]}
                [[ -n $expansion ]] || return 1
                if (( $#tokens > 1 )); then
                  case $tokens[-2] in
                    ('|'|'||'|'&&'|';'|'&'|'sudo'|'command'|'time'|'xargs'|'nohup') ;;
                    # A leading VAR=value assignment still leaves the next word
                    # in command position.
                    ([A-Za-z_]*=*) ;;
                    (*) return 1 ;;
                  esac
                fi
                LBUFFER="''${LBUFFER[1,-$(($#word + 1))]}$expansion"
              }

              _abbr_expand_and_insert() { _abbr_expand; zle self-insert }
              _abbr_expand_and_accept() { _abbr_expand; zle accept-line }
              zle -N _abbr_expand_and_insert
              zle -N _abbr_expand_and_accept
              bindkey ' ' _abbr_expand_and_insert
              bindkey '^M' _abbr_expand_and_accept
              # Alt-space when you want the abbreviation left alone.
              bindkey '^[ ' self-insert
              # Searching should never rewrite what you are searching for.
              bindkey -M isearch ' ' self-insert

              # What did I call that again?
              abbrs() {
                local key
                for key in ''${(ko)ZSH_ABBREVIATIONS}; do
                  printf '%-8s %s\n' "$key" "$ZSH_ABBREVIATIONS[$key]"
                done
              }

              #####
              # Deferred loading
              #####
              # None of these are needed to draw the first prompt, and together
              # they cost around 60ms. zsh-defer runs them once the shell goes
              # idle, which takes that off the critical path. Loading after
              # zsh-syntax-highlighting is fine: it hooks zle-line-pre-redraw
              # rather than wrapping widgets at load time.
              # Despite the name, television's completion.zsh is not a
              # completion: it defines two widgets and binds them over ^R and
              # ^T, which belong to atuin and fzf. Put the bindings back and
              # park the one genuinely new widget on M-t.
              _load_television() {
                source ${pkgs.television}/share/television/completion.zsh
                (( ''${+widgets[atuin-search]} )) && bindkey '^R' atuin-search
                (( ''${+widgets[fzf-file-widget]} )) && bindkey '^T' fzf-file-widget
                bindkey '^[t' tv-smart-autocomplete
              }

              if [[ -o interactive ]]; then
                source ${pkgs.zsh-defer}/share/zsh-defer/zsh-defer.plugin.zsh
                zsh-defer source ${pkgs.zsh-you-should-use}/share/zsh/plugins/you-should-use/you-should-use.plugin.zsh
                # autopair captures whatever is bound to space when it loads and
                # delegates to it, so loading it last keeps abbreviations working.
                zsh-defer source ${pkgs.zsh-autopair}/share/zsh/zsh-autopair/autopair.zsh
                zsh-defer _load_television
              fi
            '';
          in
          lib.mkMerge [
            (lib.mkOrder 500 earlyInit)
            (lib.mkOrder 1180 completionAndKeys)
          ];
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

      # `y` opens the browser and leaves the shell in whatever directory you
      # quit from. Themed by Stylix's yazi target.
      yazi = {
        enable = true;
        enableZshIntegration = true;
        shellWrapperName = "y";
        settings.mgr = {
          show_hidden = false;
          sort_dir_first = true;
        };
      };

      # Channel-based fuzzy finder. It never binds keys, so atuin keeps ^R and
      # fzf keeps ^T. Its completions are sourced lazily alongside the other
      # deferred plugins rather than through enableZshIntegration.
      television = {
        enable = true;
        enableZshIntegration = false;
        settings.ui = {
          use_nerd_font_icons = true;
          ui_scale = 100;
        };
        channels = {
          git-log = {
            metadata = {
              name = "git-log";
              description = "Commits in the current repository";
              requirements = [ "git" ];
            };
            source = {
              command = "git log --oneline --date=short --pretty='format:%h %s %an %cd'";
              output = "{split: :0}";
            };
            preview.command = "git show -p --stat --pretty=fuller --color=always '{0}'";
          };
          git-diff = {
            metadata = {
              name = "git-diff";
              description = "Files changed against HEAD";
              requirements = [ "git" ];
            };
            source.command = "git diff --name-only HEAD";
            preview.command = "git diff HEAD --color=always -- '{}'";
          };
        };
      };

      # Wraps darwin-rebuild/nixos-rebuild with nix-output-monitor and prints a
      # generation diff afterwards. Cleanup stays off; GC is handled at the
      # system level.
      nh = {
        enable = true;
        flake = cfg.flakePath;
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

    home.sessionVariables = {
      EDITOR = "vim";
      VISUAL = "vim";
      # Syntax-highlighted man pages. col strips the overstrike backspaces
      # groff emits, which bat would otherwise render literally.
      MANPAGER = "sh -c 'col -bx | bat --language man --style plain'";
      MANROFFOPT = "-c";
    };

    home.packages = [
      # Extra completion functions for tools nixpkgs doesn't ship completions
      # for. Picked up via the $fpath entry for the home-manager profile.
      pkgs.zsh-completions

      # bat's pager applied to man, grep, diff and friends.
      pkgs.bat-extras.batman
      pkgs.bat-extras.batgrep
      pkgs.bat-extras.batdiff
      pkgs.bat-extras.prettybat
    ];

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
