# Foundry VTT Deployment Guide

This document describes the Foundry Virtual Tabletop (Foundry VTT) deployment in this NixOS repository.

## Overview

The Foundry VTT deployment uses:
- **Container**: `felddy/foundryvtt:release` Docker image
- **Storage**: 50GB DigitalOcean Block Storage volume mounted at `/mnt/foundry-data`
- **Networking**: Tailscale VPN + Cloudflare Tunnel for public access
- **Domains**:
  - `foundry.syscd.live` (public access)
  - `foundry.syscd.tech` (public access)
  - Tailscale hostname for admin access

## Architecture

```
Internet → Cloudflare Tunnel → localhost:30000 (Foundry Container)
                                       ↓
                              /mnt/foundry-data (50GB Volume)
```

## Prerequisites

Before deploying Foundry, you need:

1. **Foundry VTT License Key** - Purchase from https://foundryvtt.com
2. **DigitalOcean Account** - For droplet and block storage
3. **Cloudflare Tunnel** - Create a new tunnel for Foundry
4. **Tailscale Network** - For VPN access
5. **1Password Vault** - For secrets management

## Initial Setup

### 1. Create Cloudflare Tunnel

```bash
# Install cloudflared CLI
# Visit: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/

# Login to Cloudflare
cloudflared tunnel login

# Create the Foundry tunnel
cloudflared tunnel create foundry

# Copy the tunnel ID (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
# Save the credentials JSON file
```

### 2. Update Foundry Cloudflare Module

Edit `modules/foundry/cloudflared.nix` and replace `foundry-tunnel-id-placeholder` with your actual tunnel ID:

```nix
"YOUR-TUNNEL-ID-HERE" = {
  credentialsFile = "/etc/cloudflared/foundry-tunnel.json";
  ingress = {
    "foundry.syscd.live" = "http://localhost:30000";
    "foundry.syscd.tech" = "http://localhost:30000";
  };
  default = "http_status:404";
};
```

### 3. Configure DNS

In Cloudflare DNS, add CNAME records:
- `foundry.syscd.live` → `YOUR-TUNNEL-ID.cfargotunnel.com`
- `foundry.syscd.tech` → `YOUR-TUNNEL-ID.cfargotunnel.com`

### 4. Store Secrets in 1Password

Create the following items in your `kubernetes/nixos` vault:

1. **foundry-license.key** - Your Foundry VTT license key
2. **foundry-admin.key** - Admin password for Foundry setup
3. **foundry-cloudflared-tunnel.json** - Cloudflare tunnel credentials JSON

### 5. Build Foundry Image

```bash
# Bump Foundry version to trigger build + release
echo "1.0.0" > foundry.version
git add foundry.version
git commit -m "chore: initial foundry release v1.0.0"
git push

# GitHub Actions will automatically:
# 1. Build nixos-foundry-YYYYMMDD-HHMMSS image
# 2. Upload to DigitalOcean custom images
# 3. Create GitHub release: foundry-v1.0.0
```

### 6. Create DigitalOcean Droplet

```bash
# Create droplet from custom image in DO dashboard
# - Select the "nixos-foundry-YYYYMMDD-HHMMSS" custom image
# - Choose size: at least 2GB RAM recommended
# - Add your SSH key
```

### 7. Create and Attach Block Storage

```bash
# In DigitalOcean dashboard or via doctl:
doctl compute volume create foundry-data \
  --region nyc1 \
  --size 50GiB \
  --fs-type ext4

# Attach to droplet
doctl compute volume-action attach <volume-id> <droplet-id>
```

**Important**: The volume will be attached as `/dev/disk/by-id/scsi-0DO_Volume_foundry-data`.
This path is already configured in `configuration-foundry.nix`.

### 8. Update deploy.json

Add Foundry node configuration:

```json
{
  "nodes": {
    "gatus": {
      "hostname": "gatus-droplet-ip",
      "tailscaleHostname": "gatus.tailcecc0.ts.net",
      "sshUser": "root"
    },
    "foundry": {
      "hostname": "foundry-droplet-ip",
      "tailscaleHostname": "foundry.tailcecc0.ts.net",
      "sshUser": "root"
    }
  }
}
```

Save to 1Password: `op://kubernetes/nixos/deploy.json`

### 9. Load Secrets and Deploy

```bash
# Load build secrets
task secrets:load:build

# Load Foundry runtime secrets
task secrets:load:foundry

# Deploy Foundry configuration
task nix:deploy:foundry
```

## Configuration

### Foundry Environment Variables

The Foundry container is configured with:

- `FOUNDRY_ADMIN_KEY` - Admin password from `/etc/foundry/admin-key`
- `FOUNDRY_LICENSE_KEY` - License key from `/etc/foundry/license-key`
- `FOUNDRY_HOSTNAME` - Set to `foundry.syscd.live`
- `FOUNDRY_PROXY_SSL` - Enabled (true)
- `FOUNDRY_PROXY_PORT` - 443
- `CONTAINER_CACHE` - `/data/container_cache`

