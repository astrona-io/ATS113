# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS113 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Authentication Methods & Identity Management**
  domain of the **OpenBao** training path (`ATP022`). It is 20% of the path.
  There is no official OpenBao certification exam; the path's domains and
  weights are Astrona's own, set in `ATP022/path.yaml`.
- **What the domain really tests:** getting the right token to the right
  person or machine. The student must *do* things: create and renew tokens,
  configure AppRole, Kubernetes, TLS certificate, userpass and OIDC/JWT
  login, and join several logins into one identity. Every explanation should
  lead to a command the reader can run, and every fix should be proved with a
  real login that returns a token with the expected policies, or is refused.
- **The four topics:** tokens and the token auth method, authentication for
  machines, authentication for people, and the identity system (entities,
  aliases and groups).
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | Tokens And The Token Auth Method | Tokens |
  | 020 | Authentication For Machines | AppRole, Kubernetes, TLS certificates |
  | 030 | Authentication For People | Userpass, OIDC and JWT |
  | 040 | Identity: Entities, Aliases And Groups | Identity |

- **The versions:** **OpenBao v2.7.1** (server image `quay.io/openbao/openbao`
  and the `bao` CLI from the release archive), installed with the `openbao`
  Helm chart **0.30.4** (`appVersion` v2.7.1) and Helm **3.22.1** on a
  single-node `kind` cluster. **Keycloak 26.8.1** is the OpenID Connect
  provider in sections 030 and 040. The documentation version is 2.7.x. Do
  not teach fields, flags or output from other versions without saying so.
- **The main sources:** the OpenBao documentation, <https://openbao.org/docs/>,
  and the source of `openbao/openbao` at tag `v2.7.1` (the docs are under
  `website/content/docs/`, the API reference under
  `website/content/docs/api/`). Check every page against them.
- **OpenBao is not Vault.** OpenBao is a fork of HashiCorp Vault 1.14 under
  the Linux Foundation (LF Projects, an OpenSSF sandbox project). Use OpenBao
  names (`bao`, `BAO_ADDR`, `BAO_TOKEN`). The HTTP API still uses the header
  `X-Vault-Token` and the web UI path `/ui/vault/`; say so where a page uses
  them, because readers expect `Bao` there.

### Status: built, not yet run

The first version of this repository was written from the OpenBao 2.7
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

Facts most likely to be wrong, in order (check these first):

1. **Keycloak's `groups` claim in the ID token.** The seed adds a group
   membership mapper to the client `openbao` with `full.path=false`, so the
   claim should be `["ops"]`, not `["/ops"]`. Every grader in sections 030
   and 040 depends on it.
2. **TLS certificate login.** The section 020 environments add a second
   listener on port `8443` with TLS and reach it through the headless Service
   name `openbao-0.openbao-internal.openbao.svc.cluster.local`. It assumes the
   listener asks for a client certificate by default and that the chart's
   `server.extraVolumes` mounts the Secret at `/openbao/userconfig/openbao-tls/`.
3. **Token role fields.** `token_period`, `token_explicit_max_ttl` and
   `token_type` on `auth/token/roles/<name>` follow the shared token
   parameters; the token API page lists only some of them.
4. **Kubernetes auth with the pod's own service account.** The config sets
   only `kubernetes_host`; OpenBao reads its own token and CA from
   `/var/run/secrets/kubernetes.io/serviceaccount/`, and the chart's
   `server.authDelegator.enabled` (default `true`) gives it
   `system:auth-delegator`.
5. **AppRole `secret_id` CIDR limits.** The section 020 capstone assumes a
   `secret_id` keeps the `secret_id_bound_cidrs` it was created with, so the
   solution generates a new `secret_id` after clearing the role's limit.
6. **Identity aliases from JWT login.** The alias name is the value of
   `user_claim` (`preferred_username`), so it matches the userpass user name
   `alice` only because both are `alice`.

### Terms, not metaphors

