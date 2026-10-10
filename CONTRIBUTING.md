# Contributing

## Developer Certificate of Origin

Contributions are accepted under the [Developer Certificate of Origin, Version 1.1](https://developercertificate.org/). Every commit must carry a `Signed-off-by` trailer with your real name and email address. Git adds it when you commit with `git commit -s`.

The Foundation does not require a Contributor License Agreement; you retain copyright in your contributions. All contributions are accepted under the Apache License, Version 2.0 (see [LICENSE](LICENSE)).

## Practical notes

- Run `tofu fmt -recursive` and `tofu validate` in any stack you change.
- Never commit state files, `.tfvars` files, keys, or tokens. The `.gitignore` blocks the usual ones; check `git status` before you commit anyway.
- A change that makes a host easier to leave running, such as opening a port wider or removing a timer, needs a stated reason in the pull request.
- Text files use LF line endings, which [.gitattributes](.gitattributes) enforces.
- Foundation materials use US English, with no em or en dashes.