### Volume Mount

The 50GB block storage is mounted at `/mnt/foundry-data` and mapped to `/data` inside the container.

This stores:
- Foundry application data
- Worlds and scenes
- Modules and systems
- Asset library (images, audio, etc.)

## Maintenance

### Updating Foundry

The Docker image automatically pulls the `:release` tag. To update:

```bash
# SSH to Foundry server
ssh root@foundry.tailcecc0.ts.net

# Restart the Foundry service (will pull latest image)
systemctl restart foundry
```

### Checking Logs

```bash
# View Foundry service logs
ssh root@foundry.tailcecc0.ts.net journalctl -u foundry -f

# View Docker container logs
ssh root@foundry.tailcecc0.ts.net docker logs -f foundry
```

### Backup and Restore

#### Backup

```bash
# SSH to Foundry server
ssh root@foundry.tailcecc0.ts.net

# Stop Foundry service
systemctl stop foundry

# Create backup
tar czf /tmp/foundry-backup-$(date +%Y%m%d).tar.gz /mnt/foundry-data

# Start Foundry service
systemctl start foundry

# Download backup
scp root@foundry.tailcecc0.ts.net:/tmp/foundry-backup-*.tar.gz ./backups/
```

#### Restore

```bash
# SSH to Foundry server
ssh root@foundry.tailcecc0.ts.net

# Stop Foundry service
systemctl stop foundry

# Upload backup
scp ./backups/foundry-backup-YYYYMMDD.tar.gz root@foundry.tailcecc0.ts.net:/tmp/

# Extract backup
tar xzf /tmp/foundry-backup-YYYYMMDD.tar.gz -C /

# Fix permissions
chown -R 1000:1000 /mnt/foundry-data

# Start Foundry service
systemctl start foundry
```

### Volume Snapshots

Use DigitalOcean snapshots for quick backups:

```bash
# Create snapshot
doctl compute volume-action snapshot <volume-id> --snapshot-name "foundry-backup-$(date +%Y%m%d)"

# List snapshots
doctl compute volume-snapshot list

# Restore from snapshot (requires new volume creation)
doctl compute volume create foundry-data-restored \
  --snapshot <snapshot-id> \
  --region nyc1
```

## Troubleshooting

### Foundry Won't Start

1. Check service status:
   ```bash
   ssh root@foundry.tailcecc0.ts.net systemctl status foundry
   ```

2. Check Docker container:
   ```bash
   ssh root@foundry.tailcecc0.ts.net docker ps -a
   ```

3. Check logs:
   ```bash
   ssh root@foundry.tailcecc0.ts.net journalctl -u foundry -n 100
   ```

### Volume Not Mounted

1. Check volume attachment:
   ```bash
   ssh root@foundry.tailcecc0.ts.net ls -la /dev/disk/by-id/
   ```

2. Check filesystem mount:
   ```bash
   ssh root@foundry.tailcecc0.ts.net df -h /mnt/foundry-data
   ```

3. If not mounted, check fstab and remount:
   ```bash
   ssh root@foundry.tailcecc0.ts.net mount -a
   ```

### Can't Access via Cloudflare

1. Check Cloudflare tunnel status:
   ```bash
   ssh root@foundry.tailcecc0.ts.net systemctl status cloudflared
   ```

2. Verify DNS records in Cloudflare dashboard

3. Test local access via Tailscale:
   ```bash
   curl http://foundry.tailcecc0.ts.net:30000
   ```

### Permission Issues

If Foundry can't write to `/data`:

```bash
ssh root@foundry.tailcecc0.ts.net
chown -R 1000:1000 /mnt/foundry-data
chmod 755 /mnt/foundry-data
```

## Monitoring

Foundry is monitored by Gatus at:
- https://gatus.syscd.live
- https://up.syscd.live

The monitoring checks:
- HTTPS accessibility via `foundry.syscd.live`
- Response time
- HTTP status codes

## Cost Estimation

Monthly costs:
- **Droplet** (2GB RAM): ~$12/month
- **Block Storage** (50GB): ~$5/month
- **Bandwidth**: Included (1TB)
- **Backups** (optional): ~$1.20/month per snapshot

**Total**: ~$17-20/month

## Security Notes

1. **Firewall**: Only port 30000 is exposed locally; public access is via Cloudflare Tunnel
2. **Admin Access**: Use Tailscale VPN for SSH and management
3. **Secrets**: All sensitive data stored in 1Password, never committed to git
4. **Updates**: Regularly update Foundry via container restarts
5. **Backups**: Schedule regular backups and test restoration

## Resources

- [Foundry VTT Official Site](https://foundryvtt.com)
- [Foundry VTT Docker Image](https://github.com/felddy/foundryvtt-docker)
- [DigitalOcean Block Storage Docs](https://docs.digitalocean.com/products/volumes/)
- [Cloudflare Tunnel Docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
