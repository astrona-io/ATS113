# Join Logins Into One Identity — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-113-playground-040-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

A sandbox that starts OpenBao v2.7.1 initialized and unsealed and stays
running, so you can explore the module's topic. Nothing to submit. Built from
the OpenBao 2.7 documentation and not yet run (see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona destroy ats-113-playground-040-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-113-playground-040-01`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition |
| `bootstrap/prepare.sh` | Installs the tools, OpenBao and the extras, then initializes and unseals |
| `manifests/` | Helm values, client pods and (where used) Keycloak |
| `docs/overview.md` | What the environment contains and ideas to try |
