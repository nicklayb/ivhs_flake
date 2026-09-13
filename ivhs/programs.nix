{
  config,
  pkgs,
  lib,
  ...
}:
let
  snes = lib.optionals config.services.ivhs.programs.snes.enable [ pkgs.bsnes-hd ];
  mpv = lib.optionals config.services.ivhs.programs.mpv.enable [ pkgs.mpv ];
  programs = snes ++ mpv;
in
{
  config = {
    environment.systemPackages = programs;
  };
}