| Term | First-use definition (example wording) |
| --- | --- |
| Token | The credential every request carries; it has policies, a time to live (TTL) and an accessor |
| Accessor | A second ID of a token that can look it up, renew or revoke it, but not use it |
| TTL / max TTL / explicit max TTL | How long a token or lease is valid now / the longest it can be renewed to / a hard limit set on the token itself |
| Periodic token | A token whose TTL is reset to its period at every renewal, so it lives as long as it is renewed |
| Service token / batch token | A token stored by OpenBao that can be renewed and has child tokens / a lightweight encrypted token that cannot be renewed |
| Orphan token | A token with no parent, so it is not revoked when the token that created it is revoked |
| Token role | A template on `auth/token/roles/<name>` that fixes the settings of tokens created through it |
| Auth method | A plugin, mounted at a path, that checks some proof of identity and returns a token |
| AppRole | An auth method for machines: a public `role_id` plus a secret `secret_id` |
| Kubernetes auth | An auth method that checks a pod's service account token with the Kubernetes TokenReview API |
| TLS certificate auth | An auth method that checks the client certificate presented in the TLS handshake against a trusted CA |
| JWT / OIDC auth | One auth method with two kinds of role: `jwt` checks a signed token sent by the client, `oidc` runs a browser login with the provider |
| Entity | One person or machine in OpenBao's identity system |
| Alias | The link between an entity and its account in one auth mount, keyed by the mount accessor |
| Internal / external group | A group whose members are set in OpenBao / a group whose members come from the provider, through a group alias |

### The example workloads

| Name | What it is |
| --- | --- |
| OpenBao (namespace `openbao`, Helm release `openbao`) | OpenBao v2.7.1, pod `openbao-0`, Service `openbao` on port `8200`, Integrated Storage (`raft`), no TLS on port 8200 (lab-only). Every environment starts initialized and unsealed |
| Secret `openbao-init` (namespace `openbao`) | The lab-only unseal key (`unseal-key`) and root token (`root-token`). Say on the page that a real installation never keeps these in a Kubernetes Secret |
| `tester` (namespace `clients`) | `nicolaka/netshoot:v0.13` with `curl` and `jq`; graders log in from here. In section 020 it also mounts the client certificate at `/certs` |
| `inventory-app` (namespace `inventory`, section 020) | `nicolaka/netshoot:v0.13` running as the ServiceAccount `inventory`; it logs in with Kubernetes auth |
| Keycloak (namespace `keycloak`, sections 030 and 040) | Keycloak 26.8.1 in development mode at `http://keycloak.localtest.me:8080`, realm `inventory`, users `alice` (group `ops`) and `bob` (group `dev`), passwords `alice-password` and `bob-password`, confidential client `openbao` with secret `openbao-client-secret`. Lab-only credentials |

### Environment facts the text must respect

- **One address everywhere: `http://openbao.localtest.me:8200`**, and
  **`http://keycloak.localtest.me:8080`** where Keycloak runs. Inside the
  cluster one CoreDNS `rewrite stop` block per name (with the answer name
  rewritten back) sends the name to the Service. On the reader's machine,
  `kubectl -n openbao port-forward svc/openbao 8200:8200` and
  `kubectl -n keycloak port-forward svc/keycloak 8080:8080` make them answer.
  Because OpenBao and the browser both use `keycloak.localtest.me`, the
  issuer in Keycloak's tokens is the same everywhere. Never use the one-line
  `rewrite name` form.
- **The `bao` CLI runs on the reader's machine** with
  `export BAO_ADDR=http://openbao.localtest.me:8200` and the lab-only root
  token from `openbao-init` in `BAO_TOKEN`. Scripts use the `bao` in the
  server image through
  `kubectl -n openbao exec -i openbao-0 -- env BAO_ADDR=http://127.0.0.1:8200 BAO_TOKEN=... bao ...`.
- **A pod restart seals OpenBao.** Bootstrap scripts unseal it with the key in
  `openbao-init`; pages that restart it show the unseal step.
- **Server configuration changes need a pod delete.** The chart's StatefulSet
  uses `updateStrategyType: OnDelete` and no configuration checksum, so a
  changed listener or storage block needs `helm upgrade`, then
  `kubectl -n openbao delete pod openbao-0`, then an unseal. No ATS113 lab
  changes the server configuration after install: the section 020 TLS
  listener is in the Helm values from the first install.
