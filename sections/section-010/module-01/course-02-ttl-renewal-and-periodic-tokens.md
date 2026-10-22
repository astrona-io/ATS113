# TTLs, Renewal And Periodic Tokens

A token that never expires is a risk, and a token that expires while a service still needs it is an outage. OpenBao solves this with renewal: a token lives for a short time, and the client asks for more time while it still needs the token. This part shows how renewal works, where it stops, and how a periodic token lets a service run as long as it keeps renewing.

## TTL, max TTL and explicit max TTL

Every token has a **time to live (TTL)**: the time it stays valid from now. When the TTL reaches zero, OpenBao revokes the token. A renewable token can ask for a new TTL, but only up to a ceiling. Three settings decide that ceiling:

| Setting | What it limits |
| --- | --- |
| TTL | How long the token is valid from its creation or its last renewal |
| Max TTL | The longest total lifetime, set by the system, the auth mount or the role; renewals cannot go past it |
| Explicit max TTL | A hard limit set on the token itself; it wins over every other max TTL |

The system default and max TTL are both 32 days (`768h`) unless an administrator changes them. Create a token with a short TTL and a hard limit, then renew it:

<!-- astrona:playground:renew -->

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
SHORT_TOKEN=$(bao token create -policy=inventory-read -ttl=10m -explicit-max-ttl=30m -field=token)
bao token renew -increment=20m $SHORT_TOKEN
```

The renewal asks for 20 more minutes from now, and OpenBao grants it, because the token is still well inside its 30-minute limit. Renew it again with `-increment=1h`: OpenBao gives back less than an hour, only what is left until the explicit max TTL. Once that limit is reached, no renewal helps, and the client must log in again to get a new token.

## Periodic tokens for services

A web service runs for months, but you still do not want its token to live for months without proof that the service is alive. A **periodic token** gives you both. It has a **period** instead of a fixed lifetime: every renewal resets the TTL back to the period, with no max TTL. As long as the service renews within each period, the token stays valid; if the service stops, the token expires one period later.

```sh
SERVICE_TOKEN=$(bao token create -policy=inventory-read -period=24h -field=token)
bao token lookup $SERVICE_TOKEN
```

The lookup shows `period` set to `24h` and a TTL of about 24 hours. Renew the token with its own credential, the way the service itself would:

```sh
BAO_TOKEN=$SERVICE_TOKEN bao token renew
```

The TTL jumps back to 24 hours. Only a root token or a token with `sudo` on `auth/token/create` can create periodic tokens directly, because a periodic token can live forever if it is renewed. Periodic tokens suit services that run a renewal loop; people should log in again instead.

## A service token should not depend on its creator

One more setting matters for a service. A token created by another token becomes its **child**, and when OpenBao revokes a parent, it revokes all its children too. If an administrator creates the service token with their own login token and that login token is revoked later, the service loses its token as well. An **orphan token** has no parent, so it lives on its own:

```sh
SERVICE_TOKEN=$(bao token create -orphan -policy=inventory-read -period=24h -field=token)
bao token lookup -format=json $SERVICE_TOKEN | jq '.data.orphan'
```

The lookup shows `orphan` as `true`. Creating orphan tokens directly also needs a root token or `sudo` on `auth/token/create`.

## Where a service keeps its token

A service needs its token somewhere it can read it at startup. In Kubernetes that is often a Secret mounted into the pod. Storing a token in a Secret is a stopgap: later in this path you will see auth methods that let a pod get its own token without anyone copying one around. For now, the pattern is simple:

```sh
kubectl -n clients create secret generic demo-token --from-literal=token=$SERVICE_TOKEN
kubectl -n clients get secret demo-token -o jsonpath='{.data.token}' | base64 -d
```

Anyone who can read that Secret can use the token until it expires, so keep its policy as narrow as possible and its period as short as the service allows.

You can now predict what renewal does: a normal token grows back to its TTL until it hits its max TTL, and a periodic token grows back to its period forever, as long as it is renewed. What you have not seen yet is what happens to a token when the token that created it is revoked.

## Common pitfalls

> [!WARNING]
> - **Expecting renewal to go past the max TTL.** Renewal never extends a token past its explicit max TTL or the mount's max TTL. The client must log in again.
> - **Combining a period with an explicit max TTL by accident.** A periodic token with an explicit max TTL still dies at that limit.
> - **Renewing too late.** A token that has already expired cannot be renewed. Renew at about half of the TTL.
> - **Giving people periodic tokens.** A person's session should end. Use normal TTLs for people.

## Your mission: Issue A Periodic Token For A Service

You can now create a periodic token with one policy and store it where a service reads it. The graded lab asks you to issue such a token for the inventory service, make sure it survives the revocation of the token that created it, and keep it narrow enough to read only inventory secrets.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-113-playground-010-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS113.git -c sections/section-010/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-113-lab-010-01
astrona start ats-113-playground-010-01
```
