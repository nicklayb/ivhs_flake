{
  config,
  internalDockerHostname,
  pkgs,
  lib,
  ...
}:
let
  networkName = "ivhs";
  postgresVolume = "ivhs-postgres";
  ivhsServiceName = "docker-ivhs";
  databaseServiceName = "docker-postgres";
  cfg = config.services.ivhs;
in
{
  config = lib.mkIf cfg.enable {
    systemd.services."oci-ivhs-setup" = {
      description = "Create IVHS OCI requirements";
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script = ''
        ${pkgs.docker}/bin/docker network inspect ${networkName} > /dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker network create ${networkName}

        ${pkgs.docker}/bin/docker volume inspect ${postgresVolume} > /dev/null 2>&1 || \
        ${pkgs.docker}/bin/docker volume create ${postgresVolume}
      '';
    };

    virtualisation = {
      docker.enable = true;
      oci-containers = {
        backend = "docker";

        containers = {
          postgres = lib.mkIf cfg.postgres.enable {
            autoStart = true;
            serviceName = databaseServiceName;
            hostname = "ivhspostgres";
            image = "postgres:18.3";
            ports = [ "5432:5432" ];
            networks = [ networkName ];
            volumes = [
              "${postgresVolume}:/var/lib/postgresql"
            ];
            environment = {
              POSTGRES_PASSWORD = cfg.postgres.password;
              POSTGRES_DB = cfg.postgres.databaseName;
            };
          };
          ivhs_broker = lib.mkIf cfg.broker.enable {
            autoStart = true;
            serviceName = ivhsServiceName;
            hostname = "ivhs-broker";
            image = "nboisvert/ivhs_broker:${cfg.broker.version}";
            ports = [ "${toString cfg.broker.port}:4000" ];
            networks = [ networkName ];
            extraOptions = [
              "--add-host=${internalDockerHostname}:host-gateway"
            ];
            environment = {
              SECRET_KEY_BASE = cfg.broker.secretKeyBase;
              LIVE_VIEW_SALT = cfg.broker.liveViewSalt;
              APP_HOST = cfg.broker.app_host;
              LOGGER_LEVEL = cfg.broker.loggerLevel;
              EMITTER_DEBOUNCE = toString cfg.broker.emitterDebounce;

              DATABASE_PATH = cfg.broker.database_url;

              # MQTT configuration
              MQTT_HOST = cfg.broker.mqtt.host;
              MQTT_PORT = toString cfg.broker.mqtt.port;
              MQTT_CLIENT_ID = cfg.broker.mqtt.clientId;
              MQTT_USERNAME = cfg.broker.mqtt.username;
              MQTT_PASSWORD = cfg.broker.mqtt.password;

              # Plex configuration
              PLEX_HOST = cfg.broker.plex.host;
              PLEX_TOKEN = cfg.broker.plex.token;
            };
          };
        };
      };
    };
  };
}
