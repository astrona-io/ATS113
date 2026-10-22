# Section 010: Tokens And The Token Auth Method

Every request to OpenBao carries a token, and every login, whatever the auth method, ends with OpenBao handing out a token. So before you set up logins for people and machines, you need to know what a token is, how long it lives and what happens to it when it is renewed or revoked. This section teaches exactly that, with the `bao token` commands you will use in every later section.

## What you will learn

- What a token carries: its policies, time to live (TTL), accessor and type.
- The difference between a TTL, a max TTL and an explicit max TTL, and what renewal does to each.
- Periodic tokens for long-running services that renew themselves.
- Service and batch tokens, the token tree, and orphan tokens that survive their parent.
- Token roles, which fix the settings of the tokens a service may create.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao, initialized and unsealed, with a KV engine at `secret/` and the policies `inventory-read` and `reporting`.

### 1. Work With OpenBao Tokens

1. What A Token Carries
2. TTLs, Renewal And Periodic Tokens, followed by the lab **Issue A Periodic Token For A Service**
3. Service And Batch Tokens, Orphans And Token Roles
4. Summary

## Section capstone: Repair A Token Role For A Reporting Service

A reporting service gets its tokens from a token role that was set up in a hurry. The role allows a far too broad policy, issues tokens that die with their parent, and has a hard limit instead of a period. One of its tokens has also leaked. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-113-capstone-010
```
