{ ... }:

{
  imports = [
    ./kubeadm.nix
  ];

  kubeadm.enable = true;
  kubeadm.role = "master";
  kubeadm.apiserverAddress = "192.168.68.106";
  kubeadm.bootstrapToken = "8tipwo.tst0nvf7wcaqjcj0";
  kubeadm.discoveryTokenCaCertHash = "sha256:c3e9efd010c793d2c983ea17f1e7f9346adf6018d524db0793bf550e39b1a402";
  kubeadm.nodeip = "192.168.68.106";
}