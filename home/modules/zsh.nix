{ pkgs, ... }:

{

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --exclude={.git,.idea,.vscode,.sass-cache,node_modules,build}";

    defaultOptions = [
      "--layout=reverse"
      "--height 100"
      "--border"
      "--no-separator"
      "--bind 'alt-y:execute(echo -n {} | ${if pkgs.stdenv.isDarwin then "pbcopy" else "xclip -selection clipboard"})'"
    ];

  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.zsh = {
    initContent = ''
    ${if pkgs.stdenv.isLinux then ''
    if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ];then
      exec start-hyprland
    fi
    '' else ""}
    ${if pkgs.stdenv.isDarwin then ''
    # Darwin specific zsh init code
    eval "$(/opt/homebrew/bin/brew shellenv)"

    export HOMEBREW_API_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles/api"
    export HOMEBREW_BOTTLE_DOMAIN="https://mirrors.tuna.tsinghua.edu.cn/homebrew-bottles"
    export HOMEBREW_PIP_INDEX_URL="https://pypi.tuna.tsinghua.edu.cn/simple"
    '' else ""}

    zstyle ':completion:*:descriptions' format '[%d]'
    zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
    zstyle ':fzf-tab:*' default-color $'\033[34m'
    zstyle ':fzf-tab:*' switch-group ',' '.'
    zstyle ':fzf-tab:*' fzf-pad 4
    zstyle ':fzf-tab:*' fzf-flags --no-separator \
    --color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
    --color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
    --color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
    --color=selected-bg:#494D64 \
    --color=border:#6E738D,label:#CAD3F5

    # 修正 vi 模式下的 backspace 行为
    bindkey '^?' backward-delete-char
    '';

    enable = true;
    # 显式开启 vi 模式
    defaultKeymap = "viins";
    # 支持..返回上一级目录
    autocd = true;

    # 启用自动补全
    enableCompletion = true;
    # 启用自动建议 (输入时灰色提示)
    autosuggestion.enable = true;
    # 关闭语法高亮
    syntaxHighlighting.enable = false;

    # 别名设置
    shellAliases = {
      update = if pkgs.stdenv.isDarwin then "sudo -H darwin-rebuild switch --flake ." else "sudo nixos-rebuild switch --flake .";
      vim = "nvim";
      ls  = "eza";
      l   = "eza -l";
      la  = "eza -a";
      ll  = "eza -l";
      lla = "eza -la";
      cp  = "rsync -aP";
      cat = "bat --style=changes";
      cls = "clear";

      feh = "feh -F";
      bc  = "bc -ql";

      fetch = "fastfetch";
      kssh  = "kitten ssh";

      # git
      gl     = "git pull";
      gp     = "git push";
      gcmsg  = "git commit -m";
      gss    = "git status -s";
      gst    = "git status";
      gsw    = "git switch";
      gswc   = "git switch --create";
      gswm   = "git switch $(git_main_branch)";
      gswd   = "git switch $(git_develop_branch)";
      gm     = "git merge";
      gma    = "git merge --abort";
      gbr    = "git br";
      gcl    = "git clone";
      grv    = "git remote --verbose";

      datetime = "date '+%Y-%m-%d %H:%M:%S'";
    };

    # 历史记录配置
    history = {
      size = 10000;
      path = "$HOME/.zsh_history";

      # 忽略连续重复的命令 (setopt HIST_IGNORE_DUPS)
      ignoreDups = true;

      # 忽略以空格开头的命令 (setopt HIST_IGNORE_SPACE)
      ignoreSpace = true;

      # 多个终端会话共享历史 (setopt SHARE_HISTORY)
      share = true;

      # 立即写入历史文件，而不是等退出时 (setopt INC_APPEND_HISTORY)
      append = true;

      # 记录命令执行的时间戳 (对应 omz 的 history 格式)
      expireDuplicatesFirst = true;
    };


    plugins = [
      {
        name = "omz-sudo";
        src = pkgs.fetchFromGitHub {
          owner = "ohmyzsh";
          repo = "ohmyzsh";
          rev = "master";
          sha256 = "sha256-ZdimmwBKi9iBUQ8RLqzeKDhy1AAQm+bgd1E3IG0/e9I="; # 建议实际运行时根据报错更新 sha256
        };
        file = "plugins/sudo/sudo.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
      {
        name = "forgit";
        src = pkgs.zsh-forgit;
        file = "share/zsh/zsh-forgit/forgit.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.zsh-fast-syntax-highlighting;
        file = "share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh";
      }
    ];
  };

}
