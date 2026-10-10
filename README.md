# Cloud Sandbox

Disposable cloud environments for The OpenAR Collective's prototypes, experiments, and tests, defined as code so that anyone on the team can stand one up, use it, and tear it down.

The first workload is performance benchmarking of database-backed software, which needs predictable non-burstable CPU, fast local storage, and runs that last hours to a day. A laptop cannot give repeatable server-class numbers, and it cannot run for a day without being a laptop. A sandbox host can.

**Status: draft.** Both stacks pass `tofu validate`. The AWS stack was applied once, on 2026-10-10, as a two-hour `m6id.large` test in the Foundation's sandbox account: first boot, the local NVMe mount, Docker's data location, and the host-facts file all checked out, and the host was destroyed afterward. The Linode stack has not been applied. See [docs/provider-comparison.md](docs/provider-comparison.md) for the open decisions.

## Principles

- **Nothing stays up.** Every host is expected to be destroyed within hours or days. The tooling makes the destroy path as easy as the create path, and adds a backstop where the provider allows one. See [docs/cost-guardrails.md](docs/cost-guardrails.md).
- **No Foundation or agency data.** The sandbox holds synthetic data only, such as the output of the mock collections data generator. Real account data never goes here.
- **One person's mistake is cheap.** SSH is open to one address, never the world. There are no long-lived credentials in this repository, and state files and variable files are git-ignored.
- **Provider-neutral where it is free to be.** Each provider gets its own small stack. Shared first-boot setup lives in [shared/cloud-init.yaml](shared/cloud-init.yaml), so the machine you land on looks the same on either one.

## Layout

| Path | What it is |
| --- | --- |
| [stacks/aws-host](stacks/aws-host) | One Ubuntu host on AWS EC2, with a self-terminating timer |
| [stacks/linode-host](stacks/linode-host) | One Ubuntu host on Linode, behind a Cloud Firewall |
| [shared/cloud-init.yaml](shared/cloud-init.yaml) | First-boot setup: Docker, PostgreSQL client, diagnostics tools |
| [docs](docs) | AWS account setup, a runbook for one benchmark run, workload shapes, provider comparison, and cost guardrails |

## Using a stack

Install [OpenTofu](https://opentofu.org/) (`winget install OpenTofu.Tofu` on Windows). Terraform 1.6 or later also works. Then, for the provider you chose:

```bash
cd stacks/aws-host            # or stacks/linode-host
cp terraform.tfvars.example terraform.tfvars   # edit it
tofu init
tofu plan
tofu apply
# ... do the work ...
tofu destroy
```

Credentials come from the provider's standard environment variables (`AWS_PROFILE` or `AWS_ACCESS_KEY_ID`, and `LINODE_TOKEN`). They are never written into this repository.

For the whole routine of one benchmark run on AWS, from signing in to tearing down and recording the cost, follow [docs/run-a-benchmark.md](docs/run-a-benchmark.md).

## Whose account

The Foundation owns the cloud account that these stacks are run against, with a spending ceiling set by the Foundation. [docs/aws-account-setup.md](docs/aws-account-setup.md) walks through setting it up. Contributors who want their own environment can use this repository to build one in their own account, at their own cost.

## Licensing

Code is licensed under the [Apache License 2.0](LICENSE). The license grants no rights to the Foundation's trademarks. Wax, HiveAR, and The OpenAR Collective are trademarks of The Open Accounts Receivable Collective Foundation.

## Contributing

Contributions are accepted under the Developer Certificate of Origin. See [CONTRIBUTING.md](CONTRIBUTING.md).
