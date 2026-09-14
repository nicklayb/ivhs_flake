{ username, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/vda";
  boot.loader.grub.useOSProber = true;

  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  services = {
    xserver.xkb = {
      layout = "ca";
      variant = "multix";
    };

    openssh.enable = true;

    ivhs = {
      enable = true;
      broker = {
        app_host = "http://192.168.1.163:4000";
        plex.host = "http://192.168.1.9:32400";
      };
    };
  };

  console = {
    useXkbConfig = true;
  };

  users.users."${username}" = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];

    shell = pkgs.zsh;

    packages = with pkgs; [
      clang
    ];
  };

  programs.zsh.enable = true;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    fzf
    selene
    stylua
  ];

  nix.settings.experimental-features = [
    "flakes"
    "nix-command"
  ];

  virtualisation.docker.enable = true;

  system.stateVersion = "26.05"; # Did you read the comment?
}
