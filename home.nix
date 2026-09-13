{
  stateVersion,
  inputs,
  username,
  ...
}:
{
  imports = [
    inputs.astronvim-config.homeManagerModules.default
  ];

  programs.home-manager.enable = true;
  home = {
    username = "${username}";
    stateVersion = stateVersion;
    sessionVariables = {
      EDITOR = "nvim";
    };
  };
  astronvim.features.copilot = false;
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "fzf"
        "web-search"
      ];
      theme = "sunaku";
    };
    initContent = ''
      source ~/.zsh/init || true
      if [[ -n "$SSH_CONNECTION" ]] && [[ "$PROMPT" != *'(%m)'* ]]; then
        PROMPT="%F{yellow}(%m) %f$PROMPT"
      fi
    '';
  };
}
