# EKS + Atlantis — DevOps hometask

Terraform and Helm-deployed EKS cluster running [Atlantis](https://www.runatlantis.io/), wired to this GitHub repository so that infrastructure changes go through pull requests: open a PR, Atlantis posts a `terraform plan` as a comment, commenting `atlantis apply` applies it.

## Architecture

- **1 VPC** (`10.0.0.0/16`) with **2 public subnets** across 2 Availability Zones, an Internet Gateway, and a route table sending `0.0.0.0/0` to it.
- **1 EKS cluster** (`luminor-eks`, region `eu-north-1`) with a managed node group: `t3.medium`, **min 1 / max 2** workers (Auto Scaling Group).
- **Two IAM roles** mapped to Kubernetes access via EKS access entries:
  - `eks-admin` → `AmazonEKSClusterAdminPolicy` (cluster-admin)
  - `eks-read-only` → `AmazonEKSViewPolicy` (read-only, no Secrets access)
- **Atlantis**, deployed via the official Helm chart, running as a StatefulSet with a persistent `gp3` EBS volume, exposed through a Kubernetes `LoadBalancer` Service.
- **No static AWS credentials anywhere** — Atlantis and the EBS CSI driver each authenticate to AWS via **EKS Pod Identity**, not IAM user keys or node-role inheritance.
- **Remote Terraform state** in a versioned, encrypted, private S3 bucket, with S3-native state locking (no DynamoDB table needed).

## Requirements mapping

| Task requirement | Where it is |
| --- | --- |
| 1 VPC, 2 subnets, 1 EKS cluster | `terraform/1-infra/vpc.tf`, `terraform/1-infra/eks.tf` |
| Worker ASG min 1 / max 2 | `terraform/1-infra/eks.tf` → `eks_managed_node_groups` |
| `eks-admin` / `eks-read-only` IAM roles + RBAC| `terraform/1-infra/access.tf`, access entries in `eks.tf` |
| EKS + Atlantis deployed via Terraform and Helm | `terraform/2-atlantis/atlantis.tf` (`helm_release` resource) |
| Atlantis configured against this GitHub repo | `terraform/2-atlantis/github.tf` (webhook), `atlantis.yaml`, `repos.yaml` |
| Demo pull request proving Atlantis works | [PR #1](../../pull/1) — plan, `atlantis apply`, manual merge |
| All infrastructure as code| Everything under `terraform/`; no console-clicked resources |
| No manual deployment steps | `Makefile` (`make up` / `make down`) |

## Repository layout

```
terraform/
  0-bootstrap/   S3 state bcket, budget alarm
  1-infra/       VPC, EKS cluster, IAM roles
  2-atlantis/    Atlantis Helm release, GitHub webhook
demo/            Project Atlantis plans/applies in the demo PR
```

Each stack under `terraform/` is an independent Terraform working directory with its own state, applied in order (`0-bootstrap` → `1-infra` → `2-atlantis`), cause each depends on outputs from the previous one (the state bucket must exist before anything else; the cluster must exist before Atlantis can be deployed into it).

## Prerequisites

- Terraform ≥ 1.10, AWS CLI v2, kubectl, Helm, `make`, `jq`
- An AWS account on the **Paid plan** (cause EKS isn't available on the Free plan), a configured CLI profile as well
- A GitHub [fine-grained personal access token](https://www.runatlantis.io/docs/access-credentials) scoped to this repo (only these: Commit statuses, Contents, Pull requests, Webhooks)

Set these as env variables before running anything (e.g. in a local, git-ignored `.env` file, then `source .env`):

```bash
export AWS_PROFILE=<your-profile>
export TF_VAR_github_token="github_pat_..."
export TF_VAR_github_webhook_secret="$(openssl rand -hex 32)"
```

## Running it

```bash
make up      # bootstrap → infra → atlantis → verify
make down    # tears everything down in reverse order
```

`make verify` re-runs the RBAC proof (`scripts/verify-access.sh`) and an Atlantis health check against the running infra.

## Demo: Atlantis in action

[PR #1 — Add demo S3 bucket](../../pull/1) shows the full cycle:

1. PR opened touching `demo/*.tf` → Atlantis auto-plans within ~30s.
2. Plan comment: 4 resources to add.
3. `atlantis apply` comment → Atlantis applies using its own Pod Identity role (not my creds), and I merge the PR once the apply succeeds.

## Some design decisions and trade-offs

- **Public subnets, not private + NAT** — avoids a NAT Gateway (~$35/mo and a 3rd subnet) for a demo. Nodes get public IPs but are restricted by security groups. Prod would use private subnets with a NAT Gateway.
- **EKS access entries, not the `aws-auth` ConfigMap** — API-managed, atomic, no risk of a YAML typo locking everyone out of the cluster.
- **Pod Identity everywhere, no IRSA, no static keys** — Atlantis and the EBS CSI driver each get a narrowly-scoped IAM role associated to their specific namespace/service account.
- **Atlantis's IAM role is intentionally narrow**: it can only touch the state bucket's `demo/*` path and resources matching `atlantis-demo-*`. Atlantis effectively runs `terraform apply` for anyone who can open a PR, so its role is the real security boundary, not `AdministratorAccess`.
- **HTTP, not HTTPS, to Atlantis** — acceptable for this demo; production would add TLS via an ALB + ACM certificate, and likely restrict inbound traffic to GitHub's published webhook IP ranges.
- **Can't self-approve** — solo, so `repos.yaml` uses `apply_requirements: [mergeable]` rather than `[approved, mergeable]`; a team setup would require the latter.
- **`-auto-approve` in the Makefile** — required to meet "no manual steps"; production would use `terraform plan -out` → review → `apply` of that saved plan.

## Cost

Running cost is about $0.20/hour while deployed (EKS control plane + 1 node + load balancer). 
run `make down` when not actively using it.

## Limitations

- **Automerge doesn't work with the documented minimum token scope.** Atlantis's docs list `Contents: read-only` as sufficient, but merging a PR via the GitHub API needs `Contents: write`. With the token scoped to the documented minimum, `atlantis apply` succeeds and applies the infrastructure, but the automerge fails with a 403, so the PR is merged manually after.
