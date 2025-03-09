# Nixos image


journalctl -u tailscale-autoconnect -f
sudo systemctl restart  tailscale-autoconnect

journalctl -u tailscaled.service -f
sudo systemctl restart  tailscaled.service

journalctl -u cloudflared-tunnel-5ce2f91a-f98f-49d1-a966-5c0742f2bddc.service -f
sudo systemctl restart  cloudflared-tunnel-5ce2f91a-f98f-49d1-a966-5c0742f2bddc.service

## Digital Ocean Nixos Image
- [Deploying NixOS with flakes on Digital Ocean — lelgenio](https://blog.lelgenio.com/deploying-nixos-with-flakes-on-digital-ocean)
- [NixOS in the Cloud, step-by-step: part 1 · Justinas Stankevičius](https://justinas.org/nixos-in-the-cloud-step-by-step-part-1)
- [Remote Deployment | NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)
- [Managing NixOS on DigitalOcean with Colmena - DEV Community](https://dev.to/vst/managing-nixos-on-digitalocean-with-colmena-3jb6)
- [Jean-Charles Quillet - Deploying a static website with nix](https://jeancharles.quillet.org/posts/2023-08-01-Deploying-a-static-website-with-nix.html)
- [Deploying to DigitalOcean · nixos · Zulip Chat Archive](https://chat.nixos.asia/stream/413948-nixos/topic/Deploying.20to.20DigitalOcean.html)

