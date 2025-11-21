# Deployment Checklist

Complete guide to deploy both Gatus and Foundry VTT from scratch.

## Prerequisites

- [ ] Foundry VTT license purchased from https://foundryvtt.com
- [ ] DigitalOcean account with API token
- [ ] Cloudflare account with domains (syscd.live, syscd.tech)
- [ ] Tailscale account configured
- [ ] 1Password CLI installed and authenticated (`op signin`)
- [ ] This repository cloned locally

---

## Phase 1: Cloudflare Tunnels

### 1.1 Install Cloudflare CLI

```bash
# macOS
brew install cloudflare/cloudflare/cloudflared

# Or download from
# https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/downloads/
```

### 1.2 Create Foundry Tunnel

```bash
# Login to Cloudflare
cloudflared tunnel login

# Create the Foundry tunnel
cloudflared tunnel create foundry

# You'll see output like:
# Created tunnel foundry with id XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX
```

**Save this information**:
- Tunnel ID: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX`
- Credentials file: `~/.cloudflared/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.json`

### 1.3 Update Foundry Module

Edit `modules/foundry/cloudflared.nix` and replace the placeholder:

```nix
# Line 14: Replace this
"foundry-tunnel-id-placeholder" = {

# With your actual tunnel ID
"XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX" = {
```

### 1.4 Configure Cloudflare DNS

In Cloudflare dashboard (dash.cloudflare.com):

**For syscd.live domain** (public access):
- Add CNAME: `rpg` → `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.cfargotunnel.com`

**Note**: `.tech` domains are Tailscale-only, no Cloudflare tunnel needed

### 1.5 Route the Tunnel

```bash
# Configure the tunnel route (only .live domain)
cloudflared tunnel route dns 8bc2858c-a6a4-474f-9287-5af2c1928578 rpg.syscd.live
```

---

## Phase 2: 1Password Secrets

### 2.1 Check Existing Secrets

```bash
# List existing items
op item list --vault kubernetes

# Check if nixos item exists
op item get nixos --vault kubernetes
```

### 2.2 Add Foundry Secrets

You need to add these fields to the `nixos` item in 1Password:

```bash
# 1. Foundry license key
op item edit nixos --vault kubernetes \
  "foundry-license.key[password]=$(cat /path/to/your/foundry-license.txt)"

# 2. Foundry admin key (choose a strong password)
op item edit nixos --vault kubernetes \
  "foundry-admin.key[password]=YOUR_SECURE_ADMIN_PASSWORD"

# 3. Foundry Cloudflare tunnel credentials
op item edit nixos --vault kubernetes \
  "foundry-cloudflared-tunnel.json[document]=$(cat ~/.cloudflared/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX.json)"
```

### 2.3 Update Gatus Cloudflare Credentials (if needed)

```bash
# If you don't have the Gatus tunnel credentials stored yet
op item edit nixos --vault kubernetes \
  "gatus-cloudflared-creds.json[document]=$(cat /path/to/gatus/tunnel/credentials.json)"
```

---

## Phase 3: Build Images

### 3.1 Commit Cloudflare Tunnel ID

```bash
# Stage your changes
git add modules/foundry/cloudflared.nix

# Commit
git commit -m "chore: add foundry cloudflare tunnel ID"

# Push to trigger initial build
git push
```

This will trigger a build because of the path filter (`modules/**`), but won't create a release yet.

### 3.2 Trigger Release Builds

```bash
# Bump Gatus to trigger release
echo "1.0.0" > gatus.version
git add gatus.version
git commit -m "chore: gatus initial release v1.0.0"
git push

# Bump Foundry to trigger release
echo "1.0.0" > foundry.version
git add foundry.version
git commit -m "chore: foundry initial release v1.0.0"
git push
```

### 3.3 Monitor Build

```bash
# Watch GitHub Actions
# https://github.com/yurifrl/nixos/actions

# Wait for both builds to complete
# You'll see:
# - nixos-gatus-YYYYMMDD-HHMMSS uploaded
# - nixos-foundry-YYYYMMDD-HHMMSS uploaded
# - Releases: gatus-v1.0.0 and foundry-v1.0.0 created
```

---

## Phase 4: Create DigitalOcean Infrastructure

### 4.1 Install doctl

```bash
# macOS
brew install doctl

# Authenticate
doctl auth init
# Enter your DigitalOcean API token
```

### 4.2 Find Custom Images

```bash
# List custom images
doctl compute image list-user

# You should see:
# - nixos-gatus-YYYYMMDD-HHMMSS
# - nixos-foundry-YYYYMMDD-HHMMSS
```

### 4.3 Create Gatus Droplet

```bash
# Get image ID
GATUS_IMAGE_ID=$(doctl compute image list-user --format ID,Name --no-header | grep nixos-gatus | sort -r | head -1 | awk '{print $1}')

# Create droplet (1GB is enough for Gatus)
doctl compute droplet create gatus-monitor \
  --image $GATUS_IMAGE_ID \
  --region nyc1 \
  --size s-1vcpu-1gb \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header) \
  --wait

# Get the IP
GATUS_IP=$(doctl compute droplet get gatus-monitor --format PublicIPv4 --no-header)
echo "Gatus IP: $GATUS_IP"
```

### 4.4 Create Foundry Droplet

```bash
# Get image ID
FOUNDRY_IMAGE_ID=$(doctl compute image list-user --format ID,Name --no-header | grep nixos-foundry | sort -r | head -1 | awk '{print $1}')

# Create droplet (2GB minimum for Foundry)
doctl compute droplet create foundry-vtt \
  --image $FOUNDRY_IMAGE_ID \
  --region nyc1 \
  --size s-2vcpu-2gb \
  --ssh-keys $(doctl compute ssh-key list --format ID --no-header) \
  --wait

# Get the IP
FOUNDRY_IP=$(doctl compute droplet get foundry-vtt --format PublicIPv4 --no-header)
echo "Foundry IP: $FOUNDRY_IP"
```

### 4.5 Create and Attach Foundry Volume

```bash
# Create 50GB volume
doctl compute volume create foundry-data \
  --region nyc1 \
  --size 50GiB \
  --fs-type ext4

# Get volume ID
VOLUME_ID=$(doctl compute volume list --format ID,Name --no-header | grep foundry-data | awk '{print $1}')

# Get Foundry droplet ID
FOUNDRY_DROPLET_ID=$(doctl compute droplet get foundry-vtt --format ID --no-header)

# Attach volume
doctl compute volume-action attach $VOLUME_ID $FOUNDRY_DROPLET_ID --wait

echo "✅ Volume attached to Foundry droplet"
```

---

## Phase 5: Configure Tailscale

### 5.1 Wait for Droplets to Boot

```bash
# Wait ~60 seconds for droplets to fully boot and Tailscale to connect

# Check Tailscale status
tailscale status

# You should see (after ~1 minute):
# gatus.tailcecc0.ts.net
# rpg.tailcecc0.ts.net
```

### 5.2 Get Tailscale Hostnames

```bash
# List Tailscale devices
tailscale status --json | jq -r '.Peer[] | .HostName'

# Or check in Tailscale admin console:
# https://login.tailscale.com/admin/machines
```

---

## Phase 6: Update deploy.json

### 6.1 Create deploy.json

Create a file with your actual IPs and Tailscale hostnames:

```json
{
  "nodes": {
    "gatus": {
      "hostname": "YOUR_GATUS_IP",
      "tailscaleHostname": "gatus.tailcecc0.ts.net",
      "sshUser": "root"
    },
    "foundry": {
      "hostname": "YOUR_FOUNDRY_IP",
      "tailscaleHostname": "rpg.tailcecc0.ts.net",
      "sshUser": "root"
    }
  }
}
```

Replace `YOUR_GATUS_IP` and `YOUR_FOUNDRY_IP` with the actual IPs from step 4.3 and 4.4.

### 6.2 Store in 1Password

```bash
# Save to 1Password
op item edit nixos --vault kubernetes \
  "deploy.json[document]=$(cat deploy.json)"

# Verify
op read "op://kubernetes/nixos/deploy.json"
```

---

## Phase 7: Load Secrets to Servers

### 7.1 Load Build Secrets Locally

```bash
# This downloads deploy.json to your local machine
task load-build-secrets

# Verify
cat deploy.json
```

### 7.2 Load Gatus Runtime Secrets

```bash
# This uploads secrets to the Gatus droplet
task load-secrets-gatus

# What it does:
# - Uploads tailscale-auth.key to /etc/tailscale/
# - Uploads cloudflared credentials to /etc/cloudflared/
# - Uploads gatus.env to /etc/gatus/
```

### 7.3 Load Foundry Runtime Secrets

```bash
# This uploads secrets to the Foundry droplet
task load-secrets-foundry

# What it does:
# - Uploads tailscale-auth.key to /etc/tailscale/
# - Uploads foundry tunnel credentials to /etc/cloudflared/
# - Uploads foundry license to /etc/foundry/
# - Uploads foundry admin key to /etc/foundry/
```

---

## Phase 8: Deploy Configurations

### 8.1 Deploy to Both Servers

```bash
# Deploy NixOS configurations to both droplets
task nix-deploy

# This will:
# 1. Build configurations locally
# 2. Copy to remote servers via SSH
# 3. Activate new system configuration
# 4. Restart services
```

**Or deploy individually**:
```bash
# Deploy only Gatus
task nix-deploy-gatus

# Deploy only Foundry
task nix-deploy-foundry
```

### 8.2 Monitor Deployment

Watch the services come online:

```bash
# Gatus logs
ssh root@gatus.tailcecc0.ts.net journalctl -u gatus -f

# Foundry logs
ssh root@rpg.tailcecc0.ts.net journalctl -u foundry -f

# Tailscale logs (both)
ssh root@gatus.tailcecc0.ts.net journalctl -u tailscale-autoconnect -f
```

---

## Phase 9: Verification

### 9.1 Check Services

```bash
# Check Gatus
curl -I https://gatus.syscd.live
curl -I https://up.syscd.live

# Check Foundry
curl -I https://rpg.syscd.live

# Or visit in browser
open https://gatus.syscd.live
open https://rpg.syscd.live
```

### 9.2 Verify Tailscale

```bash
# Ping via Tailscale
ping gatus.tailcecc0.ts.net
ping rpg.tailcecc0.ts.net

# Check direct access
curl http://gatus.tailcecc0.ts.net:8080
curl http://rpg.tailcecc0.ts.net:30000
```

### 9.3 Check Foundry Volume

```bash
# SSH to Foundry
ssh root@rpg.tailcecc0.ts.net

# Verify volume is mounted
df -h | grep foundry-data
# Should show: /dev/sda mounted at /mnt/foundry-data (50GB)

# Check permissions
ls -la /mnt/foundry-data
# Should be owned by 1000:1000 (foundry user)

# Check Docker container
docker ps
# Should show: felddy/foundryvtt:release running on port 30000
```

---

## Troubleshooting

### If Tailscale doesn't connect:

```bash
# SSH using IP address first
ssh root@YOUR_DROPLET_IP

# Check Tailscale service
systemctl status tailscale-autoconnect
journalctl -u tailscale-autoconnect -n 50

# Manually connect
tailscale up --authkey $(cat /etc/tailscale/tailscale-auth.key) --accept-dns --accept-routes
```

### If Cloudflare tunnel doesn't work:

```bash
# Check tunnel status
ssh root@rpg.tailcecc0.ts.net systemctl status cloudflared-tunnel-*

# Check tunnel logs
ssh root@rpg.tailcecc0.ts.net journalctl -u cloudflared-tunnel-* -f

# Verify credentials exist
ssh root@rpg.tailcecc0.ts.net cat /etc/cloudflared/foundry-tunnel.json
```

### If Foundry won't start:

```bash
# Check service
ssh root@rpg.tailcecc0.ts.net systemctl status foundry

# Check Docker logs
ssh root@rpg.tailcecc0.ts.net docker logs foundry

# Verify secrets exist
ssh root@rpg.tailcecc0.ts.net ls -la /etc/foundry/
ssh root@rpg.tailcecc0.ts.net cat /etc/foundry/license-key
```

---

## Quick Reference

### Environment Variables Needed

Add these to your `.env` (via `task load-envs` or manually):

```bash
# Gatus Droplet
GATUS_DROPLET_IP=xxx.xxx.xxx.xxx
GATUS_DROPLET_USER=root

# Foundry Droplet
FOUNDRY_DROPLET_IP=xxx.xxx.xxx.xxx
FOUNDRY_DROPLET_USER=root
```

### 1Password Structure

Your `kubernetes/nixos` item should have:

**Build secrets**:
- `deploy.json` - Node configuration

**Gatus secrets**:
- `tailscale-auth.key` - Shared Tailscale key
- `gatus-cloudflared-creds.json` - Gatus tunnel credentials
- `gatus.env` - Environment variables (CF_ACCESS_CLIENT_ID, etc.)

**Foundry secrets**:
- `foundry-cloudflared-tunnel.json` - Foundry tunnel credentials
- `foundry-license.key` - Your Foundry license
- `foundry-admin.key` - Admin password

### Task Commands

```bash
task load-build-secrets       # Download deploy.json locally
task load-secrets-gatus       # Upload Gatus secrets to server
task load-secrets-foundry     # Upload Foundry secrets to server
task nix-deploy-gatus         # Deploy Gatus configuration
task nix-deploy-foundry       # Deploy Foundry configuration
task nix-deploy               # Deploy both
```

---

## Success Criteria

When everything is working:

- ✅ `https://gatus.syscd.live` shows Gatus monitoring dashboard
- ✅ `https://rpg.syscd.live` shows Foundry VTT login page
- ✅ Both services accessible via Tailscale hostnames
- ✅ GitHub releases exist: `gatus-v1.0.0` and `foundry-v1.0.0`
- ✅ Foundry has 50GB volume mounted and accessible
- ✅ All systemd services running: `systemctl status gatus foundry cloudflared tailscale`

---

## Next Steps After Deployment

1. **Configure Foundry**: Login to https://rpg.syscd.live with admin key
2. **Update Gatus config**: Edit `modules/gatus/config.yaml` if needed
3. **Setup backups**: Schedule volume snapshots in DigitalOcean
4. **Monitor costs**: Check DigitalOcean billing (~$23/month expected)
5. **Test failover**: Verify services restart after droplet reboot
