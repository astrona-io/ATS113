# TLS Certificate Auth

Some machines already carry a certificate: a host with a certificate from the company's certificate authority, or a job that uses mutual TLS everywhere else. For them, the certificate itself can be the login. TLS certificate auth checks the client certificate that the client presents during the TLS handshake, so there is no extra secret to deliver at all.

## How the login works

**TLS certificate auth** (`cert`) is an auth method that logs a client in with the certificate it presents in the TLS handshake. A role in this method is called a **certificate role**: it holds the certificate authority (CA) that must have signed the client certificate, and conditions on the certificate, such as its common name. Because the certificate travels inside TLS, the login only works on a listener that uses TLS; a plain HTTP listener never sees a client certificate.

Your playground has such a listener. OpenBao listens with TLS on port `8443`, reached inside the cluster as `https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443`. The environment created a lab CA, signed the listener's server certificate with it, and signed one client certificate with the common name `reporting-job`. That client certificate is mounted in the `tester` pod at `/certs`.

## Look at the client certificate

Before you trust a certificate, read it. Copy the lab CA and the client certificate out of the Secret and print their subjects:

<!-- astrona:playground:renew -->

```sh
kubectl -n clients get secret client-tls -o jsonpath='{.data.ca\.crt}' | base64 -d > lab-ca.pem
kubectl -n clients get secret client-tls -o jsonpath='{.data.tls\.crt}' | base64 -d > reporting-job.pem
openssl x509 -in reporting-job.pem -noout -subject -issuer -ext extendedKeyUsage
```

`openssl` shows the subject `CN = reporting-job`, the issuer `CN = lab-ca`, and the extended key usage `TLS Web Client Authentication`. A certificate used to log in must allow client authentication.

## Create a certificate role

Enable the auth method and create a certificate role that trusts the lab CA, accepts only the common name `reporting-job`, and gives the policy `reporting`:

```sh
export BAO_ADDR=http://openbao.localtest.me:8200
export BAO_TOKEN=$(kubectl -n openbao get secret openbao-init -o jsonpath='{.data.root-token}' | base64 -d)
bao auth enable cert
bao write auth/cert/certs/reporting certificate=@lab-ca.pem \
  allowed_common_names=reporting-job token_policies=reporting token_ttl=1h
```

The `@` in `certificate=@lab-ca.pem` tells `bao` to read the value from the file. Without `allowed_common_names`, every certificate the lab CA ever signed could log in with this role; in a real company CA, that could be thousands of hosts.

## Log in with the certificate

The tester pod presents its client certificate to the TLS listener. It names the role in the request body, so OpenBao checks the certificate against that role only:

```sh
kubectl -n clients exec deploy/tester -- curl -s \
  --cacert /certs/ca.crt --cert /certs/tls.crt --key /certs/tls.key \
  -X POST -d '{"name":"reporting"}' \
  https://openbao-0.openbao-internal.openbao.svc.cluster.local:8443/v1/auth/cert/login
```

The response has an `auth` block with a `client_token` and the policies `default` and `reporting`. `--cacert` is for the client's side: it lets `curl` trust OpenBao's server certificate. `--cert` and `--key` are the client certificate OpenBao checks. Send the same request without `--cert` and `--key`, and OpenBao refuses the login, because no client certificate arrived.

You can now log a machine in with a certificate it already has, limited to one CA and one common name. With AppRole, Kubernetes auth and certificates, every kind of machine you are likely to meet can get a short-lived token without a pasted secret.

## Common pitfalls

> [!WARNING]
> - **Trying certificate login on a plain HTTP listener.** No TLS handshake means no client certificate. Use a listener with TLS.
> - **Trusting the whole CA.** Without `allowed_common_names` or another constraint, any certificate the CA signed can log in.
> - **A certificate without client authentication.** If its extended key usage does not include client authentication, the TLS handshake or the login fails.
> - **Mixing up the two CAs.** `--cacert` lets the client trust the server; the role's `certificate` lets OpenBao trust the client. In this lab one CA signed both, which is not true everywhere.
