# Single-node k3s (local Kubernetes). Uses its bundled containerd; runs
# alongside docker. --write-kubeconfig-mode makes /etc/rancher/k3s/k3s.yaml
# readable so kubectl works without sudo.
#
# --flannel-iface pins the pod network to the primary NIC so flannel binds
# deterministically even when the LAN address changes via DHCP.
# --disable-network-policy drops the kube-router network-policy controller,
# which hard-crashes ("failed to find interface with specified node ip") when
# the node's stored IP drifts from the current DHCP lease. NetworkPolicy
# enforcement is meaningless on a single-node dev cluster, so removing it
# eliminates that entire crash-loop failure mode.
{ ... }:
{
  services.k3s = {
    enable = true;
    role = "server";
    extraFlags = "--write-kubeconfig-mode=0644 --flannel-iface=ens18 --disable-network-policy";
  };

  # Point every shell at the local cluster so `kubectl` works without setup.
  # environment.variables (not sessionVariables) so it reaches fish too.
  environment.variables.KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";

  # k3s API server.
  networking.firewall.allowedTCPPorts = [ 6443 ];
}
