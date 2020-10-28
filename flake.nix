#
# This file is auto-generated from "README.org"
#
{
  description = "rasendubi's packages and NixOS/home-manager configurations";

  inputs = {
    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs-channels";
      ref = "nixpkgs-unstable";
    };

    nixpkgs-stable = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs-channels";
      ref = "nixos-20.03";
    };
    home-manager = {
      type = "github";
      owner = "rycee";
      repo = "home-manager";
      ref = "master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware = {
      type = "github";
      owner = "NixOS";
      repo = "nixos-hardware";
      flake = false;
    };
    emacs-overlay = {
      type = "github";
      owner = "nix-community";
      repo = "emacs-overlay";
    };
  };

  outputs = { self, ... }@inputs:
    let
      # Flakes are evaluated hermetically, thus are unable to access
      # host environment (including looking up current system).
      #
      # That's why flakes must explicitly export sets for each system
      # supported.
      systems = ["x86_64-linux" "aarch64-linux"];

      # genAttrs applies f to all elements of a list of strings, and
      # returns an attrset { name -> result }
      #
      # Useful for generating sets for all systems or hosts.
      genAttrs = list: f: inputs.nixpkgs.lib.genAttrs list f;

      # Generate pkgs set for each system. This takes into account my
      # nixpkgs config (allowUnfree) and my overlays.
      pkgsBySystem =
        let mkPkgs = system: import inputs.nixpkgs {
              inherit system;
              overlays = self.overlays.${system};
              config = { allowUnfree = true; };
            };
        in genAttrs systems mkPkgs;

      # genHosts takes an attrset { name -> options } and calls mkHost
      # with options+name. The result is accumulated into an attrset
      # { name -> result }.
      #
      # Used in NixOS and Home Manager configurations.
      genHosts = hosts: mkHost:
        genAttrs (builtins.attrNames hosts) (name: mkHost ({ inherit name; } // hosts.${name}));

      # merges a list of attrsets into a single attrset
      mergeSections = inputs.nixpkgs.lib.foldr inputs.nixpkgs.lib.mergeAttrs {};

    in mergeSections [
      (let
        nixosHosts = {
          omicron = { system = "x86_64-linux";  config = ./nixos-config.nix; };
      
          # pie uses a separate config as it is very different
          # from other hosts.
          pie =     { system = "aarch64-linux"; config = ./pie.nix; };
        };
      
        mkNixosConfiguration = { name, system, config }:
          let pkgs = pkgsBySystem.${system};
          in inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              { nixpkgs = { inherit pkgs; }; }
              (import config)
            ];
            specialArgs = { inherit name inputs; };
          };
      
      in {
        nixosConfigurations = genHosts nixosHosts mkNixosConfiguration;
      })
      (let
        homeManagerHosts = {
          AlexeyShmalko = {
            system = "x86_64-linux";
            config = ./work.nix;
            username = "rasen";
            homeDirectory = "/home/rasen";
          };
        };
      
        mkHomeManagerConfiguration = { system, name, config, username, homeDirectory }:
          let pkgs = pkgsBySystem.${system};
          in inputs.home-manager.lib.homeManagerConfiguration {
            inherit system pkgs username homeDirectory;
            configuration = { ... }: {
              nixpkgs.config.allowUnfree = true;
              nixpkgs.config.firefox.enableTridactylNative = true;
              nixpkgs.overlays = self.overlays.${system};
              imports = [
                self.lib.home-manager-common
      
                (import config)
              ];
            };
          };
      
      in {
        # Re-export common home-manager configuration to be reused between
        # NixOS module and standalone home-manager config.
        lib.home-manager-common = { lib, pkgs, config, ... }: {
          imports = [
            {
              home.file."nixpkgs".source = inputs.nixpkgs;
              systemd.user.sessionVariables.NIX_PATH = lib.mkForce "nixpkgs=$HOME/nixpkgs\${NIX_PATH:+:}$NIX_PATH";
            
              xdg.configFile."nix/registry.json".text = builtins.toJSON {
                version = 2;
                flakes = [
                  {
                    from = { id = "self"; type = "indirect"; };
                    to = ({
                      type = "path";
                      path = inputs.self.outPath;
                    } // lib.filterAttrs
                      (n: v: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash")
                      inputs.self);
                  }
                  {
                    from = { id = "nixpkgs"; type = "indirect"; };
                    to = ({
                      type = "path";
                      path = inputs.nixpkgs.outPath;
                    } // lib.filterAttrs
                      (n: v: n == "lastModified" || n == "rev" || n == "revCount" || n == "narHash")
                      inputs.nixpkgs);
                  }
                ];
              };
            }
            {
              programs.emacs = {
                enable = true;
                package = pkgs.my-emacs.base;
                extraPackages = pkgs.my-emacs.packages;
              };
              services.emacs.enable = true;
            
              # fonts used by emacs
              home.packages = [
                pkgs.input-mono
                pkgs.libertine
              ];
            }
            {
              services.picom.enable = true;
            }
            {
              home.packages = [
                pkgs.xss-lock
              ];
            }
            {
              home.packages = [ pkgs.escrotum ];
            }
            {
              home.keyboard = {
                layout = "us,ua";
                variant = "workman,";
              };
            }
            {
              xsession.initExtra = ''
                xkbcomp ${./Xkeymap} $DISPLAY
              '';
            }
            {
              home.packages = [ pkgs.xorg.xkbcomp ];
            }
            {
              home.packages = [ pkgs.naga ];
            }
            {
              home.packages = [ pkgs.networkmanagerapplet ];
            }
            {
              programs.direnv.enable = true;
              services.lorri.enable = true;
            }
            {
              programs.autorandr = {
                enable = true;
                profiles =
                  let
                    omicron = "00ffffffffffff004d104a14000000001e190104a51d11780ede50a3544c99260f505400000001010101010101010101010101010101cd9180a0c00834703020350026a510000018a47480a0c00834703020350026a510000018000000fe0052584e3439814c513133335a31000000000002410328001200000b010a202000cc";
                    work = "00ffffffffffff004d108d1400000000051c0104a52213780ea0f9a95335bd240c5157000000010101010101010101010101010101014dd000a0f0703e803020350058c210000018000000000000000000000000000000000000000000fe00464e564452804c513135364431000000000002410328011200000b010a202000ee";
                    home-monitor = "00ffffffffffff0010acc0a042524530031c010380351e78eae245a8554da3260b5054a54b00714f8180a9c0a940d1c0e10001010101a36600a0f0701f80302035000f282100001a000000ff004438565846383148304552420a000000fc0044454c4c205032343135510a20000000fd001d4c1e8c1e000a202020202020018802032ef15390050402071601141f1213272021220306111523091f07830100006d030c001000003c200060030201023a801871382d40582c25000f282100001e011d8018711c1620582c25000f282100009e04740030f2705a80b0588a000f282100001e565e00a0a0a02950302035000f282100001a0000000000000000008a";
                    work-monitor = "00ffffffffffff0010acc2d0545741312c1b010380351e78eaad75a9544d9d260f5054a54b008100b300d100714fa9408180d1c00101565e00a0a0a02950302035000e282100001a000000ff004d59334e44374234314157540a000000fc0044454c4c205032343138440a20000000fd0031561d711c000a202020202020010302031bb15090050403020716010611121513141f2065030c001000023a801871382d40582c45000e282100001e011d8018711c1620582c25000e282100009ebf1600a08038134030203a000e282100001a7e3900a080381f4030203a000e282100001a00000000000000000000000000000000000000000000000000000000d8";
                  in {
                  "omicron" = {
                    fingerprint = {
                      eDP-1 = omicron;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "0x0";
                        mode = "3200x1800";
                        rate = "60.00";
                      };
                    };
                  };
                  "omicron-home" = {
                    fingerprint = {
                      eDP-1 = omicron;
                      DP-1 = home-monitor;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "320x2160";
                        mode = "3200x1800";
                        rate = "60.00";
                      };
                      DP-1 = {
                        enable = true;
                        position = "0x0";
                        mode = "3840x2160";
                        rate = "60.00";
                      };
                    };
                  };
            
                  "work" = {
                    fingerprint = {
                      eDP-1 = work;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "0x0";
                        mode = "3840x2160";
                        rate = "60.00";
                        dpi = 284;
                      };
                    };
                  };
                  "work-home" = {
                    fingerprint = {
                      eDP-1 = work;
                      DP-3 = home-monitor;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "0x2160";
                        mode = "3840x2160";
                        rate = "60.00";
                        dpi = 284;
                      };
                      DP-3 = {
                        enable = true;
                        position = "0x0";
                        mode = "3840x2160";
                        rate = "29.98";
                        dpi = 183;
                      };
                    };
                  };
                  "work-home-usbc" = {
                    fingerprint = {
                      eDP-1 = work;
                      DP-1 = home-monitor;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "0x2160";
                        mode = "3840x2160";
                        rate = "60.00";
                        dpi = 284;
                      };
                      DP-1 = {
                        enable = true;
                        position = "0x0";
                        mode = "3840x2160";
                        rate = "29.98";
                        dpi = 183;
                      };
                    };
                  };
                  "work-work" = {
                    fingerprint = {
                      eDP-1 = work;
                      DP-3 = work-monitor;
                    };
                    config = {
                      eDP-1 = {
                        enable = true;
                        primary = true;
                        position = "0x1440";
                        mode = "3840x2160";
                        rate = "60.00";
                        dpi = 284;
                      };
                      DP-3 = {
                        enable = true;
                        position = "640x0";
                        mode = "2560x1440";
                        rate = "59.95";
                        dpi = 124;
                      };
                    };
                  };
                };
              };
            }
            {
              home.packages = [ pkgs.acpilight ];
            }
            {
              home.packages = [ pkgs.pavucontrol ];
            }
            {
              home.packages = [
                pkgs.firefox
                pkgs.google-chrome
              ];
            }
            {
              xdg.configFile."tridactyl/tridactylrc".text = ''
                " drop all existing configuration
                sanitize tridactyllocal tridactylsync
                
                bind J scrollline -10
                bind K scrollline 10
                bind j scrollline -2
                bind k scrollline 2
              '';
            }
            {
              # Store mails in ~/Mail
              accounts.email.maildirBasePath = "Mail";
            
              # Use mbsync to fetch email. Configuration is constructed manually
              # to keep my current email layout.
              programs.mbsync = {
                enable = true;
                extraConfig = lib.mkBefore ''
                  MaildirStore local
                  Path ~/Mail/
                  Inbox ~/Mail/INBOX
                  SubFolders Verbatim
                '';
              };
            
              # Notmuch for email browsing, tagging, and searching.
              programs.notmuch = {
                enable = true;
                new.ignore = [
                  ".mbsyncstate"
                  ".mbsyncstate.lock"
                  ".mbsyncstate.new"
                  ".mbsyncstate.journal"
                  ".uidvalidity"
                  "dovecot-uidlist"
                  "dovecot-keywords"
                  "dovecot.index"
                  "dovecot.index.log"
                  "dovecot.index.log.2"
                  "dovecot.index.cache"
                  "/^archive/"
                ];
              };
            
              # msmtp for sending mail
              programs.msmtp.enable = true;
            
              # My Maildir layout predates home-manager configuration, so I do not
              # use mbsync config generation from home-manager, to keep layout
              # compatible.
              imports =
                let
                  emails = [
                    { name = "gmail";   email = "rasen.dubi@gmail.com";    path = "Personal"; primary = true; }
                    { name = "ps";      email = "ashmalko@doctoright.org"; path = "protocolstandard"; }
                    { name = "egoless"; email = "me@egoless.tech";         path = "egoless"; }
                  ];
                  mkGmailBox = { name, email, path, ... }@all: {
                    accounts.email.accounts.${name} = {
                      realName = "Alexey Shmalko";
                      address = email;
                      flavor = "gmail.com";
            
                      passwordCommand = "pass imap.gmail.com/${email}";
                      maildir.path = path;
            
                      msmtp.enable = true;
                      notmuch.enable = true;
                    } // (removeAttrs all ["name" "email" "path"]);
            
                    programs.mbsync.extraConfig = ''
                      IMAPAccount ${name}
                      Host imap.gmail.com
                      User ${email}
                      PassCmd "pass imap.gmail.com/${email}"
                      SSLType IMAPS
                      CertificateFile /etc/ssl/certs/ca-certificates.crt
            
                      IMAPStore ${name}-remote
                      Account ${name}
            
                      Channel sync-${name}-all
                      Master :${name}-remote:"[Gmail]/All Mail"
                      Slave :local:${path}/all
                      Create Both
                      SyncState *
            
                      Channel sync-${name}-spam
                      Master :${name}-remote:"[Gmail]/Spam"
                      Slave :local:${path}/spam
                      Create Both
                      SyncState *
            
                      Channel sync-${name}-sent
                      Master :${name}-remote:"[Gmail]/Sent Mail"
                      Slave :local:${path}/sent
                      Create Both
                      SyncState *
            
                      Group sync-${name}
                      Channel sync-${name}-all
                      Channel sync-${name}-spam
                      Channel sync-${name}-sent
                    '';
                  };
                in map mkGmailBox emails;
            }
            {
              home.packages = [
                (pkgs.pass.withExtensions (exts: [ exts.pass-otp ]))
              ];
            }
            {
              programs.browserpass = {
                enable = true;
                browsers = ["firefox" "chrome"];
              };
            }
            {
              home.packages = [
                pkgs.gwenview
                pkgs.dolphin
                pkgs.kdeFrameworks.kfilemetadata
                pkgs.filelight
                pkgs.shared_mime_info
              ];
            }
            {
              programs.zathura = {
                enable = true;
                options = {
                  incremental-search = true;
                };
            
                # Swap j/k (for Workman layout)
                extraConfig = ''
                  map j scroll up
                  map k scroll down
                '';
              };
            }
            {
              home.packages = [
                pkgs.google-play-music-desktop-player
                pkgs.tdesktop # Telegram
            
                pkgs.mplayer
                pkgs.smplayer
              ];
            }
            {
              home.packages = [
                (pkgs.vim_configurable.override { python3 = true; })
              ];
            }
            {
              home.file.".vim".source = ./.vim;
              home.file.".vimrc".source = ./.vim/init.vim;
            }
            {
              programs.urxvt = {
                enable = true;
                iso14755 = false;
            
                fonts = [
                  "-*-terminus-medium-r-normal-*-32-*-*-*-*-*-iso10646-1"
                ];
            
                scroll = {
                  bar.enable = false;
                  lines = 65535;
                  scrollOnOutput = false;
                  scrollOnKeystroke = true;
                };
                extraConfig = {
                  "loginShell" = "true";
                  "urgentOnBell" = "true";
                  "secondaryScroll" = "true";
            
                  # Molokai color theme
                  "background" = "#101010";
                  "foreground" = "#d0d0d0";
                  "color0" = "#101010";
                  "color1" = "#960050";
                  "color2" = "#66aa11";
                  "color3" = "#c47f2c";
                  "color4" = "#30309b";
                  "color5" = "#7e40a5";
                  "color6" = "#3579a8";
                  "color7" = "#9999aa";
                  "color8" = "#303030";
                  "color9" = "#ff0090";
                  "color10" = "#80ff00";
                  "color11" = "#ffba68";
                  "color12" = "#5f5fee";
                  "color13" = "#bb88dd";
                  "color14" = "#4eb4fa";
                  "color15" = "#d0d0d0";
                };
              };
            }
            {
              programs.fish = {
            
                interactiveShellInit = ''
                  function vterm_prompt_end;
                    vterm_printf '51;A'(whoami)'@'(hostname)':'(pwd)
                  end
                  functions --copy fish_prompt vterm_old_fish_prompt
                  function fish_prompt --description 'Write out the prompt; do not replace this. Instead, put this at end of your file.'
                    # Remove the trailing newline from the original prompt. This is done
                    # using the string builtin from fish, but to make sure any escape codes
                    # are correctly interpreted, use %b for printf.
                    printf "%b" (string join "\n" (vterm_old_fish_prompt))
                    vterm_prompt_end
                  end
                '';
            
                functions.vterm_printf = ''
                  function vterm_printf;
                    if [ -n "$TMUX" ]
                      # tell tmux to pass the escape sequences through
                      # (Source: http://permalink.gmane.org/gmane.comp.terminal-emulators.tmux.user/1324)
                      printf "\ePtmux;\e\e]%s\007\e\\" "$argv"
                    else if string match -q -- "screen*" "$TERM"
                      # GNU screen (screen, screen-256color, screen-256color-bce)
                      printf "\eP\e]%s\007\e\\" "$argv"
                    else
                      printf "\e]%s\e\\" "$argv"
                    end
                  end
                '';
            
                functions.vterm_cmd = ''
                  function vterm_cmd --description 'Run an emacs command among the ones been defined in vterm-eval-cmds.'
                      set -l vterm_elisp ()
                      for arg in $argv
                        set -a vterm_elisp (printf '"%s" ' (string replace -a -r '([\\\\"])' '\\\\\\\\$1' $arg))
                      end
                      vterm_printf '51;E'(string join "" $vterm_elisp)
                  end
                '';
              };
            }
            {
              programs.fish = {
                enable = true;
                shellAliases = {
                  g = "git";
                  rm = "rm -r";
                  ec = "emacsclient";
                };
                functions = {
                  # old stuff
                  screencast = ''
                    function screencast
                        # key-mon --meta --nodecorated --theme=big-letters --key-timeout=0.05 &
                        ffmpeg -probesize 3000000000 -f x11grab -framerate 25 -s 3840x3960 -i :0.0 -vcodec libx264 -threads 2 -preset ultrafast -crf 0 ~/tmp/record/record-(date +"%FT%T%:z").mkv
                        # killall -r key-mon
                    end
                  '';
                  reencode = ''
                    function reencode
                        ffmpeg -i file:$argv[1] -c:v libx264 -crf 0 -preset veryslow file:(basename $argv[1] .mkv).crf-0.min.mkv
                    end
                  '';
                };
              };
            
              # manage other shells as well
              programs.bash.enable = true;
            }
            {
              programs.fish.functions.fish_user_key_bindings = ''
                function fish_user_key_bindings
                    fish_vi_key_bindings
            
                    bind -s j up-or-search
                    bind -s k down-or-search
                    bind -s -M visual j up-line
                    bind -s -M visual k down-line
            
                    bind -s '.' repeat-jump
                end
              '';
            }
            {
              programs.tmux = {
                enable = true;
                keyMode = "vi";
                # Use C-a as prefix
                shortcut = "a";
                # To make vim work properly
                terminal = "screen-256color";
            
                # start numbering from 1
                baseIndex = 1;
                # Allows for faster key repetition
                escapeTime = 0;
                historyLimit = 10000;
            
                reverseSplit = true;
            
                clock24 = true;
            
                extraConfig = ''
                  bind-key S-left swap-window -t -1
                  bind-key S-right swap-window -t +1
            
                  bind h select-pane -L
                  bind k select-pane -D
                  bind j select-pane -U
                  bind l select-pane -R
            
                  bind r source-file ~/.tmux.conf \; display-message "Config reloaded..."
            
                  set-window-option -g automatic-rename
                '';
              };
            }
            {
              programs.git = {
                enable = true;
                package = pkgs.gitAndTools.gitFull;
            
                userName = "Alexey Shmalko";
                userEmail = "rasen.dubi@gmail.com";
            
                signing = {
                  key = "EB3066C3";
                  signByDefault = true;
                };
            
                extraConfig = {
                  sendemail = {
                    smtpencryption = "ssl";
                    smtpserver = "smtp.gmail.com";
                    smtpuser = "rasen.dubi@gmail.com";
                    smtpserverport = 465;
                  };
            
                  color.ui = true;
                  core.editor = "vim";
                  push.default = "simple";
                  pull.rebase = true;
                  rebase.autostash = true;
                  rerere.enabled = true;
                  advice.detachedHead = false;
                };
              };
            }
            {
              programs.git.aliases = {
                cl    = "clone";
                gh-cl = "gh-clone";
                cr    = "cr-fix";
                p     = "push";
                pl    = "pull";
                f     = "fetch";
                fa    = "fetch --all";
                a     = "add";
                ap    = "add -p";
                d     = "diff";
                dl    = "diff HEAD~ HEAD";
                ds    = "diff --staged";
                l     = "log --show-signature";
                l1    = "log -1";
                lp    = "log -p";
                c     = "commit";
                ca    = "commit --amend";
                co    = "checkout";
                cb    = "checkout -b";
                cm    = "checkout origin/master";
                de    = "checkout --detach";
                fco   = "fetch-checkout";
                br    = "branch";
                s     = "status";
                re    = "reset --hard";
                r     = "rebase";
                rc    = "rebase --continue";
                ri    = "rebase -i";
                m     = "merge";
                t     = "tag";
                su    = "submodule update --init --recursive";
                bi    = "bisect";
              };
            }
            {
              programs.git.extraConfig = {
                url."git@github.com:".pushInsteadOf = "https://github.com";
              };
            }
            {
              home.packages = [ pkgs.racket ];
            }
            {
              fonts.fontconfig.enable = true;
              home.packages = [
                pkgs.inconsolata
                pkgs.dejavu_fonts
                pkgs.source-code-pro
                pkgs.ubuntu_font_family
                pkgs.unifont
                pkgs.powerline-fonts
                pkgs.terminus_font
              ];
            }
            {
              xresources.properties = {
                "Xft.dpi" = 276;
                "Xcursor.size" = 64;
              };
            }
            {
              home.file = {
                ".nethackrc".source = ./.nethackrc;
              };
            
              programs.fish.shellInit = ''
                set -x PATH ${./bin} $PATH
              '';
            }
          ];
          home.stateVersion = "20.09";
        };
        homeManagerConfigurations = genHosts homeManagerHosts mkHomeManagerConfiguration;
      })
      (let
        mkPackages = system:
          let
            pkgs = pkgsBySystem.${system};
          in
            mergeSections [
              (let
                emacs-base = pkgs.emacsGit;
                # emacs = pkgs.emacsUnstable;
                # emacs = pkgs.emacs.override {
                #   # Build emacs with proper imagemagick support.
                #   # See https://github.com/NixOS/nixpkgs/issues/70631#issuecomment-570085306
                #   imagemagick = pkgs.imagemagickBig;
                # };
                emacs-packages = (epkgs:
                  (with epkgs.melpaPackages; [
              
                    aggressive-indent
                    atomic-chrome
                    avy
                    bash-completion
                    beacon
                    blacken
                    cider
                    clojure-mode
                    cmake-mode
                    color-identifiers-mode
                    company
                    company-box
                    company-lsp
                    company-org-roam
                    counsel
                    counsel-projectile
                    diff-hl
                    diminish
                    direnv
                    dockerfile-mode
                    doom-modeline
                    dtrt-indent
                    edit-indirect
                    eglot
                    el-patch
                    elpy
                    epresent
                    evil
                    evil-collection
                    evil-magit
                    evil-numbers
                    evil-org
                    evil-surround
                    evil-swap-keys
                    fish-completion
                    fish-mode
                    flycheck
                    flycheck-inline
                    flycheck-jest
                    flycheck-rust
                    forth-mode
                    general
                    gitconfig-mode
                    go-mode
                    google-translate
                    graphviz-dot-mode
                    groovy-mode
                    haskell-mode
                    imenu-list
                    ivy
                    ivy-bibtex
                    ivy-pass
                    jinja2-mode
                    js2-mode
                    json-mode
                    ledger-mode
                    lispyville
                    lsp-haskell
                    lsp-mode
                    lsp-ui
                    lua-mode
                    magit
                    markdown-mode
                    modus-operandi-theme
                    monokai-theme
                    nix-mode
                    nix-sandbox
                    notmuch
                    org-cliplink
                    org-download
                    org-drill
                    org-ref
                    org-roam
                    org-roam-bibtex
                    org-super-agenda
                    paren-face
                    pass
                    php-mode
                    pip-requirements
                    plantuml-mode
                    prettier-js
                    projectile
                    protobuf-mode
                    psc-ide
                    purescript-mode
                    py-autopep8
                    racer
                    racket-mode
                    restclient
                    rjsx-mode
                    rust-mode
                    smex
                    spaceline
                    terraform-mode
                    tide
                    typescript-mode
                    use-package
                    visual-fill-column
                    vterm
                    vue-mode
                    w3m
                    web-mode
                    wgrep
                    which-key
                    whitespace-cleanup-mode
                    writegood-mode
                    yaml-mode
                    yasnippet
              
                  ]) ++
                  [
                    epkgs.orgPackages.org-plus-contrib
                    epkgs.elpaPackages.adaptive-wrap
                    epkgs.exwm
              
                    (epkgs.melpaBuild rec {
                      pname = "org-fc";
                      version = "20201002";
                      src = pkgs.fetchFromGitHub {
                        owner = "l3kn";
                        repo = "org-fc";
                        rev = "0fd72b4d9dcf82584b784bb7cf76d94109ee9bab";
                        sha256 = "sha256-X01yELYog1bRJb1jAk77jbjDBvJxMVLoDsw+7S4lLec=";
                      };
                      packageRequires = [ epkgs.orgPackages.org-plus-contrib ];
                      propagatedUserEnvPkgs = [ pkgs.findutils pkgs.gawk ];
              
                      recipe = pkgs.writeText "recipe" ''
                       (org-fc
                        :repo "l3kn/org-fc"
                        :fetcher github
                        :files ("*.el" "demo.org" "awk"))
                      '';
              
                      meta = {
                        description = "Spaced Repetition System for Emacs org-mode";
                        license = pkgs.lib.licenses.gpl3;
                      };
                    })
              
                    # required for org-roam/emacsql-sqlite3
                    pkgs.sqlite
              
                    (pkgs.ycmd.override (old: {
                      # racerd is currently broken
                      rustracerd = null;
                    }))
                    pkgs.notmuch
                    pkgs.w3m
                    pkgs.imagemagick
                    pkgs.shellcheck
              
                    (pkgs.python3.withPackages (pypkgs: [
                      pypkgs.autopep8
                      pypkgs.black
                      pypkgs.flake8
                      pypkgs.mypy
                      pypkgs.pylint
                      pypkgs.virtualenv
                    ]))
              
                    (pkgs.aspellWithDicts (dicts: with dicts; [en en-computers en-science ru uk]))
              
                    # latex for displaying fragments in org-mode
                    (pkgs.texlive.combine {
                      inherit (pkgs.texlive) scheme-small dvipng dvisvgm mhchem tikz-cd ;
                    })
                    pkgs.ghostscript
                  ]
                );
              
                emacs-final = (pkgs.emacsPackagesGen emacs-base).emacsWithPackages emacs-packages;
              
               in {
                 my-emacs = emacs-final // {
                   base = emacs-base;
                   packages = emacs-packages;
                 };
               })
              {
                naga = pkgs.callPackage ./naga { };
              }
              (let
                websigner =
                  { stdenv
                  , fetchurl
                  , autoPatchelfHook
                  , gtk2
                  , glib
                  , pcsclite
                  }:
                  stdenv.mkDerivation {
                    pname = "procreditbank-websigner";
                    version = "2020-01-20";
              
                    src = fetchurl {
                      url = "https://ibank.procreditbank.com.ua/websigner-linux.bin";
                      sha256 = "1bm88jg7nhgrmc0q5hv35hgv4nc0d15ihl0acrhf6x5f7wv4pszv";
                    };
              
                    nativeBuildInputs = [ autoPatchelfHook ];
              
                    buildInputs = [ gtk2 glib pcsclite ];
              
                    unpackCmd = ''
                      sh $src --extract
                    '';
              
                    dontConfigure = true;
              
                    dontBuild = true;
              
                    installPhase = ''
                      mkdir -p $out/bin
                      mkdir -p $out/lib/websigner/hosts/firefox
                      mkdir -p $out/lib/websigner/hosts/chromium
              
                      install -m 555 x86_64-linux/npwebsigner.so $out/lib/websigner
                      install -m 777 x86_64-linux/nmwebsigner $out/lib/websigner
              
                      sed "s|PLUGIN_PATH|$out/lib/websigner/nmwebsigner|" com.bifit.websigner-mozilla.json > $out/lib/websigner/hosts/firefox/com.bifit.websigner.json
                      sed "s|PLUGIN_PATH|$out/lib/websigner/nmwebsigner|" com.bifit.websigner-chrome.json > $out/lib/websigner/hosts/chromium/com.bifit.websigner.json
              
                      mkdir -p $out/lib/mozilla/native-messaging-hosts
                      ln -s $out/lib/websigner/hosts/firefox/*.json $out/lib/mozilla/native-messaging-hosts
                    '';
                  };
              in {
                procreditbank-websigner = pkgs.callPackage websigner { };
              })
              {
                # note it's a new attribute and does not override old one
                input-mono = (pkgs.input-fonts.overrideAttrs (old: {
                  src = pkgs.requireFile {
                    name = "Input-Font.zip";
                    url = "https://input.fontbureau.com/download/index.html?customize&fontSelection=fourStyleFamily&regular=InputMonoNarrow-Regular&italic=InputMonoNarrow-Italic&bold=InputMonoNarrow-Bold&boldItalic=InputMonoNarrow-BoldItalic&a=0&g=0&i=topserif&l=serifs_round&zero=0&asterisk=height&braces=straight&preset=default&line-height=1.2&email=";
                    sha256 = "0nn41w2b6jvsbr3r4lfy4p8w2ssjmgdjzd1pbj7p0vmawjpvx2w8";
                  };
                  outputHash = "1w2i660dg04nyc6fc6r6sd3pw53h8dh8yx4iy6ccpii9gwjl9val";
                }));
              }
            ];
      
      in {
        packages = genAttrs systems mkPackages;
      })
      (let
        mkOverlays = system: [
          # mix-in all local packages, so they are available as pkgs.${packages-name}
          (final: prev: self.packages.${system})
      
          (final: prev: {
            stable = import inputs.nixpkgs-stable {
              inherit system;
              overlays = self.overlays.${system};
              config = { allowUnfree = true; };
            };
          })
          inputs.emacs-overlay.overlay
          (final: prev: {
            firefox = prev.firefox.override {
              extraNativeMessagingHosts = [ final.procreditbank-websigner ];
            };
          })
        ];
      in {
        overlays = genAttrs systems mkOverlays;
      })
    ];
}
