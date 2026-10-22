# Welcome To The Course

This course trains you for the **Authentication Methods & Identity Management** part of the Astrona **OpenBao** training path. That part is 20% of the path. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, ServiceAccounts, Secrets, `kubectl exec` and `kubectl logs`. You have used the `bao` command-line tool to read and write a secret, and you know that OpenBao must be unsealed before it answers. You do not need to know any auth method yet. Each new idea is explained the first time it appears.

## What you can do at the end

OpenBao gives every caller a token, and the token decides what the caller may do. So this course is about getting the right token to the right person or machine, and nothing more. It asks you to configure logins, try them, and prove that the wrong caller is refused. The course has four topics, and each one turns into skills you will practise.

The first topic is **tokens**. You will learn to:

- Read a token's policies, time to live (TTL), accessor and type.
- Create periodic and orphan tokens and renew them.
- Use token roles to fix the settings of tokens a service may create.

Machines cannot type a password, so the second topic is **authentication for machines**. You will learn to:

- Give a job a `role_id` and a `secret_id` with AppRole.
- Let a pod log in with its Kubernetes ServiceAccount token.
- Log a client in with its TLS client certificate.

People are different again, so the third topic is **authentication for people**. You will learn to:

- Create userpass accounts.
- Log people in through Keycloak with OpenID Connect (OIDC), from the browser and the command line.
- Write roles that check the audience and the groups in a JSON Web Token (JWT).

The fourth topic is **identity**. You will learn to:

- Join several logins of one person into one entity with aliases.
- Give policies to internal and external groups.
- Use identity values in policy templates, so one policy fits every person.

Everything is written for **OpenBao v2.7.1**.

## The words this course uses

The pages use OpenBao's, Kubernetes' and OpenID Connect's own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **token** is the credential every request to OpenBao carries. A **policy** is a set of rules that says which paths a token may use and how. An **auth method** is a plugin, mounted at a path such as `auth/approle/`, that checks some proof of identity and returns a token. A **role** inside an auth method says who may log in through it and which policies the token gets.

The identity system adds three more words:

| Term | What it is |
| --- | --- |
| Entity | One person or machine, no matter how many ways it logs in |
| Alias | The link between an entity and its account in one auth method |
| Group | A set of entities that share policies |

## The example setup in your playground

Every playground and lab runs OpenBao in a small Kubernetes cluster. It starts initialized and unsealed, so you can begin with the task at once. A `tester` pod sends requests to OpenBao, and some modules add an `inventory-app` pod that logs in with its ServiceAccount. The modules about people add Keycloak, an identity provider, with two users: `alice` in the group `ops` and `bob` in the group `dev`.

Each environment uses the same names, so the pages always tell you which pod, user or path to use. Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections, in the order a team usually sets up OpenBao: tokens first, then machines, then people, and last the identity that ties them together.

| Section | What it covers |
| --- | --- |
| 010 | Tokens And The Token Auth Method |
| 020 | Authentication For Machines |
| 030 | Authentication For People |
| 040 | Identity: Entities, Aliases And Groups |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
