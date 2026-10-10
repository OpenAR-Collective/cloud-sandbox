# Cost guardrails

The risk is not the price of a run. It is a host that is still running a month later. Each layer below catches what the one before misses.

## 1. Destroy as part of the work

Every run ends with `tofu destroy`. Tag and name hosts after the experiment, such as `benchmark-run-2`, so a leftover is recognizable.

## 2. A timer inside the host (AWS)

`max_lifetime_hours` defaults to 12. First boot runs `shutdown -h +N`, and the instance is configured with `instance_initiated_shutdown_behavior = "terminate"`, so a forgotten host deletes itself and its root disk. Set the value you need before the first apply. Changing it later replaces the host, because the value is part of the first-boot script, so a running host is extended from the inside instead, as [run-a-benchmark.md](run-a-benchmark.md#7-watch-the-clock) describes. Review any change to that value. A host kept for a test campaign gets a timer set to the campaign's length, an end date in the run log, and a daily look, as [run-a-benchmark.md](run-a-benchmark.md#keeping-a-host-for-a-campaign) describes.

**Linode has no equivalent.** A powered-off Linode keeps billing, so a shutdown timer would only hide the problem. Until a reaper exists, Linode hosts depend on layers 1, 3, and 4.

## 3. Alerts

Set these once per account, before the first apply. [aws-account-setup.md](aws-account-setup.md) has the steps.

- **AWS:** a $1,000 monthly budget, with alerts at 25, 50, 80, and 100 percent and a budget action that denies new hosts at 100 percent. Add Cost Anomaly Detection with a low threshold. Budgets alert and do not delete anything.
- **Linode (if ever used):** a billing alert threshold in the account settings.

## 4. A weekly look for leftovers

Anyone with account access checks the console for hosts carrying the `openar-cloud-sandbox` tag. A small script that lists tagged resources and exits nonzero if any are older than the maximum lifetime would automate this; it is not written yet.

## 5. Possible later work

- A scheduled reaper (an AWS Lambda, or a scheduled job on a free tier for Linode) that deletes tagged hosts older than a limit.
- Per-contributor accounts or sub-accounts with service quotas, so one mistake cannot launch a 96 vCPU host.
- Spot instances for runs that tolerate interruption, once the harness can resume.

## What the stacks already do

- Restrict SSH to one address and reject `0.0.0.0/0` in the variable validation.
- Require IMDSv2 on AWS and encrypt the root volume.
- Tag every AWS resource with project, owner, and maximum lifetime.
- Keep state files, variable files, and keys out of git.
