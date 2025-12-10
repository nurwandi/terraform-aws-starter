# Traefik Gateway - Lensclause Infrastructure

## Overview

Traefik berfungsi sebagai **reverse proxy gateway** untuk semua services di infrastructure Lensclause. Semua traffic dari internet masuk melalui Traefik, kemudian di-route ke service yang sesuai berdasarkan domain/path.

### Architecture

```
Internet
   │
   ▼
Traefik Server (16.79.191.60)
   │
   ├─► Flask Gemini (10.3.11.107:5000)
   ├─► App Services (10.3.11.28:8080)
   ├─► MinIO Console (10.3.11.206:9001)
   ├─► MinIO API (10.3.11.206:9000)
   └─► PostgreSQL/MongoDB (10.3.11.19)
```

---

## File Structure

```
traefik/
├── docker-compose.yaml    # Container definition
├── traefik.yml           # Main Traefik configuration
├── config.yml            # External services routing
├── .env                  # Environment variables (optional)
└── README.md            # This file
```

---

## Quick Start

### Prerequisites

1. **Traefik Server** sudah running di public subnet
2. **Backend servers** sudah running di private subnet
3. **Security Groups** configured:
   - Traefik SG: Allow 80, 443, 8080 from internet
   - Backend SGs: Allow traffic from Traefik SG
4. **Docker network** `proxy` created: `docker network create proxy`

### Deployment Steps

#### 1. Upload Files ke Server

```bash
# From local machine
scp -r traefik/ ec2-user@16.79.191.60:/opt/
```

Atau via SSM:

```bash
# Copy files using AWS SSM or manual upload
```

#### 2. Customize Configuration

Edit `config.yml` dan sesuaikan:

```yaml
# Update domain names
rule: "Host(`flask.lensclause.com`)"  # Replace with real domain

# Verify backend IPs and ports
- url: "http://10.3.11.107:5000"      # Confirm port is correct

# Change default passwords
users:
  - "admin:$apr1$..."  # Generate new hash with htpasswd
```

#### 3. Create Docker Network (if not exists)

```bash
docker network create proxy
```

#### 4. Deploy Traefik

```bash
cd /opt/traefik
docker-compose up -d
```

#### 5. Verify Deployment

```bash
# Check container status
docker ps | grep traefik

# View logs
docker logs traefik -f

# Access dashboard
curl http://localhost:8080/api/overview
```

---

## Configuration Guide

### traefik.yml - Main Configuration

```yaml
api:
  dashboard: true     # Enable dashboard
  debug: true         # Enable debug logs
  insecure: true      # Allow insecure dashboard (dev only)

entryPoints:
  http:
    address: ":80"    # HTTP port
  traefik:
    address: ":8080"  # Dashboard port

providers:
  docker:             # Auto-discover local containers
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: proxy

  file:               # External services config
    filename: /config.yml
    watch: true       # Auto-reload on changes
```

### config.yml - External Services Routing

File ini berisi routing untuk services di server lain. Format:

```yaml
http:
  routers:           # Routing rules
    service-name-router:
      rule: "Host(`domain.com`)"
      service: service-name
      entryPoints: [http]

  services:          # Backend definitions
    service-name:
      loadBalancer:
        servers:
          - url: "http://10.3.11.x:port"
```

---

## Adding New Service

### Step 1: Add Router

Edit `config.yml`, tambahkan di section `routers`:

```yaml
http:
  routers:
    my-new-service-router:
      rule: "Host(`newservice.lensclause.com`)"
      service: my-new-service
      entryPoints:
        - http
      priority: 10
```

### Step 2: Add Service

Tambahkan di section `services`:

```yaml
http:
  services:
    my-new-service:
      loadBalancer:
        servers:
          - url: "http://10.3.11.x:8080"
        healthCheck:
          path: "/health"
          interval: "30s"
          timeout: "5s"
```

### Step 3: Wait for Auto-Reload

Karena `watch: true`, Traefik akan otomatis reload config dalam 1-2 detik.

**Tidak perlu restart container!**

### Step 4: Verify

```bash
# Check dashboard
http://16.79.191.60:8080/dashboard/

# Test routing
curl -H "Host: newservice.lensclause.com" http://16.79.191.60/
```

