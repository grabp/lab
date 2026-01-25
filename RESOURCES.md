# Resource Pool Limits — Quick Lookup
**Disk limits are the critical column**

| Pool            | Purpose                         | CPU (cores) | Memory (MB) | Disk (GB) | Recommended Disk | Why                          |
|-----------------|----------------------------------|-------------|-------------|-----------|------------------|------------------------------|
| infrastructure | DNS, Caddy, NetBird              | 3           | 1280        | 10        | 20               | Logs + certs need margin     |
| monitoring     | Prometheus, Grafana, Loki        | 6           | 4096        | 50        | 150              | Prom + Loki grow fast        |
| services       | Home Assistant, Kuma             | 4           | 3072        | 40        | 100              | HA dominates storage         |
| docker         | Docker host VM                   | 2           | 2048        | 32        | 48               | Image & log churn            |

---

## Per-Service Disk Expectations (Reference)
Use this to sanity-check pool growth.

| Service           | Typical Disk | Notes                    |
|-------------------|--------------|--------------------------|
| Pi-hole           | 2–5 GB       | Mostly logs              |
| Caddy             | 1–2 GB       | Certs + access logs      |
| NetBird           | 2–5 GB       | Config + logs            |
| Prometheus        | 50–100 GB    | Retention-dependent      |
| Loki              | 50–100 GB    | Log volume heavy         |
| Grafana           | 1–5 GB       | Metadata only            |
| Home Assistant    | 50–100 GB    | History + DB             |
| Uptime Kuma       | 1–5 GB       | Lightweight              |
| Portainer         | 1–2 GB       | UI + metadata            |
| Docker images     | 20–40 GB     | Grows silently           |

---

## Recommended Final Pool Targets (TL;DR)
**If you only remember one thing:**

| Pool            | Disk (GB) |
|-----------------|-----------|
| infrastructure | 20        |
| monitoring     | 150       |
| services       | 100       |
| docker         | 48        |

