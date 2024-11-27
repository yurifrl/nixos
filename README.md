# Home Systems

## Quick Start

```bash
ssh nixos@100.70.133.100

# Switch configuration on Pi
sudo nixos-rebuild switch --flake .#rpi --impure --show-trace

# Set up kubectl aliases and permissions
alias k=kubectl
set -gx KUBECONFIG /etc/rancher/k3s/k3s.yaml
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
k get nodes

# Set up 1Password access
op item get "Home Server" --fields "private key" --reveal > secrets/id_ed25519

# Copy your id_ed25519 to the pi and clone this repo

# Add unstable channel
sudo nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
sudo nix-channel --update
```

## References

### Sample Configurations
- [ymgyt/mynix](https://github.com/ymgyt/mynix/blob/main/homeserver/modules/kubernetes/master.nix)
- [heywoodlh/nixos-configs](https://github.com/heywoodlh/nixos-configs/blob/master/nixos/roles/kubevirt-master.nix)
- [JD95/nixos-configuration](https://github.com/JD95/nixos-configuration/blob/main/containers/kube-master/flake.nix)

### Additional Resources
- [BMC API Documentation](https://docs.turingpi.com/docs/turing-pi2-bmc-api#flash--firmware)
- [Storage Options](https://docs.turingpi.com/docs/turing-pi2-kubernetes-cluster-storage#option-2-the-longhorn)
- [Multicast DNS](https://en.wikipedia.org/wiki/Multicast_DNS)
- [Zero-configuration networking](https://en.wikipedia.org/wiki/Zero-configuration_networking#DNS-SD)