# AWS account setup

A one-time setup for the Foundation's AWS account. Allow about two hours, plus a day of waiting for billing data to appear. The console changes often, so treat menu names as approximate and follow the intent of each step.

Decisions this guide assumes:

- The Foundation owns the account. One named owner holds the root login, stored in a password manager.
- The owner and any delegates the owner selects from the board, directors, employees, or contractors can create hosts. Initially only the owner.
- Spending is capped by policy at a monthly ceiling (this guide uses **$1,000** as the example) until nonprofit credits arrive, and the aim is to spend far less.
- Only AWS is targeted for now. GPU families are undecided and are not requested.

## Why two accounts

Create the account as the root of an AWS Organization, and put the hosts in a second, member account.

| Account | What happens there |
| --- | --- |
| **Management** (the one you sign up for) | Billing, credits, Organizations, Identity Center. No hosts, ever. |
| **Sandbox** (a member account) | Every EC2 host, volume, and test resource. |

The reason is blast radius. A delegate or a leaked credential in the sandbox account cannot touch billing, the root login, or the Organization, and policies on the Organization can limit what the sandbox account is allowed to do at all. Organizations is free.

## Part 1: Before you start

Have these ready:

- A **role-based email address** the Foundation controls. The plan is a Google Workspace group, `tech-admin@example.org`, used directly as the root email of the management account, plus a second small group, `aws-sandbox@example.org`, for the sandbox account. Do not use a personal address, because the root user's email is how the account is recovered. See [Setting up the group](#setting-up-the-group) below.
- The Foundation's legal name, address, and a working phone number.
- A **payment card** for the Foundation. A card with its own limit is a useful second brake.
- Two **hardware security keys or passkeys** for root MFA, so losing one device does not lock the Foundation out.
- A password manager vault for the Foundation's cloud credentials, with the vault's membership known.

### Setting up the group

A Google group can be an AWS root email address. AWS only needs to send mail to it, and the root user signs in with its own password and MFA, not with a Google login. Check these before signing up:

1. **Let outside mail in.** Set the group's **Who can post** to **Anyone on the web** (or moderated, if you prefer to filter spam). AWS verification codes and password resets come from outside the Foundation's domain, and a group that rejects external mail will silently drop them. If the option is missing, a Workspace admin has to allow groups to receive external email in the Admin console's sharing settings.
2. **Keep it private.** Set who can view conversations and who can view members to **members only**. The group's archive will hold verification codes and password reset links.
3. **Keep the membership tiny.** Every member receives every message, including a password reset link. The owner and a sealed backup only. Delegates who create hosts do not belong here, because they sign in through Identity Center. With hardware-key MFA on the root user a reset email alone is not enough to take over the account, but treat membership as sensitive anyway.
4. **Test it** by sending a message to `tech-admin@example.org` from an outside address, such as a personal mailbox, before you start the sign-up. If it does not arrive, fix that first, because AWS will send a verification code to it within minutes.
5. **Create the second group** before Part 4: `aws-sandbox@example.org`, no Security label, the same access settings, and the same few members. Every AWS account needs its own unique address, and plus-addressing (`tech-admin+sandbox@`) may not work with groups, so do not rely on it. This Admin console did not offer group aliases, which is why there are two groups and not one group with aliases.
6. If the group is ever used for anything besides AWS, its members also receive AWS password resets. Keep the membership to the few people who should hold that power, or move the AWS root email to a dedicated group.

## Part 2: Create the account and secure the root user

1. Go to aws.amazon.com and choose **Create an AWS account**. On the sign-up page, **do not use the main button or the Google, GitHub, Apple, or Amazon buttons. Choose "Sign up (advanced)"** instead. The default "new" sign-up creates no root user, ties the account to a personal sign-in, and has AWS manage the organization policies, while this plan needs a root user with hardware MFA and its own organization policies. AWS's sign-in documentation says root and IAM users are supported only on the advanced path. Enter the Foundation's details, and if it asks for an account type, choose Business and not Personal. The sign-up flow has changed before, so follow the intent if the wording differs.
   - **Free or paid plan:** if you are offered a choice, choose the **Paid** plan. AWS says the free plan ends after six months or when its credits run out, and it upgrades itself to paid when you join an Organization, which this plan does. You are charged only for usage, and new accounts get a small credit either way.
2. Choose the **Basic (free)** support plan.
3. Sign in as root. Save the root password and the account ID in the password manager immediately.
4. Under **Security credentials**, register MFA on the root user with a hardware key or passkey. Register a second device as a backup, and store it somewhere physically separate.
5. **Do not create access keys for the root user.** Nothing in this project needs them.
6. Under **Account**, set the **alternate contacts** for billing, operations, and security. These should reach at least two people, so the account has continuity if one person is away.
7. Sign out. From now on the root login is used only for the few tasks that require it, which are changing the support plan, closing the account, and recovering from locked-out situations.

