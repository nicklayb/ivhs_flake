{
  config,
  ...
}:
{
  config = {
    services.ivhs-companion = {
      enable = config.services.ivhs.companion.enable;
      device = config.services.ivhs.companion.device;
    };
  };
}
