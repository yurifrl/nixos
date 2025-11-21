# NixOS Multi-Image Deployment

This repository manages NixOS configurations for two separate services deployed on DigitalOcean:

1. **Gatus** - Uptime monitoring and status page service
2. **Foundry VTT** - Virtual tabletop for running RPG games

Both services share common infrastructure (SSH, Tailscale VPN) but are deployed as separate images on separate droplets for independent scaling and management.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Repository                           │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐   │
│  │   Shared     │   │    Gatus     │   │   Foundry    │   │
│  │   Modules    │   │   Modules    │   │   Modules    │   │
│  ├──────────────┤   ├──────────────┤   ├──────────────┤   │
│  │ • SSH        │   │ • Gatus Svc  │   │ • Docker     │   │
│  │ • Tailscale  │   │ • Cloudflared│   │ • Foundry    │   │
│  └──────────────┘   └──────────────┘   │ • Cloudflared│   │
│                                        │ • Volume     │   │
│                                        └──────────────┘   │
└─────────────────────────────────────────────────────────────┘
           │                      │                 │
           ▼                      ▼                 ▼
    ┌─────────────┐      ┌─────────────┐   ┌─────────────┐
    │   Gatus     │      │  Foundry    │   │  DO Block   │
    │  Droplet    │      │  Droplet    │   │  Storage    │
    │             │      │             │   │  (50GB)     │
    │ :8080       │      │ :30000      │   └─────────────┘
    └─────────────┘      └─────────────┘
           │                      │
           └──────────┬───────────┘
                      │
              Tailscale VPN Mesh
```

## Repository Structure

```
.
├── gatus.version               # Gatus image version
├── foundry.version             # Foundry image version
├── modules/
│   ├── shared/                 # Shared infrastructure
│   │   ├── ssh.nix            # SSH configuration
│   │   └── tailscale.nix      # Tailscale VPN
│   ├── gatus/                  # Gatus monitoring
│   │   ├── default.nix        # Gatus service
│   │   ├── cloudflared.nix    # Cloudflare tunnel
│   │   └── config.yaml        # Monitoring config
│   └── foundry/                # Foundry VTT
│       ├── default.nix        # Docker-based service
│       └── cloudflared.nix    # Separate CF tunnel
├── configuration.nix           # Base NixOS config (shared)
├── configuration-gatus.nix     # Gatus-specific config
├── configuration-foundry.nix   # Foundry-specific config
├── flake.nix                   # Nix flake with both images
├── .github/workflows/
│   ├── build.yml              # Main: build & release
│   ├── deploy.yml             # Main: deploy
│   ├── _build-image.yml       # Reusable: build single image
│   └── _deploy-node.yml       # Reusable: deploy to node(s)
├── docs/
│   └── FOUNDRY.md             # Foundry-specific docs
└── README.md                   # This file
```

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- [Task](https://taskfile.dev/) for running tasks
- [1Password CLI](https://1password.com/downloads/command-line/) for secrets
- [DigitalOcean Account](https://cloud.digitalocean.com/)
- [Tailscale Account](https://tailscale.com/)
- [Cloudflare Account](https://dash.cloudflare.com/)

### Building Images

```bash
# Build both images
task nix:build

# Build specific image
task nix:build:gatus
task nix:build:foundry
```

### Deploying

```bash
# Deploy both configurations
task nix:deploy

# Deploy specific configuration
task nix:deploy:gatus
task nix:deploy:foundry
```

### Version Management

```bash
# Release new version with AI-generated changelog
IMAGE=gatus task release                    # Patch bump (default)
IMAGE=foundry BUMP_TYPE=minor task release  # Minor bump
IMAGE=gatus BUMP_TYPE=major task release    # Major bump

# Commit locally without pushing (review changelog first)
IMAGE=foundry PUSH=false task release
```

## Setup New Machines

### 1. Build Custom Images

Images are built automatically when you bump version files:

```bash
# Bump Gatus version
echo "1.0.1" > gatus.version
git add gatus.version
git commit -m "chore: bump gatus to v1.0.1"
git push