Key-person risk: if one person is the only one who can open the vault, losing them loses the account. Decide who is the sealed backup, such as another officer who can open the 1Password vault in an emergency, and write the answer in the Foundation's records.

## Part 3: Billing safety, before anything is built

Do this before launching any host. All of it is in the Billing and Cost Management console.

1. **Activate IAM access to billing**, so that non-root users can be given billing views later without sharing root.
2. **Create a monthly cost budget of $1,000.** Add email alerts at 25, 50, 80, and 100 percent of actual spend, and one at 100 percent of forecasted spend. Send them to the root-email group and to the owner.
3. **Add a budget action** at 100 percent of actual spend that applies a policy denying `ec2:RunInstances` to the operators group. AWS budgets alert and do not stop spending on their own. The action stops new hosts from being created, though it does not delete existing ones. Check the current action options when you set it up. AWS has no true hard stop on spending, and billing data runs hours behind, so a budget can overshoot. See [What actually caps spending](#what-actually-caps-spending).
4. **Turn on Cost Anomaly Detection** with a monitor for all services and an alert at a low threshold, such as $50. It is free and catches the forgotten host faster than the monthly budget.
5. **Enable Cost Explorer.** It takes up to a day to fill in.
6. **Activate the cost allocation tags** `Project` and `Owner` later, in Part 6. A tag can be activated only after a resource has been created with it, and the OpenTofu stack applies both tags to every resource. Cost reports can split by tag only after activation, which also takes up to a day.
7. Set billing preferences to receive PDF invoices by email, and turn on free tier usage alerts.
8. Leave the **tax settings** for later. When the IRS determination arrives, add the exemption documentation.

Where the numbers land, using approximate on-demand rates that must be checked against the pricing calculator: $1,000 is roughly 1,000 hours of the default 16 vCPU host with local NVMe (about $1 an hour), which is around 30 full 20-hour bake-off passes, or roughly 300 hours of a 64 vCPU host. Disks and data transfer are small by comparison unless something is left behind. A run that is destroyed afterward costs little, so the budget is mostly insurance.

## What actually caps spending

AWS has no setting that refuses all spending after a threshold. The cap comes from several layers, each with a gap on its own:

1. **The vCPU service quota** in the sandbox account is the strongest cap, and it works in real time. With a 32 vCPU quota nothing can run more than 32 vCPUs at once, which at about $1 an hour per 16 vCPUs is about $2 an hour. Ask only for what the next run needs.
2. **The lifetime timer** on every host ends a forgotten host within the configured limit (for example 36 hours for a long benchmark pass). Review any change to that value.
3. **The region policy** on the sandbox account stops launches anywhere nobody is watching.
4. **The budget action** blocks new launches at 100 percent of the budget. Billing data is hours behind, and the action does not delete anything, and disks and data transfer keep billing.
5. **A card with its own limit**, if one is available. A failed charge takes days to suspend the account, so this is a last resort.

## Part 4: Organization, sandbox account, and sign-in

1. In the management account, enable **AWS Organizations**.
2. Create a member account named `openar-sandbox`, using the `aws-sandbox@` group address.
3. Enable **IAM Identity Center** in the management account, in one region (use `us-east-1`).
4. **Use Google Workspace as the identity source.** People sign in to AWS with their own Google Workspace accounts, never with the `tech-admin@` group. A group address is a mailbox and not a login, so it plays no part in single sign-on. The root user stays outside SSO entirely, with its own password and MFA.
   - In Identity Center, choose **Settings, Actions, Change identity source, External identity provider**, and follow AWS's guide for Google Workspace. It needs a Google super administrator for a few minutes. In the Google Admin console, add the app by searching for **Amazon Web Services** and choosing **Amazon Web Services (SAML)**. Set Name ID format to **EMAIL** and Name ID to **Primary email**, and on the attribute mapping page map `RoleSessionName` to Primary email and `Role` to any attribute.
   - SCIM syncs **users only**. It does not sync groups, and with an external identity provider the console cannot create groups either. For one operator, **skip groups** and assign the permission set directly to the operator's user. When delegates join, create a group with the AWS CLI (`aws identitystore create-group`) or use the community tool `ssosync`.
   - Copy the SCIM endpoint and access token straight into Google's auto-provisioning page and into the password manager. AWS shows them once. The token expires after a year, and so does Google's SAML certificate on its own schedule, so put both dates on the Foundation's calendar.
   - Every Google user to be synced needs a first name, last name, username, and display name, each with a single value.
   - **MFA moves to Google.** When the identity source is external, Identity Center's own MFA settings do not apply. Require **2-Step Verification** for the Foundation's Google accounts, with security keys or passkeys, and enforce it in the Admin console. Then offboarding also works from one place: suspending the Google account stops new AWS sign-ins.
5. Create a **permission set** and assign it to the operator's user (or to a group later) on the `openar-sandbox` account. Start with the AWS-managed `PowerUserAccess` policy, which allows creating resources and not managing identity, and tighten it later. The operator should not also work as an administrator day to day.
6. Add an **organization policy (SCP)** on the sandbox account that denies every region except the ones in use, to start with only `us-east-1`. The policy is in [../policies/sandbox-region-scp.json](../policies/sandbox-region-scp.json). It exempts a short list of global services that do not work with a region restriction, based on AWS's published pattern, so test the sign-in after attaching it and extend the list if a global service breaks. Attach it to the sandbox account and not to the organization root. This stops a mistaken or stolen session from launching hosts somewhere nobody is watching.
7. In the sandbox account, request **service quota** increases only for what the next real run needs, such as the vCPU limit for On-Demand Standard instances. This quota is also the main spending cap (see [What actually caps spending](#what-actually-caps-spending)), so do not raise it further than needed. **Do not request GPU quota**: the GPU families are undecided, and the request can wait until an experiment exists.

### Locking down the sandbox account's root user

A member account created through Organizations starts with **no root credentials** (no password, access keys, or MFA), so it has no root login to protect. Centralized root access management makes that permanent: AWS blocks the forgot-password flow for member accounts that have no root credentials, so nobody can set a password through the account's mailbox.

1. In the management account, open **IAM, Root access management**, and enable **root credentials management** and **privileged root actions in member accounts**. Leave the delegated administrator blank unless you have a reason to name one.
2. **The management account's own root user cannot read the member account's status or take privileged actions.** AWS refuses with "RootSession may not be assumed by root accounts", and the credentials column shows Access denied. You need a regular IAM principal in the management account, such as an Identity Center user.
3. To check, as the root user create a temporary permission set (for example `ManagementAdminTemporary`, AdministratorAccess, 1 hour session) and assign it to your own Identity Center user on the management account. Sign out of root, then sign in through the access portal to the management account with that permission set.
4. In IAM, Root access management, the member account's **Root user credentials** column should read **Not present**. If it lists credentials instead, use **Take privileged action** to audit and delete them.
5. Remove the assignment (and the permission set, if you do not want a standing route) when you are done.

## Part 5: Set up your laptop

1. Install the AWS CLI (`winget install Amazon.AWSCLI`), then open a new terminal.
2. Run `aws configure sso`, give it the Identity Center start URL, choose the `openar-sandbox` account, and name the profile `openar-sandbox`.
3. Each work session, run `aws sso login --profile openar-sandbox`, then `$env:AWS_PROFILE = "openar-sandbox"` in PowerShell. The credentials are short-lived and expire on their own, and no long-lived access key ever exists.
4. Check it with `aws sts get-caller-identity`. It should show the sandbox account ID.

## Part 6: Prove it with a throwaway host

1. In `stacks/aws-host`, copy `terraform.tfvars.example` to `terraform.tfvars`. Use a small `instance_type` such as `m7i.large`, `max_lifetime_hours = 2`, and your own public address in `allowed_ssh_cidr`.
2. Run `tofu init`, `tofu plan`, and `tofu apply`. Wait for `sandbox-ready` to appear (`ls /var/lib/cloud/instance/`), then sign in and check that Docker runs.
3. Run `tofu destroy`. Confirm in the console that the instance is terminated and no volumes remain.
4. After the test host exists, activate the `Project` and `Owner` cost allocation tags in the management account's Billing console (they appear there once a resource has used them). The next day, open Cost Explorer filtered by the `Project` tag and record what the test actually cost. That number replaces the estimates in this repository.

## Part 7: Adding a delegate later

1. Give them a Foundation Google Workspace account with 2-Step Verification, enable the Amazon Web Services app for them in Google, wait for SCIM to sync them into Identity Center, and assign the permission set to their user (or to a group once you have created one). They sign in as themselves and never share Rob's login.
2. Move OpenTofu state from the laptop to a shared place first. Use an S3 bucket with versioning in the sandbox account, so two people cannot apply over each other or leave hosts the other cannot see.
3. Tell them the rules: destroy when done, never open SSH wider than their own address, and no real agency or account data in the sandbox.
4. Remove the user from the group when they leave the Foundation or the project.

## Part 8: When the IRS determination arrives

1. Register the Foundation with TechSoup and request the AWS credit (up to $5,000 per fiscal year as published).
2. Apply the promo code under **Billing, Credits** in the management account.
3. Add tax-exempt documentation to the tax settings.
4. Revisit the $1,000 ceiling in light of the credit.

## Monthly habit

Open Cost Explorer once a month, and look at the tag report. Anything running in the sandbox account that is not tied to a current experiment gets terminated.
