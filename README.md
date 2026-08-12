# Infrastructure

Docker and Cloudflare infrastructure for the server.

## Structure

```text
.
├── compose-*.yml
├── conf/
├── cloudflared-config/
├── all-compose.sh
├── start-cloudflared-tunnel.sh
├── stop-cloudflared-tunnel.sh
└── update-cloudflared-dns.sh
```

- `compose-*.yml` — Docker Compose services
- `conf/` — Service configuration
- `cloudflared-config/` — Cloudflare Tunnel configurations
- `all-compose.sh` — Start all Compose services
- `start-cloudflared-tunnel.sh` — Start all Cloudflare tunnels
- `stop-cloudflared-tunnel.sh` — Stop all Cloudflare tunnels
- `update-cloudflared-dns.sh` — Create/update DNS records for all tunnels

---

# Docker Compose

Compose files are named `compose-*.yml`.

Start all services:

```bash
./all-compose.sh
```

---

# Cloudflare Tunnels

Each Cloudflare Tunnel has its own directory:

```text
cloudflared-config/
├── ruinfo.ch/
│   ├── config.yml
│   ├── cert.pem
│   └── <TUNNEL-ID>.json
│
└── ruinformatique.ch/
    ├── config.yml
    ├── cert.pem
    └── <TUNNEL-ID>.json
```

The directory name **must be the Cloudflare domain**.

For example:

```text
cloudflared-config/ruinfo.ch/
cloudflared-config/ruinformatique.ch/
```

Real tunnel directories are ignored by Git.

The `folder-example.org.disabled` directory is provided as an example.

---

## Create a new Cloudflare Tunnel

### 1. Create the tunnel

```bash
cloudflared tunnel create example.org
```

Cloudflare will return a Tunnel ID.

A credentials file will also be created in:

```text
~/.cloudflared/<TUNNEL-ID>.json
```

Create the configuration directory:

```bash
mkdir -p cloudflared-config/example.org
```

Copy the credentials:

```bash
cp ~/.cloudflared/<TUNNEL-ID>.json \
   cloudflared-config/example.org/
```

---

### 2. Create the Cloudflare certificate

The certificate is required for Cloudflare management operations such as creating DNS routes.

Run:

```bash
cloudflared tunnel login
```

Select the correct Cloudflare zone.

Then copy the generated certificate:

```bash
cp ~/.cloudflared/cert.pem \
   cloudflared-config/example.org/cert.pem
```

**Never commit `cert.pem` or the tunnel `.json` credentials.**

---

### 3. Create `config.yml`

Use:

```text
cloudflared-config/folder-example.org.disabled/config.yml
```

as a template.

Example:

```yaml
tunnel: <TUNNEL-ID>
credentials-file: /home/docker/infrastructure/cloudflared-config/example.org/<TUNNEL-ID>.json

ingress:

  - hostname: app.example.org
    service: http://localhost:8080

  - service: http_status:404
```

The `credentials-file` must point to the tunnel's JSON credentials.

---

### 4. Create DNS records

Run:

```bash
./update-cloudflared-dns.sh
```

The script automatically:

- Finds all active tunnel directories
- Reads the tunnel ID from `config.yml`
- Finds all hostnames
- Uses the `cert.pem` from the corresponding domain directory
- Creates/updates the Cloudflare DNS routes

The directory name must match the domain:

```text
cloudflared-config/example.org/
                           ^^^^^^^^^^
                           Cloudflare domain
```

Hostnames in the configuration must belong to that domain.

For example:

```text
example.org          ✓
app.example.org     ✓
api.example.org     ✓

example.com          ✗
app.example.com      ✗
```

---

### 5. Start the tunnels

```bash
./start-cloudflared-tunnel.sh
```

All active tunnels are started in the background.

Logs are stored in each tunnel directory:

```text
cloudflared-config/example.org/cloudflared.log
```

---

### 6. Stop the tunnels

```bash
./stop-cloudflared-tunnel.sh
```

PID files are stored in each tunnel directory:

```text
cloudflared-config/example.org/cloudflared.pid
```

---

# Disable a Tunnel

To prevent a tunnel from being managed by the scripts, add `.disabled` to the directory name:

```text
cloudflared-config/example.org.disabled/
```

The scripts will automatically ignore it.

---

# Add a Service to a Tunnel

Add another `ingress` rule to the tunnel's `config.yml`:

```yaml
ingress:

  - hostname: app.example.org
    service: http://localhost:8080

  - hostname: api.example.org
    service: http://localhost:8081

  - service: http_status:404
```

Then update DNS:

```bash
./update-cloudflared-dns.sh
```

And restart the tunnels:

```bash
./stop-cloudflared-tunnel.sh
./start-cloudflared-tunnel.sh
```

---

# Secrets

Never commit:

- `cert.pem`
- Cloudflare `*.json` credentials
- `cloudflared.log`
- `cloudflared.pid`
- `.env` files

These files contain secrets or are generated automatically.
