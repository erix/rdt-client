# rdt-client-manual-download Helm Chart

Helm chart for deploying rdt-client with manual download feature on Kubernetes/TrueNAS SCALE.

## Installation

### Quick Install with Default Values

```bash
helm install rdt-client ./rdt-client-manual-download
```

### Install with Custom Values

```bash
helm install rdt-client ./rdt-client-manual-download \
  --set persistence.downloads.hostPath=/mnt/pool/downloads \
  --set persistence.database.hostPath=/mnt/pool/appdata/rdt-client \
  --set service.type=LoadBalancer
```

### Install with Custom values.yaml

```bash
# Copy and edit values
cp values.yaml my-values.yaml
nano my-values.yaml

# Install
helm install rdt-client ./rdt-client-manual-download -f my-values.yaml
```

## Configuration

### Key Configuration Options

#### Image

```yaml
image:
  repository: erix12/rdt-client-manual-download
  tag: latest
  pullPolicy: Always
```

#### Service

```yaml
service:
  type: ClusterIP  # Options: ClusterIP, NodePort, LoadBalancer
  port: 6500
```

#### Persistence

**Option 1: Host Path (TrueNAS)**
```yaml
persistence:
  downloads:
    hostPath: /mnt/pool/downloads
  database:
    hostPath: /mnt/pool/appdata/rdt-client
```

**Option 2: PVC (Dynamic Provisioning)**
```yaml
persistence:
  downloads:
    enabled: true
    storageClass: "nfs-client"
    size: 100Gi
  database:
    enabled: true
    storageClass: "nfs-client"
    size: 1Gi
```

**Option 3: Existing PVC**
```yaml
persistence:
  downloads:
    existingClaim: "my-downloads-pvc"
  database:
    existingClaim: "my-database-pvc"
```

#### Environment Variables

```yaml
env:
  BASE_PATH: /rdtclient  # For reverse proxy
  LOG_LEVEL: Warning     # Error, Warning, Information, Debug
```

#### Resources

```yaml
resources:
  limits:
    cpu: 1000m
    memory: 1Gi
  requests:
    cpu: 100m
    memory: 256Mi
```

#### Security Context

```yaml
securityContext:
  runAsUser: 568   # TrueNAS app user
  runAsGroup: 568
  fsGroup: 568
```

### Ingress Configuration

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
    - host: rdt.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: rdt-tls
      hosts:
        - rdt.example.com
```

## Examples

### TrueNAS SCALE Deployment

```bash
helm install rdt-client ./rdt-client-manual-download \
  --set persistence.downloads.hostPath=/mnt/pool/downloads \
  --set persistence.database.hostPath=/mnt/pool/appdata/rdt-client \
  --set service.type=LoadBalancer \
  --set securityContext.runAsUser=568 \
  --set securityContext.runAsGroup=568 \
  --set securityContext.fsGroup=568
```

### Behind Traefik Ingress

```bash
helm install rdt-client ./rdt-client-manual-download \
  --set ingress.enabled=true \
  --set ingress.className=traefik \
  --set 'ingress.annotations.traefik\.ingress\.kubernetes\.io/router\.entrypoints=websecure' \
  --set ingress.hosts[0].host=rdt.example.com \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.hosts[0].paths[0].pathType=Prefix \
  --set env.BASE_PATH=""
```

### High Resource Deployment

```bash
helm install rdt-client ./rdt-client-manual-download \
  --set resources.limits.cpu=2000m \
  --set resources.limits.memory=2Gi \
  --set resources.requests.cpu=500m \
  --set resources.requests.memory=512Mi
```

## Upgrading

```bash
# Upgrade with new image version
helm upgrade rdt-client ./rdt-client-manual-download \
  --set image.tag=2.0.120-manual-download

# Upgrade with new values
helm upgrade rdt-client ./rdt-client-manual-download -f my-values.yaml

# Reuse existing values
helm upgrade rdt-client ./rdt-client-manual-download --reuse-values
```

## Uninstalling

```bash
helm uninstall rdt-client
```

**Note:** This will NOT delete PVCs if using dynamic provisioning. Delete manually:
```bash
kubectl delete pvc rdt-client-rdt-client-manual-download-downloads
kubectl delete pvc rdt-client-rdt-client-manual-download-database
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/name=rdt-client-manual-download
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/name=rdt-client-manual-download -f
```

### Check Service

```bash
kubectl get svc -l app.kubernetes.io/name=rdt-client-manual-download
```

### Describe Pod for Events

```bash
kubectl describe pod -l app.kubernetes.io/name=rdt-client-manual-download
```

### Permission Issues

If you get permission errors, check the security context matches your host:

```bash
# Check what user owns the directories on the host
ls -ld /mnt/pool/downloads
ls -ld /mnt/pool/appdata/rdt-client

# Update ownership to match securityContext
chown -R 568:568 /mnt/pool/downloads
chown -R 568:568 /mnt/pool/appdata/rdt-client
```

## Default Values

See [values.yaml](values.yaml) for complete list of configurable values.

## Requirements

- Kubernetes 1.19+
- Helm 3.0+
- Storage provisioner or host paths configured
- Port 6500 available (or configure different port)

## Chart Structure

```
rdt-client-manual-download/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default configuration values
├── templates/
│   ├── deployment.yaml     # Kubernetes Deployment
│   ├── service.yaml        # Kubernetes Service
│   ├── pvc.yaml           # PersistentVolumeClaims
│   ├── ingress.yaml       # Ingress configuration
│   └── _helpers.tpl       # Template helpers
└── README.md              # This file
```

## Support

- Issues: https://github.com/erix/rdt-client/issues
- Original Project: https://github.com/rogerfar/rdt-client
