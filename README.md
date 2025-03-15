# Nixos image


journalctl -u gatus.service -f
sudo systemctl restart  gatus.service

journalctl -u tailscale-autoconnect -f
sudo systemctl start  tailscale-autoconnect

journalctl -u tailscaled.service -f
sudo systemctl restart  tailscaled.service

journalctl -u cloudflared-tunnel-5ce2f91a-f98f-49d1-a966-5c0742f2bddc.service -f
sudo systemctl restart  cloudflared-tunnel-5ce2f91a-f98f-49d1-a966-5c0742f2bddc.service

Trobleshooting
```bash
nix-env -iA nixos.dnsutils nixos.inetutils tcpdump
```

## Digital Ocean Nixos Image
- [Deploying NixOS with flakes on Digital Ocean — lelgenio](https://blog.lelgenio.com/deploying-nixos-with-flakes-on-digital-ocean)
- [NixOS in the Cloud, step-by-step: part 1 · Justinas Stankevičius](https://justinas.org/nixos-in-the-cloud-step-by-step-part-1)
- [Remote Deployment | NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)
- [Managing NixOS on DigitalOcean with Colmena - DEV Community](https://dev.to/vst/managing-nixos-on-digitalocean-with-colmena-3jb6)
- [Jean-Charles Quillet - Deploying a static website with nix](https://jeancharles.quillet.org/posts/2023-08-01-Deploying-a-static-website-with-nix.html)
- [Deploying to DigitalOcean · nixos · Zulip Chat Archive](https://chat.nixos.asia/stream/413948-nixos/topic/Deploying.20to.20DigitalOcean.html)


# Setup new machine

- Create a tag and push it, `.github/workflows/build.yml` will build a new custom digital ocean image
- Use the newly created image to deploy a new machine
- Machine should be running
- Get the ip address of the machine and change it in `flake.nix` and in 1password
- run `task load-envs` to generate .env with credentials you need locally
- Run `task load-secrets` to send secrets to the machine
- machine should have secrets now
- Add the machine ip to `flake.nix`
- Make a deploy or run `docker compose up --rm deploy` to start the secrets
- You may remove the IP from `flake.nix` and use the `1password` hostname there
- To the pipeline to work, it need the know host,  you cant initialy add tailscale there because tailscale is not running in the begining