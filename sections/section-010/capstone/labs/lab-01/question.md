# Question

Solve this question on: `terminal`

**Time:** about 30 minutes · **Topic:** Tokens

## Scenario

The reporting service gets its tokens from the token role `reporting`. Someone set the role up in a hurry. Its tokens die when the administrator who created them logs out, they stop working after one hour no matter how often they are renewed, and the role lets anyone who may use it ask for the `admin` policy. To make things worse, the token stored for the service has been pasted into a public chat. Its accessor is in the ConfigMap `leaked-token` in the namespace `clients`.

## Your task

1. Fix the token role `reporting` so that it:
   - allows only the policy `reporting`;
   - issues orphan tokens;
   - issues periodic tokens with a period of 24 hours;
   - has no explicit max TTL.
2. Revoke the leaked token, using the accessor in the ConfigMap `leaked-token`.
3. Issue a new token through the role, with the policy `reporting`, and store it in the Secret `reporting-token` in the namespace `clients`, under the key `token`.

## Constraints

- Keep the role's name `reporting`.
- Do not change the policies `reporting` or `admin`.
- The new token must come from the role, not from a plain `bao token create`.

## Done when

- The role allows exactly `reporting`, issues orphan tokens with a 24-hour period and has no explicit max TTL, and refuses to create a token with `admin`.
- The leaked token no longer exists.
- The token in `reporting-token` was created through the role, is an orphan periodic token with `reporting`, and can read `secret/reports/q3`.
