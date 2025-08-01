# Neptuner Production Deployment Guide

This guide covers deploying the Neptuner productivity application to production environments with best practices for security, performance, and reliability.

## Table of Contents

- [Pre-deployment Checklist](#pre-deployment-checklist)
- [Server Requirements](#server-requirements)
- [Environment Configuration](#environment-configuration)
- [Database Deployment](#database-deployment)
- [Asset Optimization](#asset-optimization)
- [SSL/HTTPS Configuration](#sslhttps-configuration)
- [Background Job Workers](#background-job-workers)
- [Monitoring and Logging](#monitoring-and-logging)
- [Platform-Specific Guides](#platform-specific-guides)
- [Security Considerations](#security-considerations)
- [Performance Optimization](#performance-optimization)
- [Backup and Recovery](#backup-and-recovery)
- [Troubleshooting](#troubleshooting)

## Pre-deployment Checklist

### Code Quality
- [ ] All tests pass: `mix test`
- [ ] Code is formatted: `mix format --check-formatted`
- [ ] Security vulnerabilities checked: `mix deps.audit`
- [ ] Database migrations are ready and tested
- [ ] Assets are optimized: `mix assets.deploy`

### Configuration
- [ ] Production environment variables configured
- [ ] OAuth applications registered with production URLs
- [ ] Payment processor webhooks configured
- [ ] Database backups scheduled
- [ ] Monitoring and alerting configured

### Security
- [ ] `SECRET_KEY_BASE` is cryptographically secure
- [ ] Database credentials are secure
- [ ] Admin passwords are strong
- [ ] SSL certificates are valid and configured
- [ ] Security headers are configured

## Server Requirements

### Minimum Requirements
- **CPU**: 2 cores
- **RAM**: 2GB (4GB recommended)
- **Storage**: 20GB SSD (50GB+ recommended)
- **OS**: Ubuntu 20.04+ / CentOS 8+ / Amazon Linux 2

### Recommended Production Setup
- **CPU**: 4+ cores
- **RAM**: 8GB+
- **Storage**: 100GB+ SSD with automated backups
- **Network**: Load balancer with SSL termination
- **Database**: Dedicated PostgreSQL instance

### Required Software
- **Elixir**: 1.15+
- **Erlang/OTP**: 26+
- **PostgreSQL**: 14+
- **Node.js**: 18+ (for asset compilation)
- **Nginx**: (recommended reverse proxy)

## Environment Configuration

### Production Environment Variables

Create a secure `.env` file or configure environment variables:

```bash
# Core Application
PHX_HOST=your-domain.com
PORT=4000
PHX_SERVER=true
SECRET_KEY_BASE=your_very_secure_64_char_secret

# Database
DATABASE_URL=ecto://username:password@host:5432/neptuner_prod
POOL_SIZE=10
ECTO_IPV6=false

# OAuth - User Authentication
GOOGLE_CLIENT_ID=your_production_google_client_id
GOOGLE_CLIENT_SECRET=your_production_google_client_secret
GITHUB_CLIENT_ID=your_production_github_client_id
GITHUB_CLIENT_SECRET=your_production_github_client_secret

# OAuth - Service Integration
GOOGLE_OAUTH_CLIENT_ID=your_google_service_client_id
GOOGLE_OAUTH_CLIENT_SECRET=your_google_service_client_secret
MICROSOFT_OAUTH_CLIENT_ID=your_microsoft_client_id
MICROSOFT_OAUTH_CLIENT_SECRET=your_microsoft_client_secret

# Payments
LEMONSQUEEZY_API_KEY=your_lemonsqueezy_api_key
LEMONSQUEEZY_WEBHOOK_SECRET=your_webhook_secret

# AI/LLM
OPENAI_API_KEY=your_openai_api_key

# Admin Access
ADMIN_USERNAME=your_admin_username
ADMIN_PASSWORD=your_very_secure_admin_password

# Application URL
APP_URL=https://your-domain.com

# Monitoring (optional)
SENTRY_DSN=your_sentry_dsn
HONEYBADGER_API_KEY=your_honeybadger_key

# Email (configure based on your provider)
SMTP_HOST=smtp.your-provider.com
SMTP_PORT=587
SMTP_USERNAME=your_smtp_username
SMTP_PASSWORD=your_smtp_password
SMTP_TLS=true

# Cache and Performance
CACHE_TTL=300
DNS_CLUSTER_QUERY=your-cluster-query
```

### Generating Secrets

```bash
# Generate SECRET_KEY_BASE
mix phx.gen.secret

# Generate secure admin password
openssl rand -base64 32

# Generate webhook secrets
openssl rand -hex 32
```

## Database Deployment

### PostgreSQL Setup

#### 1. Install PostgreSQL
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql postgresql-contrib

# CentOS/RHEL
sudo yum install postgresql-server postgresql-contrib
sudo postgresql-setup initdb
```

#### 2. Configure PostgreSQL
```bash
# Create database and user
sudo -u postgres psql
```

```sql
CREATE USER neptuner WITH PASSWORD 'secure_password';
CREATE DATABASE neptuner_prod OWNER neptuner;
GRANT ALL PRIVILEGES ON DATABASE neptuner_prod TO neptuner;

-- Enable necessary extensions
\c neptuner_prod;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

#### 3. Configure Connection Security
Edit `/etc/postgresql/*/main/postgresql.conf`:
```
listen_addresses = 'localhost'  # or your specific IP
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
```

Edit `/etc/postgresql/*/main/pg_hba.conf`:
```
# Allow application connection
host neptuner_prod neptuner 127.0.0.1/32 md5
```

#### 4. Run Migrations
```bash
# Set production environment
export MIX_ENV=prod

# Run migrations
mix ecto.migrate

# Seed initial data (if needed)
mix run priv/repo/seeds.exs
```

### Database Performance Tuning

Add indexes for common queries:
```sql
-- Performance indexes
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);
CREATE INDEX CONCURRENTLY idx_tasks_user_id ON tasks(user_id);
CREATE INDEX CONCURRENTLY idx_tasks_status ON tasks(status);
CREATE INDEX CONCURRENTLY idx_habits_user_id ON habits(user_id);
CREATE INDEX CONCURRENTLY idx_service_connections_user_id ON service_connections(user_id);
CREATE INDEX CONCURRENTLY idx_meetings_user_id ON meetings(user_id);
CREATE INDEX CONCURRENTLY idx_meetings_start_time ON meetings(start_time);
```

## Asset Optimization

### Build Production Assets
```bash
# Set production environment
export MIX_ENV=prod

# Install asset dependencies
mix assets.setup

# Build and optimize assets
mix assets.deploy
```

This will:
- Minify CSS and JavaScript
- Generate asset digests for cache busting
- Create gzipped versions of assets
- Generate `cache_manifest.json`

### Nginx Asset Configuration
```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
    add_header Vary Accept-Encoding;
    
    # Serve gzipped assets if available
    gzip_static on;
}
```

## SSL/HTTPS Configuration

### Option 1: Let's Encrypt with Certbot
```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal (add to crontab)
0 12 * * * /usr/bin/certbot renew --quiet
```

### Option 2: Manual SSL Certificate
```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/certificate.crt;
    ssl_certificate_key /path/to/private.key;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY always;
    add_header X-Content-Type-Options nosniff always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}
```

## Background Job Workers

### Oban Configuration

Ensure Oban is properly configured for production in `config/runtime.exs`:

```elixir
config :neptuner, Oban,
  engine: Oban.Engines.Basic,
  notifier: Oban.Notifiers.Postgres,
  repo: Neptuner.Repo,
  queues: [
    default: 10,
    token_refresh: 5,
    webhook_renewal: 3,
    sync: 8,
    analytics: 2
  ]
```

### Systemd Service for Background Workers

Create `/etc/systemd/system/neptuner.service`:
```ini
[Unit]
Description=Neptuner Phoenix Application
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=forking
User=neptuner
Group=neptuner
WorkingDirectory=/opt/neptuner
Environment=MIX_ENV=prod
Environment=PORT=4000
EnvironmentFile=/opt/neptuner/.env
ExecStart=/opt/neptuner/bin/neptuner start
ExecStop=/opt/neptuner/bin/neptuner stop
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

Enable and start the service:
```bash
sudo systemctl enable neptuner
sudo systemctl start neptuner
sudo systemctl status neptuner
```

### Worker Monitoring

Monitor background jobs:
- Production Oban Dashboard: Configure access restrictions
- Log analysis for job failures
- Metrics collection for job processing times

## Monitoring and Logging

### Application Monitoring

Configure monitoring in `config/runtime.exs`:

```elixir
# Telemetry and monitoring
config :neptuner, :telemetry,
  enabled: true,
  metrics: [
    # Phoenix metrics
    "phoenix.endpoint.start",
    "phoenix.endpoint.stop",
    "phoenix.router_dispatch.start",
    "phoenix.router_dispatch.stop",
    
    # Ecto metrics
    "neptuner.repo.query",
    
    # Oban metrics
    "oban.job.start",
    "oban.job.stop",
    "oban.job.exception"
  ]

# Error tracking
config :error_tracker,
  enabled: true,
  store_source_code: false
```

### Log Configuration

Configure structured logging:

```elixir
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :organization_id]

config :logger,
  backends: [:console, {LoggerFileBackend, :file}]

config :logger, :file,
  path: "/var/log/neptuner/app.log",
  level: :info,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :user_id, :organization_id]
```

### Nginx Logging
```nginx
access_log /var/log/nginx/neptuner_access.log combined;
error_log /var/log/nginx/neptuner_error.log warn;
```

### Log Rotation
Create `/etc/logrotate.d/neptuner`:
```
/var/log/neptuner/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
```

## Platform-Specific Guides

### Fly.io Deployment

1. **Install Fly CLI**
   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Initialize Fly App**
   ```bash
   fly launch
   ```

3. **Configure fly.toml**
   ```toml
   app = "neptuner"
   primary_region = "ord"

   [build]
     dockerfile = "Dockerfile"

   [env]
     MIX_ENV = "prod"
     PORT = "8080"
     PHX_HOST = "neptuner.fly.dev"

   [[services]]
     internal_port = 8080
     protocol = "tcp"

     [[services.ports]]
       handlers = ["http"]
       port = 80
       force_https = true

     [[services.ports]]
       handlers = ["tls", "http"]
       port = 443

   [checks]
     [checks.alive]
       grace_period = "30s"
       interval = "15s"
       method = "GET"
       path = "/webhooks/health"
       port = 8080
       timeout = "2s"
   ```

4. **Set Environment Variables**
   ```bash
   fly secrets set SECRET_KEY_BASE=your_secret
   fly secrets set DATABASE_URL=your_database_url
   # Set all other environment variables...
   ```

5. **Deploy**
   ```bash
   fly deploy
   ```

### Digital Ocean App Platform

1. **Create `app.yaml`**
   ```yaml
   name: neptuner
   services:
   - name: web
     source_dir: /
     github:
       repo: your-org/neptuner
       branch: main
     run_command: mix phx.server
     environment_slug: elixir
     instance_count: 1
     instance_size_slug: basic-xxs
     envs:
     - key: MIX_ENV
       value: prod
     - key: PHX_HOST
       value: neptuner-xyz.ondigitalocean.app
     - key: SECRET_KEY_BASE
       value: your_secret
       type: SECRET
     # Add other environment variables...
   
   databases:
   - name: neptuner-db
     engine: PG
     version: "14"
   ```

### AWS Elastic Beanstalk

1. **Create Dockerfile**
   ```dockerfile
   FROM elixir:1.15-alpine

   RUN apk add --no-cache build-base npm git

   WORKDIR /app

   COPY mix.exs mix.lock ./
   RUN mix deps.get --only prod
   RUN mix deps.compile

   COPY assets assets
   RUN mix assets.setup
   RUN mix assets.deploy

   COPY . .
   RUN mix compile

   EXPOSE 4000
   CMD ["mix", "phx.server"]
   ```

2. **Deploy**
   ```bash
   eb init
   eb create production
   eb deploy
   ```

## Security Considerations

### Application Security

1. **Environment Variables**
   - Never commit secrets to version control
   - Use secure secret management services
   - Rotate secrets regularly

2. **Database Security**
   - Use encrypted connections (SSL)
   - Implement connection pooling limits
   - Regular security updates

3. **API Security**
   - Rate limiting configured
   - CORS properly configured
   - Input validation on all endpoints

4. **Authentication**
   - Strong password policies
   - OAuth tokens properly secured
   - Session management configured

### Infrastructure Security

1. **Network Security**
   - Firewall configured (only 80, 443, SSH open)
   - VPC/private networks where possible
   - Regular security updates

2. **Monitoring**
   - Failed login attempt monitoring
   - Unusual API usage alerts
   - Error rate monitoring

3. **Backups**
   - Encrypted database backups
   - Secure backup storage
   - Regular restore testing

## Performance Optimization

### Application Performance

1. **Database Optimization**
   ```elixir
   # Connection pool configuration
   config :neptuner, Neptuner.Repo,
     pool_size: 10,
     queue_target: 50,
     queue_interval: 1000
   ```

2. **Caching Strategy**
   ```elixir
   # Configure caching for expensive operations
   config :neptuner, :cache,
     adapter: Nebulex.Adapters.Multilevel,
     levels: [
       {
         Nebulex.Adapters.Local,
         gc_interval: :timer.hours(12),
         max_size: 1_000_000,
         allocated_memory: 2_000_000_000
       },
       {Nebulex.Adapters.Redis, []}
     ]
   ```

3. **Background Job Optimization**
   - Monitor job queue lengths
   - Adjust worker pool sizes
   - Implement job priority queues

### Infrastructure Performance

1. **Load Balancing**
   ```nginx
   upstream neptuner_backend {
       server 127.0.0.1:4000;
       server 127.0.0.1:4001;
       server 127.0.0.1:4002;
   }
   ```

2. **Content Delivery Network (CDN)**
   - CloudFlare or AWS CloudFront
   - Static asset caching
   - Geographic distribution

3. **Database Performance**
   - Read replicas for reporting
   - Connection pooling
   - Query optimization

## Backup and Recovery

### Database Backups

1. **Automated Backups**
   ```bash
   #!/bin/bash
   # /opt/scripts/backup-neptuner.sh
   
   TIMESTAMP=$(date +%Y%m%d_%H%M%S)
   BACKUP_DIR="/opt/backups/neptuner"
   DB_NAME="neptuner_prod"
   
   mkdir -p $BACKUP_DIR
   
   pg_dump $DB_NAME | gzip > $BACKUP_DIR/neptuner_$TIMESTAMP.sql.gz
   
   # Cleanup old backups (keep 30 days)
   find $BACKUP_DIR -name "neptuner_*.sql.gz" -mtime +30 -delete
   ```

2. **Backup Verification**
   ```bash
   #!/bin/bash
   # Test backup restoration
   
   LATEST_BACKUP=$(ls -t /opt/backups/neptuner/neptuner_*.sql.gz | head -n1)
   
   # Create test database
   createdb neptuner_test_restore
   
   # Restore backup
   gunzip -c $LATEST_BACKUP | psql neptuner_test_restore
   
   # Verify restoration
   psql neptuner_test_restore -c "SELECT COUNT(*) FROM users;"
   
   # Cleanup
   dropdb neptuner_test_restore
   ```

### Application State Backup

1. **File System Backups**
   - Configuration files
   - Uploaded files (if any)
   - Log files for debugging

2. **Environment Configuration**
   - Document all environment variables
   - Backup OAuth application configurations
   - Payment processor webhook configurations

## Troubleshooting

### Common Deployment Issues

#### Application Won't Start

**Symptoms:**
- Service fails to start
- Port binding errors
- Database connection failures

**Solutions:**
1. Check logs: `journalctl -u neptuner -f`
2. Verify environment variables
3. Test database connection manually
4. Check port availability: `netstat -tulpn | grep :4000`

#### Assets Not Loading

**Symptoms:**
- CSS/JS files return 404
- Styles not applied
- JavaScript functionality broken

**Solutions:**
1. Verify asset compilation: `mix assets.deploy`
2. Check nginx configuration for static files
3. Verify `cache_manifest.json` exists
4. Check file permissions

#### Background Jobs Not Processing

**Symptoms:**
- Jobs pile up in queue
- Oban dashboard shows errors
- Sync operations fail

**Solutions:**
1. Check Oban configuration
2. Verify database connections for job processing
3. Review worker logs
4. Check queue configuration

#### OAuth Integration Failures

**Symptoms:**
- Login redirects fail
- Service connections can't authorize
- Invalid client errors

**Solutions:**
1. Verify OAuth application configurations
2. Check callback URLs match production domain
3. Ensure API scopes are correctly configured
4. Test OAuth flow manually

### Performance Issues

#### High Memory Usage

**Solutions:**
1. Monitor with `:observer.start()`
2. Check for memory leaks in GenServers
3. Review LiveView assign patterns
4. Optimize database queries

#### Slow Database Queries

**Solutions:**
1. Enable query logging
2. Add missing indexes
3. Optimize N+1 queries
4. Consider read replicas

#### High CPU Usage

**Solutions:**
1. Profile with `:fprof` or `:eprof`
2. Check for infinite loops
3. Optimize hot code paths
4. Consider horizontal scaling

### Monitoring Commands

```bash
# Check application status
systemctl status neptuner

# View application logs
journalctl -u neptuner -f

# Check database connections
psql neptuner_prod -c "SELECT count(*) FROM pg_stat_activity;"

# Monitor system resources
htop
iostat -x 1

# Check disk usage
df -h
du -sh /opt/neptuner/*

# Network connections
netstat -tulpn | grep neptuner
```

## Health Checks

### Application Health Endpoints

Neptuner includes health check endpoints:

- **Basic Health**: `GET /webhooks/health`
- **Database Health**: Custom endpoint for database connectivity
- **Background Jobs Health**: Oban dashboard for job processing status

### Monitoring Integration

Configure monitoring services to check:
- HTTP response times
- Database query performance
- Background job processing rates
- Error rates and exceptions
- Memory and CPU usage

## Conclusion

This deployment guide provides a comprehensive foundation for deploying Neptuner to production. Customize the configurations based on your specific infrastructure requirements, security policies, and performance needs.

For additional support:
- Review application logs for specific error messages
- Check the main README.md troubleshooting section
- Monitor the application metrics and adjust configurations as needed

Remember to regularly update dependencies, rotate secrets, and test backup/recovery procedures to maintain a secure and reliable production environment.