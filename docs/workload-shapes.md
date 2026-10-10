# Benchmark host shapes

What a performance-benchmark host in this sandbox needs, stated generally. Benchmarks of database-backed software are sensitive to the host, so the stacks follow these rules.

## One host, predictable performance

- **16 vCPUs and 64 GB of memory** as the starting shape. An AWS vCPU is one hyperthread, so 16 vCPUs is 8 physical cores. Choose the shape to match the workload and record it with the results.
- **32 vCPUs and 128 GB** for production-scale tests, such as `m6id.8xlarge` (one 1,900 GB local NVMe drive; check the current specification). That is 16 physical cores. It needs a 32 vCPU quota, and a host that size costs roughly twice the 16 vCPU host.
- **Non-burstable CPU.** No credit-based instance families, because a throttled credit balance silently changes results.
- **Docker Engine with the Compose v2 plugin**, not Docker Desktop, on a **cgroup v2** kernel. Ubuntu 24.04 satisfies both. Python 3.12 and git come with the image or the first-boot setup.
- **Treat each AWS host as its own baseline.** Record the instance type, the CPU model, and the kernel, and compare results only within one host and one run.

## Disk

Commit-bound workloads, where every transaction waits for a log flush, depend on flush latency as much as CPU.

- The stack's default instance type has **local NVMe storage** (`m6id.4xlarge`: 16 vCPUs, 64 GB, one 950 GB drive). First boot formats the drive, mounts it at `/mnt/nvme`, and moves Docker's data root onto it, so database volumes sit on the fast disk. The data is lost when the host stops or terminates, which suits disposable test data.
- `m7i.4xlarge` is the same CPU with a network disk (EBS only). Treat it as a different baseline, and measure rather than assume. Run `pg_test_fsync` once on each host type and record the result.
- The root volume defaults to 100 GB. Peak use for the current workloads is well below that.

## Time and cost

- A long benchmark pass can run for many hours, and a full plan can take more than a day. The stack's lifetime timer defaults to 12 hours, and the example variables file sets 36. **The timer ends the host whether or not a run has finished**, so set it longer than the longest pass, and copy results off the host before anything else.
- At roughly $1 an hour for the default shape (check current pricing), a long pass costs on the order of tens of dollars.
- Whether to keep a host between runs or rebuild it each time is a decision for the operator. For a test campaign, the Foundation keeps one host for as long as the campaign needs it and rebuilds only when it must, because a rebuild repeats work that already exists. An idle 16 vCPU host costs about $24 a day and a 32 vCPU host about twice that, so a kept host needs an end date, a daily look, and a timer set to the campaign (see [run-a-benchmark.md](run-a-benchmark.md#keeping-a-host-for-a-campaign)). The local disk is lost whenever the host stops, so stopping is not a way to save money.

## Getting code on and results off

Copy code and data up with `scp` and copy results back down before running `tofu destroy`. Nothing in the sandbox holds source of record.

## Host facts

On AWS, first boot writes `/etc/openar-sandbox/host-facts.json` with the provider, instance type, instance ID, region, and availability zone, so a test harness can read the host's identity without calling the instance metadata service. The stack requires token-based (IMDSv2) metadata requests with a hop limit of 1, which containers cannot make. On providers without that service the file is simply not written.

## Scale beyond one host

A single host cannot answer questions about production-scale throughput, and no multi-host design exists yet. Designing one needs inputs that are unknown today: the target workload's size and window, which workloads must sustain the rate, the database topology, the number of application hosts, and network latency.
