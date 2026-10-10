# Provider comparison: AWS, Linode, Azure

Status: **draft.** Prices are approximate and must be checked against each provider's calculator before anyone relies on them.

## Decisions so far

- **Tooling:** OpenTofu.
- **Account ownership:** the Foundation owns the cloud account. Contributors who want their own environment can use this repository's stacks in their own accounts, at their own cost. The root login is held by one named owner and stored in a password manager, and a small set of delegates chosen by the Foundation can create hosts. See [aws-account-setup.md](aws-account-setup.md).
- **Spend:** a monthly ceiling set by the Foundation until credits arrive, with the aim of spending much less.
- **Provider:** AWS only for now. The Linode stack stays in the repository as a starting point, and its cleanup job will not be written unless Linode is used.
- **GPUs:** the families are undecided. No GPU quota is requested until an experiment exists.
- **Scale:** some runs will need more than 32 vCPUs to simulate large production environments, and some AI experiments will need GPUs. This favors AWS as the primary provider. See below.
- **Credits:** not available yet. See [Nonprofit credits](#nonprofit-credits).

## What the sandbox has to do

The first workload is performance benchmarking of database-backed software. It needs:

- One Linux host with Docker, running PostgreSQL and the application under test side by side.
- **Predictable CPU.** A host whose CPU speed varies with neighbors or credits produces numbers nobody can compare. That rules out burstable instance types (AWS `t` family, Linode Shared CPU) for benchmark runs.
- Enough cores to test beyond what a laptop can: some runs will want 16 to 64 vCPUs for a few hours.
- **GPUs** for some AI experiments, in short runs.
- Fast local disk. When every transaction waits for a log flush, fsync latency matters as much as CPU.
- Runs of hours, occasionally overnight. Nothing needs to stay up.

See [workload-shapes.md](workload-shapes.md) for the host shapes.

## Comparison

| | AWS | Linode (Akamai Cloud) | Azure |
| --- | --- | --- | --- |
| Hourly billing, no minimum | Yes (per second for Linux) | Yes, capped at the monthly price | Yes (per second) |
| Comparable 8 vCPU benchmark host | `m7i.2xlarge`, 8 vCPU, 32 GB, roughly $0.40/hr on demand | `g6-dedicated-8`, 8 vCPU, 16 GB, roughly $0.22/hr (extrapolated from the published 4 GB and 8 GB rates; verify) | `D8s_v5` class, roughly similar to AWS |
| Large hosts (32 to 64 vCPU) | Wide choice, including storage-optimized types with local NVMe | Dedicated plans scale up, with fewer shapes | Wide choice |
| Billing stops when | Instance is terminated (stopped instances still pay for disks) | Instance is **deleted**. A powered-off Linode still bills | Deallocated and disks deleted |
| Self-terminating backstop | Yes: shutdown behavior `terminate` plus a shutdown timer | No equivalent. Needs an external reaper or a manual destroy | Partial, via auto-shutdown schedules |
| Data transfer out | Metered, and the free allowance is small | Large pooled allowance included | Metered |
| Spend alerts and hard caps | Budgets and alarms (alerts, not caps) | Alerts only | Budgets and alarms |
| Nonprofit credits | Up to $5,000 a year through TechSoup. Not available before the IRS determination | Not known | $2,000 a year in Azure credit. Needs recognized 501(c)(3)-equivalent status |
| GPUs | Wide range (G and P families), but new accounts start with zero or low GPU quota | Some GPU plans, in limited regions. Verify current plans | Wide range, with similar quota limits |
| Already in use by the Collective | No | **Yes**, for the website | No |
| IaC provider | `hashicorp/aws`, the most mature | `linode/linode`, solid and smaller | `hashicorp/azurerm`, mature |

## Reading the table

- **Cost is close for small hosts and unlikely to be the deciding factor.** A 12 hour run on an 8 vCPU host is a few dollars on either provider. The cost that matters is the host somebody forgets, and the table's real difference is in the guardrails: AWS can terminate a host from inside, and Linode cannot.
- **Linode is cheaper per core and simpler,** and the Collective already has an account. Its weaknesses for this job are the smaller menu of large shapes and the missing self-terminating backstop.
- **AWS has the reach, and the Foundation's stated needs call for it.** Runs above 32 vCPUs, GPUs, local NVMe, and managed PostgreSQL such as RDS or Aurora to compare against the self-managed one are all routine on AWS. It is also the provider most contributors already know. Linode stays useful for small, cheap, long-lived-for-an-afternoon hosts.
- **Quotas are the hidden delay.** A new AWS account usually starts with low limits on vCPUs and zero on GPU instance families, and increases are requested through Service Quotas and can take days. Request the quotas for the largest host and the GPU family the Foundation expects to use as soon as the account exists, not on the day of a run.
- **Azure adds nothing the other two do not cover** unless nonprofit credits make it free. It is not scaffolded here. Check the credits before dropping it entirely.

## Tooling: OpenTofu or Terraform

Both read the same files. Terraform 1.6 and later is under the Business Source License, which the Open Source Initiative does not approve. [OpenTofu](https://opentofu.org/) is the MPL 2.0 fork under the Linux Foundation. For a Foundation whose mission is free and open-source software, and which will publish this repository, **OpenTofu is the recommended default.** The stacks here pin `required_version = ">= 1.6"` and avoid features that differ between the two, so either works. The Foundation's Open Source Policy should be checked for anything that bears on this.

## Nonprofit credits

Researched 2026-10-10 from the programs' published rules. As far as the published rules show, neither program issues credits before the IRS recognizes an organization's 501(c)(3) status.

- **AWS Nonprofit Credit Program:** up to $5,000 in promotional credit per fiscal year (July 1 to June 30), valid for at least a year. US organizations apply through TechSoup. TechSoup says an organization waiting on its 501(c)(3) determination is held as pending and receives no offers until the IRS recognizes it. A Delaware nonprofit corporation is not enough on its own, because the test is federal tax-exempt recognition and not state incorporation. TechSoup also excludes fiscally sponsored projects, so a fiscal-sponsor route would not help here either.
- **Microsoft for Nonprofits Azure grant:** $2,000 a year in Azure credit, which cannot roll over, and a credit card is required in case usage exceeds it. Eligibility requires recognized legal status equal to 501(c)(3), checked by a third-party validation partner. Microsoft's pages do not describe any provision for pending applications.

Neither page says in so many words that pending organizations are refused, except TechSoup's, so the next step is to ask: **TechSoup** about AWS credit, and **Microsoft's Nonprofit support form** about Azure. Both answers are cheap to get and would be worth recording here. Until recognition arrives, budget as if there are no credits. When it does, register with TechSoup and Microsoft the same week.

## Suggested path

1. Create the Foundation's AWS account with a monthly budget alert, and request the vCPU and GPU quota increases early.
2. Validate the AWS stack with one throwaway `plan`, `apply`, and `destroy` cycle and record the real cost. Add GPU and large-host variants once the quotas are granted.
3. Leave the Linode stack parked. If it is ever used, write its cleanup job first (see [cost-guardrails.md](cost-guardrails.md)).
4. Revisit after the first real benchmark run, with an actual bill in hand.

## Open questions

- Which hosts and sizes do the planned runs need beyond the single 16 vCPU host? See [workload-shapes.md](workload-shapes.md).
- Who is the backup holder of the root credentials, so the account survives one person being unavailable?
- Which GPU families, if any, will the AI experiments need? Undecided by design.
