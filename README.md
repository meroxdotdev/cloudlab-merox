# Deploy steps

## First

- Deploy docker compose up -d inside the repository and after that enter every folder app one by one
like:

```
cd traefik && docker compose up -d
```

FOR K8S widget make sure: sudo chown 1000:1000 ./config/kubeconfig.yaml