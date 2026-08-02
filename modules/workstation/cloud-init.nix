# Enable cloud-init so the NoCloud cidata drive (attached by the crossplane
# workstation-cloud-init.yaml snippet) is actually processed. Its write_files
# stanza drops the Tailscale authkey to /etc/tailscale/authkey, which the native
# tailscale module (tailscale.nix, authKeyFile) then uses to authenticate.
#
# Without this the image has no cloud-init at all, so the pushed key never lands
# and tailscaled-autoconnect races an empty key file and fails.
{ ... }:
{
  services.cloud-init = {
    enable = true;
    # Keep the image's existing DHCP networking; cloud-init here is only used to
    # write the authkey file, not to manage the network.
    network.enable = false;
    settings.datasource_list = [ "NoCloud" ];
  };

  # tailscaled-autoconnect reads /etc/tailscale/authkey; cloud-init must have
  # written it first. cloud-final is the last cloud-init stage, so ordering after
  # it guarantees write_files (an earlier stage) has completed.
  systemd.services.tailscaled-autoconnect = {
    after = [ "cloud-final.service" ];
    wants = [ "cloud-final.service" ];
  };
}