- **`bao login` writes the token helper file** (`~/.bao-token`). `BAO_TOKEN`
  in the environment wins over it, so pages run logins in a subshell with
  `unset BAO_TOKEN` and keep the lab-only root token in `BAO_TOKEN`.
- **Keycloak's password grant is for automation only.** Labs grade OIDC and
  JWT logins with an ID token from Keycloak's password grant (client
  `openbao` has direct access grants on). Say on each page that uses it that a
  person logs in with `bao login -method=oidc` in a browser, and that the
  password grant is a lab shortcut.
- **Many environments start broken on purpose.** The fault is the material.
  Never "fix" it in the bootstrap.

### Where things are in this repo

The layout is the same as every Astrona course: `astrona.yaml`, `README.md`,
`sections/intro/`, `sections/section-0N0/README.md`, module pages
(`course.md`, `course-0N-*.md`), `playground/` (`config.yaml`,
`bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`), labs
(`config.yaml`, `README.md`, `prerequisites.md`, `question.md`,
`solution.md`, `bootstrap/01-install-openbao.sh`, `bootstrap/02-seed-state.sh`,
`manifests/`, `solution/apply.sh`, `testing/wait-for-openbao.sh`,
`validation/validate-*.sh`) and one capstone per section.

The plumbing of all twelve environments (manifests, install, seed, testing,
solution and validation scripts, `config.yaml`, author READMEs and
`prerequisites.md`) was generated by a script that is not in this
repository. When you change a shared piece, such as the install script, the
CoreDNS block or the `bao_root` helper, change it in **every** environment.

### Lab metadata in `astrona.yaml`

`training:` block: id `ATS113`, domain `Authentication Methods & Identity
Management`, weight `20`. Lab entries carry `title`, `path`, `difficulty`,
`estimated_duration`, `topic`, `task_kind`, `tags`, `learning_goals`,
`resources`, in that order, as in ATS016.

- `topic`: exactly one of `tokens`, `machine-auth`, `human-auth`, `identity`.
- `task_kind`: `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8, only from this list: `token`, `token-ttl`,
  `periodic-token`, `orphan-token`, `batch-token`, `token-role`, `accessor`,
  `approle`, `secret-id`, `kubernetes-auth`, `service-account`,
  `cert-auth`, `tls`, `userpass`, `oidc`, `jwt`, `keycloak`, `groups-claim`,
  `bound-claims`, `entity`, `entity-alias`, `internal-group`,
  `external-group`, `group-alias`, `policy-template`, `policy`.
- `resources`: 1 to 4 pages on `openbao.org`. The only place outside links
  are allowed.

### Running things

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-01/playground
astrona destroy ats-113-playground-010-01
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-113-lab-010-01
astrona test -c sections/section-010/module-01/labs/lab-01   # authors
```

Names: `ats-113-playground-<section>-<module>`, `ats-113-lab-<section>-<module>`,
`ats-113-capstone-<section>`. Graders check **behaviour**: a real login that
returns a token with the expected policies, a login that must be refused, a
token lookup with the expected fields, and the same `entity_id` from two
logins. They reject the plausible but wrong fix (handing out the root token,
adding `root` or a broad policy, binding a role to every service account or
namespace with `*`, deleting and recreating an entity so its ID changes). A
lab's `question.md` and `solution.md` must match what its `validation/`
scripts check.

### Where to find trusted sources

- **Tokens:** <https://openbao.org/docs/concepts/tokens/>,
  <https://openbao.org/docs/auth/token/>,
  <https://openbao.org/docs/api/auth/token/>
- **Machine auth:** <https://openbao.org/docs/auth/approle/>,
  <https://openbao.org/docs/auth/kubernetes/>,
  <https://openbao.org/docs/auth/cert/>
- **Human auth:** <https://openbao.org/docs/auth/userpass/>,
  <https://openbao.org/docs/auth/jwt/>, <https://openbao.org/docs/auth/login-mfa/>
- **Identity:** <https://openbao.org/docs/concepts/identity/>,
  <https://openbao.org/docs/api/secret/identity/entity/>,
  <https://openbao.org/docs/concepts/policies/> (templated policies)
