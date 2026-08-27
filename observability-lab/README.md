# GitHub Workflow + Observability Lab

Builds on the Aurora GroupID lab's infra. This time the focus isn't the
database, it's the *process*: branching, opening a pull request, letting
CI validate it, reviewing it yourself like a teammate would, then merging
and applying. The infra change being reviewed is CloudWatch alarms and
SNS notifications, closing the observability gap flagged back in the AWS
RDS lab.

## What's already in this repo (goes to `main` as-is)

- The working Aurora cluster config from the previous lab (with the two
  fixes already applied: engine `16.9`, `publicly_accessible = true`)
- `.github/workflows/terraform-plan.yml`, a CI check that runs
  `terraform fmt`, `terraform validate`, and `terraform plan` on every PR
  touching a `.tf` file
- `.gitignore` so state and secrets never get committed

## What you'll add yourself, on a branch, via a PR

- `cloudwatch.tf` (currently named `cloudwatch.tf.feature-branch` in this
  folder, you'll rename it when you add it)
- An `alert_email` variable in `variables.tf`

## Step 1: Create the GitHub repo

1. Go to github.com, click **New repository**
2. Name it something like `observability-lab`
3. Keep it **Private** (this repo will reference real AWS resource names)
4. Don't initialize with a README, you already have one
5. Copy the repo URL it gives you

## Step 2: Push the initial `main` branch

```powershell
cd gh-observability-lab
git init
git add .
git rm --cached cloudwatch.tf.feature-branch   # don't commit this yet, on purpose
git commit -m "Initial Aurora cluster infra"
git branch -M main
git remote add origin https://github.com/YOUR-USERNAME/observability-lab.git
git push -u origin main
```

Double-check `cloudwatch.tf.feature-branch` did NOT get pushed, look at
the repo on GitHub, `main` should only show the original Aurora files.

## Step 3: Add repo secrets (for CI to run terraform plan)

GitHub repo → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**. Add these five:

| Secret name | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | your `terraform-cli` access key |
| `AWS_SECRET_ACCESS_KEY` | your `terraform-cli` secret key |
| `TF_VAR_MASTER_PASSWORD` | a password for this lab's cluster |
| `TF_VAR_MY_IP_CIDR` | your IP in `/32` form |
| `TF_VAR_ALERT_EMAIL` | an email you can check |

These stay encrypted in GitHub and are never visible in logs.

## Step 4: Deploy the base infra locally first

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars   # fill in my_ip_cidr

$env:TF_VAR_master_password = "SomeStrongPass2026!"
terraform init
terraform apply
```

## Step 5: Create a feature branch for the observability change

```powershell
git checkout -b add-cloudwatch-alarms
```

## Step 6: Add the actual change

```powershell
Rename-Item cloudwatch.tf.feature-branch cloudwatch.tf
```

Then open `variables.tf` and add this new variable block at the end:

```hcl
variable "alert_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
}
```

## Step 7: Commit and push the branch

```powershell
git add cloudwatch.tf variables.tf
git commit -m "Add CloudWatch alarms and SNS notifications for connection and ACU thresholds"
git push -u origin add-cloudwatch-alarms
```

## Step 8: Open the pull request

On GitHub, you'll see a banner offering to open a PR from your just-pushed
branch, click it. Write a real PR description, practice this like you
would for an actual team review:

- **What**: adds two CloudWatch alarms (connection count, ACU ceiling) and
  an SNS topic with email notification
- **Why**: closes the observability gap from the earlier AWS lab, gives
  early warning before the cluster hits real limits
- **How to verify**: `terraform plan` output attached below (CI will add
  this automatically once configured)

## Step 9: Watch CI run

Go to the **Actions** tab, or the checks section at the bottom of the PR.
You should see `terraform fmt`, `validate`, and `plan` run automatically.
Click into the plan step, read the output, this is exactly what a
reviewer would look at before approving.

If CI fails, that's not a bad outcome, it's the lab working. Read the
error, fix it on your branch, `git add`, `git commit`, `git push` again,
CI reruns automatically on the same PR.

## Step 10: Review your own PR like a teammate would

Before merging, actually read the diff on GitHub's PR "Files changed" tab
and ask yourself:

- Do the alarm thresholds make sense for this workload?
- Is the SNS subscription going to a real, checkable inbox?
- Does anything in this diff touch state, secrets, or credentials it
  shouldn't?
- Is the commit message and PR description clear enough that someone
  else could understand the change without asking you?

## Step 11: Merge

Click **Merge pull request** on GitHub, then locally:

```powershell
git checkout main
git pull
```

## Step 12: Apply the change

```powershell
terraform apply
```

Terraform will show the new SNS topic and two alarms as additions. Type
`yes`.

## Step 13: Confirm the SNS subscription

Check the inbox for `alert_email`, AWS sends a confirmation email for new
SNS subscriptions, you must click the confirm link or the alarm
notifications will silently never arrive. This is a common real-world
gotcha, easy to miss.

## Step 14: Tear down

```powershell
terraform destroy
```

## What this lab actually taught, beyond the Terraform

- **Branch, PR, review, merge** is now something you've done for real,
  not just read about, directly answers the open question about seeing
  a GitHub pipeline run in person.
- **CI catching a bad plan before merge** is the actual value of the
  pattern, not paperwork, a broken `terraform plan` in the PR check stops
  a bad change before it ever reaches `main`.
- **SNS email confirmation is a real trap**, alarms can be perfectly
  configured and still notify nobody if that step's skipped, worth
  remembering for real infra later.
