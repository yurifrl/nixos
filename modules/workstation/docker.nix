# Docker for dev use (mirrors the foundry docker setup).
{ ... }:
{
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates = "weekly";
    };
  };
}
