# ATS113 — Authentication Methods & Identity Management (OpenBao)

Course material for the **Authentication Methods & Identity Management**
domain of the Astrona OpenBao training path
([ATP022](https://github.com/astrona-io/ATP022)), which is **20% of the
path**. Written for **OpenBao v2.7.1**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the OpenBao 2.7 documentation and the v2.7.1 source. None has been
> started on a cluster, and no lab has passed `astrona test` yet. See
> `CLAUDE.md` for the facts to check first.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining the section into a single
  scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | Tokens And The Token Auth Method | 3 | 3 + capstone | Tokens, auth methods, response wrapping |
| [020](sections/section-020) | Authentication For Machines | 2 | 2 + capstone | AppRole, Kubernetes, TLS certificates |
| [030](sections/section-030) | Authentication For People | 2 | 2 + capstone | Userpass, OIDC, JWT with Keycloak, LDAP |
| [040](sections/section-040) | Identity: Entities, Aliases And Groups | 2 | 2 + capstone | Identity, entity operations, identity tokens |

The order follows how a team sets OpenBao up: tokens first, because every
login ends in one; then machines, which cannot type a password; then people,
through an identity provider; and last the identity system that joins several
logins of one person.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Work With OpenBao Tokens](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 010-02 | [Manage Authentication Methods](sections/section-010/module-02/course.md) | 4 | [lab-01](sections/section-010/module-02/labs/lab-01) |
| 010-03 | [Response Wrapping And The Cubbyhole](sections/section-010/module-03/course.md) | 4 | [lab-01](sections/section-010/module-03/labs/lab-01) |
| 020-01 | [Log Machines In Without Long-Lived Secrets](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 020-02 | [Run AppRole In Production](sections/section-020/module-02/course.md) | 4 | [lab-01](sections/section-020/module-02/labs/lab-01) |
| 030-01 | [Log People In With Userpass And Keycloak](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 030-02 | [Log People In From A Directory With LDAP](sections/section-030/module-02/course.md) | 4 | [lab-01](sections/section-030/module-02/labs/lab-01) |
| 040-01 | [Join Logins Into One Identity](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |
| 040-02 | [Entity Operations And Identity Tokens](sections/section-040/module-02/course.md) | 4 | [lab-01](sections/section-040/module-02/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair A Token Role For A Reporting Service | the role allows `admin`, issues child tokens, has no period and a hard limit; a leaked token |
| [020](sections/section-020/capstone/labs/lab-01) | Repair Three Machine Logins | a misspelled namespace, a secret ID bound to the wrong network, the wrong certificate common name |
| [030](sections/section-030/capstone/labs/lab-01) | Repair A Broken Keycloak Login | the wrong realm, the wrong audience, the wrong groups claim, a break-glass account without its policy |
| [040](sections/section-040/capstone/labs/lab-01) | Make Groups From Keycloak Drive Access | a duplicate entity, a group alias with the wrong name, a policy template on the wrong path |

---

## The lab environment

Every playground and lab is a **kind** cluster with OpenBao v2.7.1 installed by
the `openbao` Helm chart 0.30.4, already initialized and unsealed. The lab-only
unseal key and root token are kept in the Secret `openbao-init`. OpenBao answers
at `http://openbao.localtest.me:8200` both on the reader's machine (through a
port-forward) and inside the cluster (through a CoreDNS rewrite). Section 020
adds a TLS listener and client certificates; sections 030 and 040 add Keycloak
26.8.1 at `http://keycloak.localtest.me:8080`. The LDAP module adds OpenLDAP 1.5.0 in the namespace `ldap`.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final state** of OpenBao with real logins, and several
checks reject the plausible-but-wrong fix: handing out the root token, binding
a role to every namespace or group, accepting any audience, or deleting and
recreating an entity.