---

## DNS Configuration

Point semua domain ke Traefik public IP:

```
flask.lensclause.com       A    16.79.191.60
app.lensclause.com         A    16.79.191.60
minio.lensclause.com       A    16.79.191.60
s3.lensclause.com          A    16.79.191.60
```

Traefik akan route berdasarkan `Host()` header.

---

## Security Groups

### Traefik Server SG

**Inbound:**
```
Port 80    TCP  0.0.0.0/0         HTTP
Port 443   TCP  0.0.0.0/0         HTTPS
Port 8080  TCP  YOUR_IP/32        Dashboard (restrict!)
```

**Outbound:**
```
All traffic
```

### Backend Server SG

**Inbound:**
```
Port 5000   TCP  <Traefik-SG>     Flask
Port 8080   TCP  <Traefik-SG>     App Services
Port 9000   TCP  <Traefik-SG>     MinIO API
Port 9001   TCP  <Traefik-SG>     MinIO Console
```

---

## Testing

### Test Local Connectivity

```bash
# From Traefik server
docker exec traefik curl http://10.3.11.107:5000/health
docker exec traefik curl http://10.3.11.28:8080/health
docker exec traefik curl http://10.3.11.206:9000/minio/health/live
```

### Test Routing (without domain)

```bash
# Using Host header
curl -H "Host: flask.lensclause.com" http://16.79.191.60/
curl -H "Host: app.lensclause.com" http://16.79.191.60/
curl -H "Host: minio.lensclause.com" http://16.79.191.60/
```

### Test Routing (with domain)

```bash
# After DNS configured
curl http://flask.lensclause.com/
curl http://app.lensclause.com/
curl http://minio.lensclause.com/
```

### View Dashboard

Browser: `http://16.79.191.60:8080/dashboard/`

Dashboard menampilkan:
- Active routers dan rules
- Backend services dan health status
- Request metrics
- Configuration errors (if any)

---

## Troubleshooting

### Container Not Running

```bash
# Check status
docker ps -a | grep traefik

# View logs
docker logs traefik

# Restart
cd /opt/traefik
docker-compose restart
```

### Service Unreachable (503)

**Possible causes:**

1. **Backend not running**
   ```bash
   # SSH to backend server
   docker ps
   ```

2. **Wrong IP/port in config.yml**
   ```bash
   # Test from Traefik
   docker exec traefik curl http://10.3.11.107:5000
   ```

3. **Security Group blocking**
   ```bash
   # Check backend SG allows traffic from Traefik
   aws ec2 describe-security-groups --group-ids sg-xxx
   ```

4. **Health check failing**
   ```bash
   # Check dashboard for service status
   # Implement /health endpoint in backend
   ```

### Configuration Not Loading

```bash
# Check syntax errors
docker logs traefik | grep -i error

# Verify file is mounted
docker exec traefik cat /config.yml

# Force reload (if watch disabled)
docker-compose restart
```

### Dashboard Not Accessible

1. **Check EntryPoint**
   ```yaml
   # traefik.yml must have:
   entryPoints:
     traefik:
       address: ":8080"
   ```

2. **Check port exposed**
   ```yaml
   # docker-compose.yaml:
   ports:
     - 8080:8080
   ```

3. **Check Security Group**
   - Port 8080 must be open (at least from your IP)

### Connection Timeout

1. **Instance in private subnet?**
   - Must be in public subnet with IGW
   - Check route table: 0.0.0.0/0 → IGW (not NAT)

2. **Security Group blocking?**
   - Verify inbound rules

3. **Backend unreachable?**
   - Test connectivity from Traefik server

---

## Maintenance

### Update Traefik Version

```bash
# Edit docker-compose.yaml
image: traefik:3.6.2  # Update version

# Pull new image
docker-compose pull

# Recreate container (zero downtime)
docker-compose up -d
```

### Backup Configuration

```bash
# Backup all configs
tar -czf traefik-backup-$(date +%Y%m%d).tar.gz /opt/traefik/

# Upload to S3
aws s3 cp traefik-backup-*.tar.gz s3://your-bucket/backups/
```

### View Logs

