# Summary

LDAP auth lets OpenBao check a person's password against a directory they already have. One login is several directory requests: OpenBao binds as a search account, searches for the user's DN, binds again as that DN with the person's password, searches for the groups, and then builds a token from the policies mapped to the user and the groups.

Each step has its own setting. The `url` and the TLS fields control the connection. The `binddn` and `bindpass` identify the read-only search account. The `userdn` and `userattr` find the person, and `userattr` must match the attribute people log in with, often `uid`. The `groupdn`, `groupattr` and `groupfilter` find the groups and read their names.

Policies come from two mappings. A group mapping, named after the group's `groupattr` value, gives policies to every member. A user mapping adds policies for one person. The token gets the union of `default`, the group policies and the user policies. A user with no mapping gets only `default`: the login works and no secret is readable. Policies are read at login, so a change in the directory applies to the next login and not to live tokens.

Passwords must not travel in clear text, so use LDAPS or StartTLS with the directory's CA certificate and never `insecure_tls`. Keep `deny_null_bind` on, because an empty-password bind can look like a success. When a login fails, run the same searches with `ldapsearch` first, because they are the requests OpenBao makes.

- `userattr` must match what people type as their user name.
- A group mapping uses the group's name, not its DN.
- Rotate `bindpass` in the directory and in OpenBao together.

<!-- astrona:playground:destroy -->