# Bump Foundry version
echo "1.0.1" > foundry.version
git add foundry.version
git commit -m "chore: bump foundry to v1.0.1"
git push
```

**Automatic triggers**:
- Change to `gatus.version` → builds Gatus image → creates `gatus-v1.0.1` release
- Change to `foundry.version` → builds Foundry image → creates `foundry-v1.0.1` release
- Changes to any `.nix` or `modules/` files → rebuilds, but no new release

**Manual build**:
```bash
# Go to Actions → Build & Release NixOS Images → Run workflow
# Choose: all, gatus, or foundry
```

### 2. Create Droplets

#### Gatus Droplet
1. Create droplet from `nixos-gatus-YYYYMMDD-HHMMSS` custom image
2. Choose size: 1GB RAM minimum ($6/month)
3. Add your SSH key
4. Note the droplet IP

#### Foundry Droplet
1. Create droplet from `nixos-foundry-YYYYMMDD-HHMMSS` custom image
2. Choose size: 2GB RAM minimum ($12/month)
3. Add your SSH key
4. Create and attach 50GB block storage volume
5. Note the droplet IP

### 3. Configure Secrets

Update `deploy.json` in 1Password (`op://kubernetes/nixos/deploy.json`):

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

### 4. Load Secrets

```bash
# Load build secrets (deploy.json)
task secrets:load:build

# Load runtime secrets to servers
task secrets:load:gatus   # Tailscale, Cloudflare, Gatus env
task secrets:load:foundry # Tailscale, Cloudflare, Foundry license
```

### 5. Initial Deployment

```bash
# Deploy configurations to both servers
task nix:deploy

# Or deploy individually
task nix:deploy:gatus
task nix:deploy:foundry
```

## Services

### Gatus (Monitoring)

**Access**:
- https://gatus.syscd.live
- https://up.syscd.live
- http://gatus.tailcecc0.ts.net:8080 (via Tailscale)

**Features**:
- Uptime monitoring
- Status page
- Discord webhooks
- Monitors Foundry VTT availability

**Commands**:
```bash
# Check service status
ssh root@gatus.tailcecc0.ts.net systemctl status gatus

# View logs
ssh root@gatus.tailcecc0.ts.net journalctl -u gatus -f

# Restart service
ssh root@gatus.tailcecc0.ts.net systemctl restart gatus
```

### Foundry VTT (Game Server)

**Access**:
- https://foundry.syscd.live (public)
- https://foundry.syscd.tech (public)
- http://foundry.tailcecc0.ts.net:30000 (via Tailscale)

**Features**:
- Docker-based deployment
- 50GB persistent storage
- Automatic updates
- Public + VPN access

**Commands**:
```bash
# Check service status
ssh root@foundry.tailcecc0.ts.net systemctl status foundry

# View logs
ssh root@foundry.tailcecc0.ts.net journalctl -u foundry -f

# Restart service (pulls latest Docker image)
ssh root@foundry.tailcecc0.ts.net systemctl restart foundry

# Check Docker container
ssh root@foundry.tailcecc0.ts.net docker ps
```

See [docs/FOUNDRY.md](docs/FOUNDRY.md) for detailed Foundry setup and maintenance guide.

## Shared Infrastructure

Both services include:

### Tailscale VPN
- Mesh networking
- MagicDNS via unbound
- Subnet routing enabled
- Tags: `ci` for GitHub Actions

```bash
# Check Tailscale status
ssh root@<hostname> tailscale status
```

### SSH
- OpenSSH enabled
- Password authentication disabled
- Key-based authentication only
- Root access via authorized keys

### Cloudflare Tunnel
- Separate tunnels per service
- Public HTTPS access
- No exposed ports (except Tailscale)

## Development

### Local Testing

```bash
# Check Nix flake
nix flake check

# Build locally
task nix:build:gatus

# Test configuration
nixos-rebuild build-vm --flake .#gatus
```

### Modifying Configurations

**For configuration changes** (no new image needed):
```bash
# Make changes to modules
vim modules/gatus/config.yaml

# Deploy directly (no rebuild needed)
task nix:deploy:gatus
```

**For image updates** (requires rebuild):
```bash
# Make changes to modules
vim modules/foundry/default.nix

# Release with AI-generated changelog (bumps version, commits, pushes)
IMAGE=foundry task release

# GitHub Actions will automatically build and create release
# Then deploy the new configuration
task nix:deploy:foundry
```

**Advanced release options**:
```bash
# Review changelog before pushing
IMAGE=gatus PUSH=false task release
# Review the commit, then manually push:
git push

# Different bump types
IMAGE=foundry BUMP_TYPE=minor task release  # 1.0.0 → 1.1.0
IMAGE=gatus BUMP_TYPE=major task release    # 1.0.0 → 2.0.0
```

