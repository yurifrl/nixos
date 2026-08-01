# Single-node k3s (local Kubernetes). Uses its bundled containerd; runs
# alongside docker. --write-kubeconfig-mode makes /etc/rancher/k3s/k3s.yaml
# readable so kubectl works without sudo.
{ ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--write-kubeconfig-mode=0644";
  };

  # k3s API server.
  networking.firewall.allowedTCPPorts = [ 6443 ];
}
