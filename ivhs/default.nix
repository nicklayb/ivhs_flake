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
  mkEnumOption = options: mkOption (lib.types.enum options);
  defaultMqttPort = 1883;
  defaultBorkerPort = 4000;
  cfg = config.services.ivhs;
  internalDockerHostname = "host.docker.internal";
in
{

  imports = [
    ./labwc.nix
    ./mosquitto.nix
    ./programs.nix
    ./companion.nix
    # (import ./docker.nix {
    #   config = config;
    #   lib = lib;
    #   pkgs = pkgs;
    #   internalDockerHostname = internalDockerHostname;
    # })
  ];

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

      companion = {
        enable = mkBoolOption "Enables USB Companion app" true;
        device = {
          vendorId = mkStrOption "Device's vendor ID" "239a";
          productId = mkStrOption "Device's product ID" "8029";
        };
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

      player = {
        enable = mkBoolOption "Enables IVHS Player" true;
        windowManager = mkEnumOption [ "labwc" ] "Selects the window manager" "labwc";
      };

      programs = {
        snes.enable = mkBoolOption "Enables SNES program" true;
        mpv.enable = mkBoolOption "Enables MPV program" true;
      };
    };
  };

  config =
    let
      ports =
        (if cfg.mqtt.enable then [ cfg.mqtt.port ] else [ ])
        ++ (if cfg.broker.enable then [ cfg.broker.port ] else [ ]);
    in
    (lib.mkIf cfg.enable {

      networking.firewall = {
        allowedTCPPorts = ports;
      };
    });
}
