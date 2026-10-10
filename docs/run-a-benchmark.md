# Run a benchmark on an AWS sandbox host

The routine for one run, from signing in to tearing the host down and recording what it cost. It is written for a person at a terminal, or a person working with an assistant, who has already been through [aws-account-setup.md](aws-account-setup.md). It covers the host. What to run on the host belongs to the experiment's own instructions.

By default, treat a run as one trip: create the host, use it, copy the results off, destroy it. For a test campaign of several runs, the Foundation may keep one host for the campaign instead, as [Keeping a host for a campaign](#keeping-a-host-for-a-campaign) describes. Either way, nothing on the host is the source of record, and the host deletes itself when its timer ends.

## Before you start

- **You can sign in to the sandbox account.** Part 5 of the account setup guide sets up the `openar-sandbox` profile. If you also have AWS profiles for other projects, never run these stacks with one of them.
- **The vCPU quota covers the host.** The quota is "Running On-Demand Standard (A, C, D, H, I, M, R, T, Z) instances" in `us-east-1` (quota code `L-1216C47A`), counted in vCPUs. The default host has 16 vCPUs, so the quota must be at least 16. A launch over the quota fails with a vCPU limit error. Check the value in the Service Quotas console, and request an increase early, because increases can take days. The quota is also the strongest spending cap, so ask only for what the next run needs.
- **You know what the run costs at most.** Multiply the hours in `max_lifetime_hours` by the hourly price of the instance type, and check the price in the AWS pricing calculator. The default host is roughly $1 an hour, so a 36 hour host costs on the order of $36, plus a little for the root disk.
- **You have your public address as a /32** and an SSH key pair on your machine. Only the public key goes anywhere near the stack.
- **The code and data are ready to copy up**, as a git bundle or an archive. The sandbox holds synthetic data only. Real account data never goes here.

## 1. Sign in and confirm the account

```powershell
aws sso login --profile openar-sandbox
$env:AWS_PROFILE = "openar-sandbox"
aws sts get-caller-identity
```

Check that the account ID printed is the sandbox account and not the management account or any other. Do this in the same terminal you will run OpenTofu in, because the profile is a property of the terminal. If the account is wrong, stop and fix it before anything else.

## 2. Configure the run

```bash
cd stacks/aws-host
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`, which git ignores:

- `owner` is you, and shows up in the cost tags.
- `name` identifies the run, such as `benchmark-run-3`, so a leftover is recognizable.
- `ssh_public_key` is the contents of your public key file, such as `~/.ssh/id_ed25519.pub`. Never use a private key here.
- `allowed_ssh_cidr` is your public address as a /32. To find it: `(Invoke-RestMethod https://checkip.amazonaws.com).Trim()` in PowerShell, or `curl https://checkip.amazonaws.com` in bash.
- `instance_type` is the default `m6id.4xlarge` unless the run needs something else. Use a fixed-performance type, never a burstable `t` type.
- `max_lifetime_hours` must be longer than the longest planned pass plus setup and copy-off time. **Decide it now.** Changing it after the host exists replaces the host (see [Watch the clock](#7-watch-the-clock)).

## 3. Plan, read it, then apply

```bash
tofu init
tofu plan
```

Read the plan before applying it. For a new run it should show exactly three resources to add (a key pair, a security group, and the instance), the instance type and region you intended, your /32 on the SSH rule, and nothing to change or destroy. If it shows anything else, stop and find out why.

```bash
tofu apply
```

Type `yes` when the plan is right. The meter starts when the instance launches.

## 4. Wait for the host to be ready

```bash
tofu output ssh
ssh ubuntu@<the public address from the output>
```

First boot takes a few minutes: package updates, formatting the local disk, and installing Docker. The host is ready when `/var/lib/cloud/instance/sandbox-ready` exists. `cloud-init status --wait` blocks until first boot finishes. If you signed in before it finished, sign out and in again so your shell picks up the `docker` group.

Check the host before you rely on it:

```bash
cat /etc/openar-sandbox/host-facts.json     # provider, instance type, instance ID, region, zone
docker info --format '{{.DockerRootDir}}'    # /mnt/nvme/docker on types with local NVMe
df -h /mnt/nvme                              # the local disk, on the "d" instance types
shutdown --show                              # the lifetime timer is scheduled
```

Record the instance type and zone with the results, because every AWS host is its own baseline. If the experiment is commit-bound, measure the disk's flush latency once with PostgreSQL's `pg_test_fsync`, run against the disk the database will use, and keep the result. That tool ships with the PostgreSQL server tools, which first boot does not install.

## 5. Put the code on the host

Copy code up with `scp` and unpack it there. For a git repository without a remote, a bundle keeps every commit:

```bash
git bundle create ../project.bundle main
scp ../project.bundle ubuntu@<address>:~
ssh ubuntu@<address> "git clone project.bundle project"
```

The host can reach the internet to pull images and packages. Do not copy credentials, tokens, or real data onto it.

## 6. Run the work so it survives a dropped connection

A long run must not depend on one SSH session. First boot does not install a terminal multiplexer, so add one:

```bash
sudo apt-get install -y tmux
tmux new -s run
```

Start the work inside tmux, keep its output in a log file, and detach with `Ctrl-b d`. Reattach later with `tmux attach -t run`. Do not run two measured jobs at once on the same host unless the experiment says so.

## 7. Watch the clock

`shutdown --show` prints when the host will shut itself down. The shutdown terminates the instance, so the timer ends the host whether or not the run has finished, and everything on the host goes with it. Check the clock at the start of every working session, and decide with at least two hours to spare whether to copy results off or to extend.

**Do not extend a host by raising `max_lifetime_hours` and running `tofu apply` again.** The value is part of the first-boot script, and a changed script replaces the instance: a new host, empty disks, and the run gone. To give a running host more time, sign in and replace its timer in one step, then confirm:

```bash
sudo shutdown -c; sudo shutdown -h +720 "extended by <your name>"
shutdown --show
```

The number is minutes from now. Never cancel the timer without scheduling a new one in the same command line, and note the extension in the run log, because the host now costs more than the plan said.

For the same reason, never run `tofu apply` against a host that is already running. The stack picks the newest Ubuntu image each time it plans, and a newer image also replaces the instance. A running host is read-only as far as OpenTofu is concerned. If your address changes and SSH stops working, run `tofu plan` and apply only if it shows a change to the security group alone and no replacement of the instance. If the plan also replaces the instance, do not apply. Change the security group's SSH rule in the AWS console instead, and expect OpenTofu's record to differ from reality until you destroy the host.

## 8. Copy results off before anything else

```bash
scp -r ubuntu@<address>:~/project/results ./results-run-3
```

Do this as soon as results exist and again at the end, not at the last minute. Check that the sizes match, and move the results into the experiment's own repository or archive. The local disk is lost when the host stops, and the root disk is deleted when it terminates.

## 9. Destroy and verify

```bash
tofu destroy
```

Type `yes`. Then check that nothing is left. The sandbox account holds only sandbox resources, so anything these commands list that is not a deliberate leftover needs investigating:

```bash
aws ec2 describe-instances --region us-east-1 --query "Reservations[].Instances[?State.Name!='terminated'].[InstanceId,InstanceType,State.Name,LaunchTime]" --output table
aws ec2 describe-volumes --region us-east-1 --query "Volumes[].[VolumeId,Size,State]" --output table
aws ec2 describe-addresses --region us-east-1 --query "Addresses[].[PublicIp,AllocationId]" --output table
aws ec2 describe-snapshots --region us-east-1 --owner-ids self --query "Snapshots[].[SnapshotId,VolumeSize]" --output table
```

All four should be empty. Key pairs and security groups cost nothing, but `tofu destroy` should have removed the ones this run made.

If you forget this step, the timer ends the host for you, but the step above still applies. Look anyway.

## 10. Record what it cost

Billing data runs hours behind. The next day, open Cost Explorer in the management account, filter by the `Project` tag set to `openar-cloud-sandbox`, and record the run's cost next to its results, with the instance type and the hours. The first few of these replace the estimates in this repository with real numbers. The `Project` and `Owner` tags only appear in Cost Explorer after they are activated as cost allocation tags, which [aws-account-setup.md](aws-account-setup.md) covers.

## Keeping a host for a campaign

When one host serves several runs over days, as in a production-scale test campaign, rebuilding it for every run would repeat work and add nothing. The Foundation's decision is to keep such a host as long as the campaign needs it. The rest of this page still applies. What changes is that the host stays up between runs, so the cost and the timer need more attention:

- **Set the timer to the campaign, on purpose.** Choose `max_lifetime_hours` for the whole campaign before the first apply, such as 168 for a week, and write the end date in the run log. A forgotten campaign host still ends itself, but only at that limit.
- **Know the daily cost.** An idle host costs the same as a busy one. At roughly $1 an hour for 16 vCPUs and roughly twice that for 32 vCPUs (check current pricing), that is about $24 and $48 a day. The $1,000 monthly ceiling is about three weeks of a 32 vCPU host running all day. The budget action blocks new launches but does not stop a running host, so the timer is what ends it.
- **Look at it every day it exists.** Run `shutdown --show` to see the timer, and open Cost Explorer for the `Project` tag to see the spend so far.
- **Never stop the host to save money.** The local disk is lost whenever the host stops, and a shutdown from inside terminates the instance. A host is either running or gone.
- **Reset between runs as the experiment says.** The data on the host persists across runs, so reseed or clean it according to the experiment's instructions, and record which state each run started from.
- **Copy results off after every run,** not only at the end. A host can disappear for reasons you did not choose.
- **Extend from the inside, as in [Watch the clock](#7-watch-the-clock),** if the campaign overruns, and record the new end date.
- **End it when the campaign ends.** Run `tofu destroy`, check that nothing is left (step 9), and record the campaign's total cost (step 10).

## When something goes wrong

- **The launch fails with a vCPU limit error.** The quota is lower than the instance needs. Request an increase in Service Quotas, and do not retry in a loop.
- **`tofu plan` wants to replace a running host.** Do not apply it. See [Watch the clock](#7-watch-the-clock).
- **SSH times out.** Your public address probably changed. See the last paragraph of [Watch the clock](#7-watch-the-clock).
- **The wrong account or profile.** Stop. Run `aws sts get-caller-identity` and fix the profile before any further command.
- **The disk fills.** The root disk is 100 GB by default and the local disk is about 950 GB on the default type. `df -h` shows both. Clean up on the host, or destroy it and start a new run with a larger root disk.
- **You are not sure the host is gone.** Run the checks in step 9. If an instance is still listed, terminate it from the console and tell the account owner.

## What this page does not cover

The experiment itself, hosts with GPUs, runs across several hosts, and the Linode stack. See [workload-shapes.md](workload-shapes.md) for the host shapes and [cost-guardrails.md](cost-guardrails.md) for the layers that limit spending.
