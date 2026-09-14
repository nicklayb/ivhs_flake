{
  config,
  ...
}:
{
  config = {
    services.ivhs-broker = config.services.ivhs.broker;
  };
}
