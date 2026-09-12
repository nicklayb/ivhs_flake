{ pkgs, ... }:

{

  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  networking.hostName = "ivhs-pi";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  users.users.nixos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };

  system.stateVersion = "26.05";
}
