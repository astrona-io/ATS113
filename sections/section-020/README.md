# Section 020: Authentication For Machines

A job, a pod or a scheduled script cannot type a password, and a long-lived token copied into its configuration is exactly the secret you want to get rid of. OpenBao solves this with auth methods built for machines: each one checks something the machine already has, such as a Kubernetes ServiceAccount token or a TLS client certificate, and hands back a short-lived token with a narrow policy. This section teaches the three machine auth methods you will use most.

## What you will learn

- AppRole: a public `role_id` and a secret `secret_id`, their lifetimes and how to bind them to a network.
- Kubernetes auth: letting a pod log in with its ServiceAccount token, and binding a role to one ServiceAccount in one namespace.
- How OpenBao checks a Kubernetes token with the TokenReview API, and why it needs `system:auth-delegator`.
- TLS certificate auth: trusting a certificate authority and checking the client certificate's common name.
- How to read the error of a refused machine login.

## The learning path

The module starts at its landing page, which also launches the playground. The playground holds OpenBao with a second listener that uses TLS, the namespace `inventory` with the pod `inventory-app` and its ServiceAccount, and a lab certificate authority with one client certificate.

### 1. Log Machines In Without Long-Lived Secrets

1. AppRole For Jobs And Pipelines
2. Kubernetes Auth For Pods, followed by the lab **Let The Inventory App And The CI Job Log In**
3. TLS Certificate Auth
4. Summary

## Section capstone: Repair Three Machine Logins

Three machines cannot log in: the inventory pod, the CI job and the reporting job that uses a client certificate. Each auth method has one small mistake, and each mistake shows a different error. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-113-capstone-020
```
