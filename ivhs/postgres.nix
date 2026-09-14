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
      enableTCPIP = true;
      ensureDatabases = [ cfg.postgres.databaseName ];
      ensureUsers = [
        {
          name = cfg.postgres.databaseName;
          ensureDBOwnership = true;
          ensureClauses = {
            password = cfg.postgres.password;
            createdb = true;
            createrole = true;
          };
        }
      ];
      authentication = pkgs.lib.mkOverride 10 ''
        # TYPE  DATABASE        USER            ADDRESS                 METHOD
        local   all             all                                     trust
        host    all             all             127.0.0.1/32            trust
        host    all             all             ::1/128                 trust
      '';
    };
  };
}
