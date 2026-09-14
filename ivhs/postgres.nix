{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ivhs;
in
{
  config = lib.mkIf cfg.postgres.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_18;
      authentication = lib.mkOverride 10 [
        {
          type = "local";
          database = cfg.postgres.databaseName;
          user = "postgres";
          method = "trust";
        }
        {
          type = "local";
          database = cfg.postgres.databaseName;
          user = cfg.postgres.databaseName;
          method = "md5";
        }
      ];
      initialScript = ''
        CREATE USER ${cfg.postgres.databaseName} WITH PASSWORD '${cfg.postgres.password}';
        CREATE DATABASE ${cfg.postgres.databaseName} OWNER ${cfg.postgres.databaseName};
      '';
    };
  };
}
