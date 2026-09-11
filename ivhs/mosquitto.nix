{
  config,
  lib,
  ...
}:
let
  cfg = config.services.ivhs;
in
{
  config = lib.mkIf cfg.mqtt.enable {
    services.mosquitto = {
      enable = true;
      listeners = [
        {
          port = cfg.mqtt.port;
          users.${cfg.mqtt.username} = {
            acl = [ "readwrite ivhs/#" ];
            password = cfg.mqtt.password;
          };
        }
      ];
    };
  };
}
