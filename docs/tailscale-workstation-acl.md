# Tailnet ACL grant for the workstation dev VM

**Status: DOCUMENTATION ONLY — not applied to the tailnet.**

The workstation joins the tailnet as a tagged node (`tag:workstation`, advertised
by `modules/workstation/tailscale.nix`). Tagged nodes are **not reachable by
default** once the tailnet ACL is tightened — you must explicitly grant your
devices access to `tag:workstation`. Full L3 + `trustedInterfaces = [ "tailscale0" ]`
on the box then makes every dev-server port reachable over MagicDNS
(`http://workstation:<port>`), provided the server binds `0.0.0.0`.

Add the following to the tailnet policy file (Tailscale admin console → Access
Controls). This grants all tailnet members all TCP ports on the box for dev use;
scope `"*"` down to specific ports if you want to tighten it.

```jsonc
{
  // Declare the tag and who may own/mint keys for it.
  "tagOwners": {
    "tag:workstation": ["autogroup:admin"]
  },

  "acls": [
    // Members -> workstation, all TCP ports (dev use).
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:workstation:*"]
    }
  ],

  // Optional: allow Tailscale SSH into the box for members.
  "ssh": [
    {
      "action": "accept",
      "src": ["autogroup:member"],
      "dst": ["tag:workstation"],
      "users": ["root", "autogroup:nonroot"]
    }
  ]
}
```

To scope to specific devices instead of all members, replace
`"autogroup:member"` with the device owners or `tag:`/host references, e.g.
`["you@github", "tag:laptop"]`, and to expose only chosen ports replace
`tag:workstation:*` with `tag:workstation:8080,3000`.