**Complete workflow example**:
```bash
# 1. Make changes
vim modules/foundry/default.nix

# 2. Release (bump, AI changelog, commit, push)
IMAGE=foundry task release

# 3. Wait for GitHub Actions to build (~5-10 min)
# 4. Deploy new config to running server
task nix:deploy:foundry
```

### Adding New Services

1. Create `<service>.version` file (e.g., `echo "1.0.0" > myapp.version`)
2. Create module in `modules/<service>/`
3. Create configuration in `configuration-<service>.nix`
4. Add to `flake.nix` nixosConfigurations
5. Update `build.yml` to include new image in workflow
6. Add deployment node to `deploy.json`
7. Create secrets in 1Password
8. Document in `docs/<SERVICE>.md`

## Troubleshooting

### Common Issues

**Tailscale not connecting**:
```bash
ssh root@<hostname> systemctl status tailscale-autoconnect
ssh root@<hostname> journalctl -u tailscale-autoconnect -f
```

**Cloudflare tunnel down**:
```bash
# Gatus
ssh root@gatus.tailcecc0.ts.net systemctl status cloudflared-tunnel-*

# Foundry
ssh root@foundry.tailcecc0.ts.net systemctl status cloudflared-tunnel-*
```

**Service won't start**:
```bash
# Check service status
ssh root@<hostname> systemctl status <service>

# View recent logs
ssh root@<hostname> journalctl -u <service> -n 100

# Check configuration
ssh root@<hostname> systemctl cat <service>
```

**Debugging Tools**:
```bash
# Install network debugging tools
nix-env -iA nixos.dnsutils nixos.inetutils nixos.tcpdump

# Test DNS
dig gatus.syscd.live

# Test connectivity
curl -I https://gatus.syscd.live

# Check firewall
ssh root@<hostname> iptables -L -n -v
```

## CI/CD

### GitHub Actions Workflows

The repository uses **version-based releases** with **reusable workflows**:

**Version Control**:
- `gatus.version` - Gatus image version (bump to trigger build + release)
- `foundry.version` - Foundry image version (bump to trigger build + release)

**Main Workflows**:
- `build.yml` - Detects version changes, builds images, creates releases
- `deploy.yml` - Deploys to specified nodes via Tailscale

**Reusable Library Workflows** (prefixed with `_`):
- `_build-image.yml` - Builds a single NixOS image and uploads to DO
- `_deploy-node.yml` - Deploys configuration to specified node(s)

**How it works**:
1. Change `gatus.version` or `foundry.version` and push to main
2. GitHub Actions automatically builds the changed image(s)
3. Uploads to GCS and creates DigitalOcean custom image
4. Creates GitHub release tagged as `gatus-v1.0.1` or `foundry-v1.0.1`
5. You can then create a droplet from the custom image

**Manual options**:
- Build specific image: Actions → Build & Release → Choose image
- Deploy specific node: Actions → Deploy → Choose target (all/gatus/foundry)

### Required Secrets

GitHub Actions secrets:
- `DEPLOY_NIX_JSON` - Deployment configuration
- `DEPLOY_SSH_KEY` - SSH private key
- `TS_OAUTH_CLIENT_ID` - Tailscale OAuth
- `TS_OAUTH_SECRET` - Tailscale OAuth secret
- `WIF_PROVIDER` - GCP Workload Identity
- `WIF_SERVICE_ACCOUNT` - GCP Service Account
- `GCP_PROJECT_ID` - Google Cloud project
- `GCS_BUCKET_NAME` - Storage bucket name
- `DIGITALOCEAN_ACCESS_TOKEN` - DO API token

## Cost Breakdown

**Gatus**:
- Droplet (1GB): $6/month
- Total: ~$6/month

**Foundry**:
- Droplet (2GB): $12/month
- Block Storage (50GB): $5/month
- Total: ~$17/month

**Combined**: ~$23/month + bandwidth

## References

### NixOS & DigitalOcean
- [Deploying NixOS with flakes on Digital Ocean](https://blog.lelgenio.com/deploying-nixos-with-flakes-on-digital-ocean)
- [NixOS in the Cloud, step-by-step](https://justinas.org/nixos-in-the-cloud-step-by-step-part-1)
- [Remote Deployment | NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/best-practices/remote-deployment)

### Tools & Services
- [Gatus Documentation](https://github.com/TwiN/gatus)
- [Foundry VTT](https://foundryvtt.com)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Cloudflare Tunnel Documentation](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/)
- [deploy-rs](https://github.com/serokell/deploy-rs)

## License

MIT