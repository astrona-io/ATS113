# Section 040: Identity: Entities, Aliases And Groups

alice logs in to OpenBao with a userpass account during an outage and through Keycloak every other day. Without the identity system, OpenBao sees two strangers: two sets of tokens, two places to grant policies, and no way to say "alice" in a policy. This section teaches the identity system, which joins logins into one entity, groups entities, and lets one policy template serve every person.

## What you will learn

- Entities and aliases: how every login maps to an entity, and how OpenBao creates them for you.
- Linking two logins to one entity, and merging entities that were created twice.
- Internal groups, whose members you set in OpenBao, and external groups, whose members come from the identity provider.
- Token policies and identity policies, and why identity policies change without a new login.
- Policy templates with `{{identity.entity.name}}` and other identity values.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with the userpass user `alice`, the JWT/OIDC auth method configured for Keycloak with the role `person`, and Keycloak with `alice` (group `ops`) and `bob` (group `dev`).

### 1. Join Logins Into One Identity

1. Entities And Aliases
2. Internal And External Groups, followed by the lab **Give Alice One Identity Across Two Logins**
3. Identity In Policy Templates
4. Summary

## Section capstone: Make Groups From Keycloak Drive Access

alice already has two entities, the external group that should follow Keycloak's group `ops` never matches, and the policy that should give each person a private folder points at the wrong path. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-113-capstone-040
```