```bash
# Follow logs
docker logs -f traefik

# Last 100 lines
docker logs --tail 100 traefik

# With timestamp
docker logs -t traefik
```

### Restart Traefik

```bash
cd /opt/traefik

# Graceful restart
docker-compose restart

# Force recreate
docker-compose up -d --force-recreate
```

---

## Enabling HTTPS (Let's Encrypt)

### Step 1: Update traefik.yml

Uncomment section:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /acme.json
      httpChallenge:
        entryPoint: http
```

### Step 2: Create acme.json

```bash
touch /opt/traefik/acme.json
chmod 600 /opt/traefik/acme.json
```

### Step 3: Update docker-compose.yaml

Uncomment:

```yaml
volumes:
  - ./acme.json:/acme.json
```

### Step 4: Update config.yml

Add to routers:

```yaml
routers:
  flask-gemini-router:
    rule: "Host(`flask.lensclause.com`)"
    service: flask-gemini-service
    entryPoints:
      - https
    tls:
      certResolver: letsencrypt
```

### Step 5: Restart Traefik

```bash
docker-compose up -d --force-recreate
```

Let's Encrypt akan otomatis generate SSL certificate.

---

## Monitoring

### Built-in Dashboard

URL: `http://16.79.191.60:8080/dashboard/`

Features:
- Real-time request metrics
- Service health status
- Active routes
- Configuration overview

### API Endpoints

```bash
# Overview
curl http://localhost:8080/api/overview

# List routers
curl http://localhost:8080/api/http/routers | jq

# List services
curl http://localhost:8080/api/http/services | jq

# Health
curl http://localhost:8080/api/health
```

### Access Logs

Enable in traefik.yml:

```yaml
accessLog:
  filePath: "/var/log/traefik/access.log"
  format: json
```

Mount volume:

```yaml
volumes:
  - ./logs:/var/log/traefik
```

---

## Production Checklist

Before going to production:

- [ ] Replace all domain placeholders with real domains
- [ ] Change all default passwords (use `htpasswd -nb user pass`)
- [ ] Verify all backend IPs and ports
- [ ] Implement `/health` endpoints in all services
- [ ] Enable HTTPS with Let's Encrypt
- [ ] Restrict CORS origins to specific domains
- [ ] Enable authentication for sensitive services (databases, MinIO)
- [ ] Restrict dashboard access (remove `insecure: true`)
- [ ] Configure Security Groups properly
- [ ] Verify DNS records
- [ ] Enable access logs
- [ ] Setup monitoring/alerts
- [ ] Backup configuration to S3/Git
- [ ] Test failover scenarios
- [ ] Document all credentials securely
- [ ] Review rate limiting settings

---

## Useful Commands

### Docker

```bash
# Container status
docker ps | grep traefik

# Logs
docker logs -f traefik

# Exec into container
docker exec -it traefik sh

# Restart
docker-compose restart

# Stop
docker-compose down

# Start
docker-compose up -d
```

### Traefik

```bash
# Version
docker exec traefik traefik version

# Check config
docker exec traefik cat /traefik.yml

# Validate config (dry run)
docker exec traefik traefik --configFile=/traefik.yml --dry-run
```

### Debugging

```bash
# Test backend connectivity
docker exec traefik curl http://10.3.11.107:5000

# Check routes
curl http://localhost:8080/api/http/routers | jq '.[] | {name: .name, rule: .rule, service: .service}'

# Check services health
curl http://localhost:8080/api/http/services | jq '.[] | {name: .name, status: .serverStatus}'

# Network inspection
docker network inspect proxy
```

---

## Support & Documentation

### Official Traefik Docs
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [File Provider](https://doc.traefik.io/traefik/providers/file/)
- [Routing](https://doc.traefik.io/traefik/routing/routers/)

### Internal Docs
- `KNOWLEDGE.md` - Technical knowledge base
- `CLAUDE.md` - Project context & memory

### Contact
- Owner: Qolbi NurWandi
- Email: qolbi.yunus@insignia.co.id

---

## Changelog

### 2025-11-18
- Initial Traefik setup
- Created config templates for 4 backend services
- Documented deployment process
- Added troubleshooting guide

---

**Last Updated**: 2025-11-18
**Version**: 1.0
