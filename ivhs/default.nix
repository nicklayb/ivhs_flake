{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkOption =
    type: description: default:
    lib.mkOption {
      description = description;
      type = type;
      default = default;
    };
  mkStrOption = mkOption lib.types.str;
  mkBoolOption = mkOption lib.types.bool;
  mkIntOption = mkOption lib.types.int;
  defaultMqttPort = 1883;
  defaultBorkerPort = 4000;
  cfg = config.services.ivhs;
  internalDockerHostname = "host.docker.internal";
in
{
  options = {
    services.ivhs = {
      enable = lib.mkEnableOption "Enables IVHS";

      mqtt = {
        enable = mkBoolOption "Enables MQTT broker" true;
        port = mkIntOption "MQTT broker port" defaultMqttPort;
        username = mkStrOption "Sets MQTT username" "ivhs";
        password = mkStrOption "Sets MQTT password" "ivhs";
      };

      postgres = {
        enable = mkBoolOption "Enables Postgres Server" true;
        password = mkStrOption "Postgres's password" "postgres";
        databaseName = mkStrOption "Postgres's database name" "ivhs_broker";
      };

      broker = {
        enable = mkBoolOption "Enables IVHS Broker" true;
        port = mkIntOption "IVHS Port" defaultBorkerPort;
        name = mkStrOption "IVHS app name" "ivhs-app";
        version = mkStrOption "Broker version (docker image tag)" "latest";
        database_url = mkStrOption "Postgres database url" "postgresql://postgres:postgres@ivhspostgres/${cfg.postgres.databaseName}";
        secretKeyBase = mkStrOption "IVHS Secret key base" (
          builtins.hashString "sha256" "${cfg.broker.name}.secret_key_base"
        );
        liveViewSalt = mkStrOption "IVHS Secret key base" (
          builtins.hashString "sha256" "${cfg.broker.name}.live_view_salt"
        );
        app_host = mkStrOption "App's hostname" "http://localhost:${toString defaultBorkerPort}";
        loggerLevel = mkStrOption "Logger's level" "info";
        emitterDebounce = mkIntOption "Emitter's debounce" 1000;
        mqtt = {
          host = mkStrOption "MQTT Broker hostname" "${internalDockerHostname}";
          port = mkIntOption "MQTT Broker port" defaultMqttPort;
          clientId = mkStrOption "IVHS Broker client id on MQTT broker" "ivhs-player";
          username = mkStrOption "MQTT Broker username" cfg.mqtt.username;
          password = mkStrOption "MQTT Broker password" cfg.mqtt.password;
        };
        plex = {
          host = mkStrOption "Plex hostname" "";
          token = mkStrOption "Plex token" "";
        };
      };
    };
  };

  config =
    let
      networkName = "ivhs";
      postgresVolume = "ivhs-postgres";
      ivhsServiceName = "docker-ivhs";
      databaseServiceName = "docker-postgres";
      ports =
        (if cfg.mqtt.enable then [ cfg.mqtt.port ] else [ ])
        ++ (if cfg.broker.enable then [ cfg.broker.port ] else [ ]);
    in
    lib.mkIf cfg.enable {
      services.mosquitto = lib.mkIf cfg.mqtt.enable {
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

      networking.firewall = {
        allowedTCPPorts = ports;
      };
    };
}
