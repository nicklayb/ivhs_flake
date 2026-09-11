{
  config,
  pkgs,
  lib,
  stateVersion,
  ...
}:
{
  config = lib.mkIf (config.services.ivhs.player.windowManager == "labwc") {
    users.users.ivhs = {
      isNormalUser = true;
      description = "iVHS Player";
      extraGroups = [
        "video"
        "input"
        "audio"
      ];
      shell = pkgs.bash;
    };

    home-manager.users.ivhs.home.stateVersion = stateVersion;

    programs.labwc.enable = true;

    programs.xwayland.enable = true;

    services.greetd = {
      enable = true;

      settings = {
        initial_session = {
          command = "${pkgs.labwc}/bin/labwc";
          user = "ivhs";
        };

        default_session = {
          command = "${pkgs.labwc}/bin/labwc";
          user = "ivhs";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      labwc
      xwayland

      xterm

      wayland-utils
      wl-clipboard

      # mpv
      # vlc
      # snes9x
    ];

    environment.etc."xdg/labwc/rc.xml".text = ''
      <?xml version="1.0"?>
      <labwc_config>

        <core>
          <decoration>no</decoration>
          <xwaylandPersistence>yes</xwaylandPersistence>
        </core>

        <keyboard>
        </keyboard>

        <mouse>
        </mouse>
        <theme>
          <titlebar>
            <show>no</show>
          </titlebar>
        </theme>

        <windowRules>
          <windowRule identifier="*">
            <maximized>yes</maximized>
            <decorated>no</decorated>
          </windowRule>
        </windowRules>

      </labwc_config>
    '';

    environment.etc."xdg/labwc/autostart" = {
      text = ''
        #!/bin/sh

        exec ${pkgs.xterm}/bin/xterm
      '';
      mode = "0755";
    };

    services.pipewire = {
      enable = true;

      alsa.enable = true;
      alsa.support32Bit = true;

      pulse.enable = true;
    };

    hardware.bluetooth.enable = true;

    boot.kernelParams = [
      "console=tty1"
    ];

    # No login screen
    services.getty.autologinUser = null;
  };
}
