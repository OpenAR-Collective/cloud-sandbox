<!-- Thank you. The checklist below is what review looks for. -->

## What this changes and why

<!-- The problem, the change, and what it affects. -->

## Does it make a host easier to leave running or easier to reach?

<!-- Opening a port wider, lengthening or removing a lifetime timer, raising a quota, or adding a permission needs a stated reason. Write "no" only if you have checked the stacks, policies, and shared first-boot setup. -->

## How I checked it

<!-- For example: tofu plan output reviewed, or a throwaway apply and destroy in my own account. Never paste account IDs, addresses, or keys. -->

## Checklist

- [ ] `tofu fmt -recursive` and `tofu validate` pass in each stack I changed, or I am relying on CI.
- [ ] No state files, `.tfvars` files, keys, tokens, account IDs, or personal addresses are committed.
- [ ] Docs match the change, and follow the house style (US English, no em or en dashes).
- [ ] Commits are signed off (DCO). If I forgot, I will post the retroactive sign-off comment described in CONTRIBUTING.md.
- [ ] I license this contribution under Apache 2.0.
