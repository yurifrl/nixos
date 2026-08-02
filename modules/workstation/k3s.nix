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

  # Point every login shell at the local cluster so `kubectl` works without setup.
  environment.sessionVariables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  # k3s API server.
  networking.firewall.allowedTCPPorts = [ 6443 ];
}
