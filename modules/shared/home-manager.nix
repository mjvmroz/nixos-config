{
  identity,
  config,
  pkgs,
  lib,
  onePassAgentPath,
  gpgSshProgram,
  ...
}:

{
  # Shared shell configuration
  zsh = {
    enable = true;
    dotDir = "dotfiles";
    autocd = true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };
    history = {
      append = true;
      ignoreDups = true;
      ignoreSpace = true; # Leading spaces hide commands from history
    };
    historySubstringSearch = {
      enable = true;
    };
    autosuggestion = {
      enable = true;
      strategy = [ "history" ];
    };
    plugins = [
      {
        name = "zsh-ls-colors";
        src = pkgs.fetchFromGitHub {
          owner = "xPMo";
          repo = "zsh-ls-colors";
          rev = "6a5e0c4d201467cd469b300108939543a59ffed7";
          sha256 = "sha256-YtzyXVGG5ZfvqIkGSinRx6MxZPaz2NKVkNq7+cvFp7Y=";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "c2b4aa5ad2532cca91f23908ac7f00efb7ff09c9";
          sha256 = "1b4pksrc573aklk71dn2zikiymsvq19bgvamrdffpf7azpq6kxl2";
        };
      }
    ];

    shellAliases = {
      ll = "exa -l";
      la = "exa -la";
      gl = "git pull";
      gp = "git push";
      gco = "git checkout";
      cat = "bat";
      top = "btop";
      # At some point I should update these. I've been carrying them around since bailing on OMZ an eon ago.
      glg = "git log --stat";
      glgp = "git log --stat -p";
      glgg = "git log --graph";
      glgga = "git log --graph --decorate --all";
      glgm = "git log --graph --max-count 10";
      glo = "git log --oneline --decorate";
      glol = "git log --graph --pretty format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      glola = "git log --graph --pretty format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --all";
      glog = "git log --oneline --decorate --graph";
      gloga = "git log --oneline --decorate --graph --all";
      cf = "code $(fzf)";
      "c." = "code .";
      dr = "direnv reload";
      da = "direnv allow";
      cb = "cabal build";
      ccb = "cabal clean && cabal build";
    };
    cdpath = [ "~/.local/share/src" ];
    initExtraFirst = ''
      if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
        . /nix/var/nix/profiles/default/etc/profile.d/nix.sh
      fi

      # Define variables for directories
      export PATH=$HOME/.local/share/bin:$PATH

      export LESS="-R -M -i -J -z-4 --mouse"

      # Remove history data we don't want to see
      export HISTIGNORE="pwd:ls:cd"

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
        exa --tree --color=always $1 | less
      }

      export SSH_AUTH_SOCK=$(expand_tilde "${onePassAgentPath}")

      bindkey '^[[1;9D' beginning-of-line
      bindkey '^[[1;9C' end-of-line
    '';
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

  git = {
    enable = true;
    delta = {
      enable = true;
      options = {
        features = "decorations line-numbers side-by-side";
        whitespace-error-style = "22 reverse";
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
      };
    };
    ignores = [ "*.swp" ];
    userName = identity.name;
    userEmail = identity.email;
    lfs = {
      enable = true;
    };
    extraConfig = {
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        autocrlf = "input";
      };
      user.signingkey = identity.signingKey;
      gpg.format = "ssh";
      gpg.ssh.program = gpgSshProgram;
      commit.gpgsign = true;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "ag -g ''";
    fileWidgetCommand = "fd --type f";
  };

  eza.enable = true;

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
      set wildmode=list:longest
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
    includes = [
      (lib.mkIf pkgs.stdenv.hostPlatform.isLinux "/home/${identity.user}/.ssh/config_external")
      (lib.mkIf pkgs.stdenv.hostPlatform.isDarwin "/Users/${identity.user}/.ssh/config_external")
    ];
    extraConfig = ''
      IdentityAgent "${onePassAgentPath}"
    '';

  };

  tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      sensible
      yank
      prefix-highlight
      {
        plugin = power-theme;
        extraConfig = ''
          set -g @tmux_power_theme 'gold'
        '';
      }
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

  ############################################################

  newsboat = {
    enable = true;
    urls = [
      # "https://news.ycombinator.com/rss"
      # "https://lobste.rs/rss"
      {
        url = "https://www.heneli.dev/feed.xml";
        tags = [ "haskell" ];
      }
    ];
  };

  yt-dlp = {
    enable = true;
  };
}
