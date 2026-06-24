# Terraform — apply order

Apply folders in number order: `00_bootstrap` → `01_vpc` → … → `10_kube-prometheus-stack`.

## Commands

**Bootstrap** (creates the S3 bucket):

```powershell
cd terraform/00_bootstrap
terraform init
terraform apply
```

After bootstrap, set the bucket name in each stack's `providers.tf` (from `terraform output state_bucket_name`).

**Every other stack:**

```powershell
cd terraform/01_vpc
terraform init
terraform apply
```

## How stacks get config

| What | Where it comes from |
|------|-------------------|
| This stack's state storage | `providers.tf` → `backend "s3"` |
| Bucket + region for reading other stacks | `bootstrap.tf` → `00_bootstrap` local state |
| VPC, EKS, keys, etc. | `data.tf` → `terraform_remote_state` |

No `backend.json` file — stacks read bucket/region from bootstrap outputs automatically.

## Stack dependencies

| Stack | Reads from |
|-------|------------|
| All stacks 01–10 | `00_bootstrap` (bucket, region) |
| `03_eks`, `04_jenkins`, `05_bastion` | `01_vpc`, `02_keys` |
| `06_ebs-csi-driver`, `08_alb-controller` | `03_eks` |
| `07_storage-class` | `06_ebs-csi-driver` |
| `09_argocd`, `10_kube-prometheus-stack` | `07_storage-class` |

## Prerequisites

- AWS credentials on your machine (for `terraform apply`)
- SSH public key at `shared/terra-key.pub`
- **kubectl** is run from the **bastion host** (not your laptop) — see `05_bastion` outputs after apply
- Stacks **06–10** run Helm/Kubernetes via Terraform: run `terraform apply` from the **bastion** (after kubeconfig is set there), or keep `~/.kube/config` on the machine where you run those applies

### Bastion → EKS workflow

```powershell
# 1. From your machine: get SSH command and kubeconfig setup command
cd terraform/05_bastion
terraform output -raw ssh_command
terraform output -raw setup_kubeconfig_command

# 2. SSH into bastion, configure AWS credentials (aws configure), then run setup_kubeconfig_command
# 3. On bastion: kubectl get nodes
```
