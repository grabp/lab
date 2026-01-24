# Secrets Management

See [docs/secrets.md](./docs/secrets.md) for complete documentation on secrets management.

## Quick Reference

**Edit secrets:**
```bash
sops secrets/vms/web-1.yaml
```

**Bootstrap secrets (one-time per system):**
```bash
just bootstrap web-1 10.0.0.69
just bootstrap-container app-1 10.0.0.100
```

**Rotate/re-deploy secrets:**
```bash
just rotate-secrets web-1 10.0.0.69
just rotate-secrets-container app-1 10.0.0.100
```

For detailed information, see [docs/secrets.md](./docs/secrets.md).

