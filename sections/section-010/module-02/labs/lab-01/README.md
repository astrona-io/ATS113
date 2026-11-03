---
estimated_duration: 15m
---

# Set Up A Tuned Staff Login

- **ID:** LAB
- **Slug:** ats-113-lab-010-02
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab for OpenBao v2.7.1. Read `question.md` for the task; `solution.md`
is the walkthrough. Built from the OpenBao 2.7 documentation and not yet run
(see the repository `CLAUDE.md`).

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-113-lab-010-02
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-113-lab-010-02`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/01-install-openbao.sh` | Tools, OpenBao (initialized and unsealed) and the extras |
| `bootstrap/02-seed-state.sh` | The starting state of the task |
| `manifests/` | Helm values, client pods and (where used) Keycloak |
| `solution/apply.sh` | Reference solution used by `astrona test` |
| `testing/wait-for-openbao.sh` | Waits until OpenBao answers unsealed |
| `validation/` | Grading scripts, one per check |
