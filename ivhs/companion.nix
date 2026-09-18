{
  config,
  ...
}:
{
  config = {
    services.ivhs-companion = config.services.ivhs.companion;
  };
}
