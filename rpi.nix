{ pkgs, username, ... }:

{

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  services = {
    openssh = {
      enable = true;
      settings.PermitRootLogin = "yes";
    };

    ivhs = {
      enable = true;
      broker = {
        plex.host = "http://192.168.1.9:32400";
      };
    };
  };

  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  system.stateVersion = "26.05";
}
