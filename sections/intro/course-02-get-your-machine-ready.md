# Get Your Machine Ready

Every playground and lab in this course runs on your own machine, in a small Kubernetes cluster. A tool called `astrona` builds it for you, sets it up, grades your work and removes it again. This page gets your machine ready: first the tools you need, then the handful of `astrona` commands you will use every day, and last what to do when a start goes wrong.

## What you need

Every section needs the same set of tools. Install these before you start:

- **A container engine:** Docker or Podman. The cluster runs inside it.
- **`kind`:** runs Kubernetes inside the container engine.
- **`kubectl`:** talks to the cluster.
- **The astrona command-line tool.**
- **`jq`:** reads JSON, so you can pick out one field of a token lookup or a login response.
- **`openssl`:** reads certificates in the section on TLS certificate login. macOS and most Linux systems already have it.
- **A web browser:** to log in through Keycloak and to open the OpenBao web user interface.

Two more tools come with every environment, so you do not install them yourself: **Helm 3.22.1** and the **`bao` command-line tool v2.7.1**. Each playground and lab puts the pinned versions in `/usr/local/bin` or `~/.local/bin`, so the versions always match the server.

The playgrounds and labs need **outbound internet** while they start. They download Helm, `bao` and the OpenBao Helm chart, and they pull the OpenBao, Keycloak and tester images. Without outbound internet, those starts fail with errors that have nothing to do with OpenBao.

## Reaching OpenBao

OpenBao runs inside the cluster, so your machine reaches it through a port-forward. Every page that uses `bao` asks you to start it in a second terminal and leave it running:

```sh
kubectl -n openbao port-forward svc/openbao 8200:8200
```

The address is always `http://openbao.localtest.me:8200`. The name `openbao.localtest.me` is a public DNS name that points at `127.0.0.1`, your own machine, so the port-forward answers it. Inside the cluster, the same name points at the OpenBao Service, so the pages, the pods and the graders all use one address. In the modules about people, Keycloak works the same way at `http://keycloak.localtest.me:8080`.

Then tell `bao` where OpenBao is and which token to use. The environment keeps a lab-only root token in a Kubernetes Secret, so you can start working at once:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
```

A real installation never keeps its root token in a Kubernetes Secret, and it revokes the root token once setup is done. The labs keep it so you can set things up quickly; the tokens you create for people and machines are the real subject.

Some home routers block DNS answers that point at `127.0.0.1`. If a command says it cannot resolve `openbao.localtest.me`, add this line to `/etc/hosts` on your machine:

```
127.0.0.1 openbao.localtest.me keycloak.localtest.me
```

You do not have to check your tools by hand. Let `astrona` look at your machine for you:

```sh
astrona setup
```

`astrona setup` looks at what is missing, shows you each step it would take, and asks before it does anything. On macOS it can install `kind`, `kubectl` and Podman. Install `jq` yourself.

Later, you can check your machine at any time:

```sh
astrona check
```

## The commands you use every day

Once your machine is ready, you need only a handful of `astrona` commands. Each module page and lab page shows the exact command to copy, so you do not need to remember paths. This section walks through them in the order you meet them: sign in, start, pause, submit and clean up.

Labs from the course catalog are tied to your Astrona account, so you sign in first:

```sh
astrona login
```

Next you start a playground or a lab. Each module page and lab page shows the exact `astrona run` command for it. It looks like this:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-01/playground
```

When the cluster is ready, `kubectl` already points at it.

A chapter that sends you to a lab asks you to pause the playground first. Pausing frees your machine's memory but keeps everything you built:

```sh
astrona stop <name>
```

When the lab is done, start the playground again and carry on where you left off:

```sh
astrona start <name>
```

Inside a lab, you send your work for grading with `astrona submit`. The grader checks the live cluster. It logs in to OpenBao as the lab's people and machines and reads OpenBao's own settings, so your fix has to actually work, not only make an error message go away. Each lab page shows the exact command:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

You can submit as often as you like.

When you are done with a playground or a lab, remove it:

```sh
astrona destroy <name>
```

The name is the environment's name, printed by `astrona run` and shown on each page (for example `ats-113-playground-010-01`). It is not the folder path. To see what is on your machine, list it:

```sh
astrona list
```

> [!WARNING]
> **Run one environment at a time.** Each playground and lab is a whole cluster with its own OpenBao. Two running at once can use up your machine's memory, and it is easy to send a command to the wrong one. Pause or destroy the playground before you start the lab.

## When a start goes wrong

Sometimes a playground or lab does not start cleanly. Ask `astrona` what is wrong before you try anything else:

```sh
astrona doctor
```

It checks your machine, the lab's configuration and the running lab, and tells you how to fix what it finds.

If a start fails while it downloads something, check your network first. If `bao` cannot reach OpenBao, check that the port-forward is still running in your second terminal; it stops when the OpenBao pod restarts. If `bao status` says OpenBao is sealed, the pod restarted: unseal it with the lab-only key from the Secret `openbao-init`. Remember also that a lab that starts with a refused login is often broken on purpose: the lab's task tells you when that is the case. With your machine ready and these commands at hand, you can start the first module.
