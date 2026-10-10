# Contributing

## Developer Certificate of Origin

Contributions are accepted under the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/). Every commit must carry a `Signed-off-by` trailer with your real name and email address. Git adds it when you commit with `git commit -s`.

The Foundation does not require a Contributor License Agreement; you retain copyright in your contributions. All contributions are accepted under the Apache License, Version 2.0 (see [LICENSE](LICENSE)).

## If you forgot the sign-off

Either amend and force-push your branch (`git commit --amend -s && git push -f`), or post a comment on the pull request stating: "I certify the contents of this contribution under the DCO, Signed-off-by: Your Name <you@example.com>". A maintainer will proceed. The DCO check stays red in that case, and the comment is the record that satisfies the policy.

## Checks

Every pull request runs two checks: `dco` (sign-offs) and `validate` (formatting, `tofu validate` on each stack, and `scripts/check-repo.py`, which rejects committed state files, variable files, keys, and dash or quote style problems). Run `python3 scripts/check-repo.py` locally before you push. These checks never have cloud credentials, and they must not be given any.

## Practical notes

- Run `tofu fmt -recursive` and `tofu validate` in any stack you change.
- Never commit state files, `.tfvars` files, keys, or tokens. The `.gitignore` blocks the usual ones; check `git status` before you commit anyway.
- A change that makes a host easier to leave running, such as opening a port wider or removing a timer, needs a stated reason in the pull request.
- Text files use LF line endings, which [.gitattributes](.gitattributes) enforces.
- Foundation materials use US English, with no em or en dashes.
