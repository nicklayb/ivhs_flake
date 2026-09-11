{
  config,
  pkgs,
  lib,
  ...
}:
let
  snes = if config.services.ivhs.programs.snes.enable then [ pkgs.snes9x ] else [ ];
  mpv = if config.services.ivhs.programs.mpv.enable then [ pkgs.mpv ] else [ ];
  programs = snes ++ mpv;
in
{
  config = {
    environment.systemPackages = programs;

    home-manager.users.ivhs.home.file.".snes9x/snes9x.conf".source = ./snes9x.conf;
  };
}
