# Terraform — apply order

Apply stacks **in folder number order**. Run from your **PC** unless noted.

## Required now (core platform)

| # | Stack | Where | Notes |
|---|--------|--------|--------|
| 00 | `00_state` | PC | S3 state bucket — run once |
| 01 | `01_vpc` | PC | VPC, subnets, NAT; private subnets tagged for Karpenter |
| 02 | `02_route53_acm` | PC | `simsoliver.com` hosted zone + ACM wildcard cert |
| 03 | `03_keys` | PC | SSH key for EC2 |
| 04 | `04_eks` | PC | EKS cluster (private API) + Karpenter IAM/SQS |
| 05 | `05_jenkins` | PC | Jenkins CI EC2 — included in apply-01-to-06.sh |
| 06 | `06_bastion` | PC | Bastion — apply **after** `04_eks` |
| 07 | `07_alb-controller` | **Bastion** | AWS Load Balancer Controller |
| 08 | `08_external-dns` | **Bastion** | Auto Route 53 records from Ingress hostnames |
| 09 | `09_argocd` | **Bastion** | Argo CD — apply **after** `07` + `08` |
| 10 | `10_ebs-csi-driver` | **Bastion** | Dynamic EBS volumes (MongoDB PVC) |
| 11 | `11_storage-class` | **Bastion** | Default StorageClass — after `10_ebs-csi-driver` |
| 12 | `12_metrics-server` | **Bastion** | Metrics API for HPA + `kubectl top` |
| 13 | `13_kube-prometheus-stack` | **Bastion** | Monitoring (Grafana / Prometheus) |
| 14 | `14_external-secrets` | **Bastion** | External Secrets Operator + IRSA (AWS Secrets Manager) |
| 15 | `15_karpenter` | **Bastion** | Node autoscaler — extra SPOT workers when pods are Pending |
| 16 | `16_logging` | **Bastion** | Elasticsearch + Filebeat + Kibana — after `07` `08` `10` `11` |

## Helpers

```powershell
# PC (after 00_state + backend bucket names updated):
bash terraform/apply-01-to-06.sh

# Bastion:
bash terraform/apply-07-to-16.sh
```

Destroy is the reverse: `destroy-16-to-07.sh` on the bastion, then `destroy-06-to-01.sh` on the PC.

## Bastion workflow (stacks 07–16)

```powershell
cd terraform/06_bastion
terraform output -raw ssh_command

# on bastion:
sudo cloud-init status --wait
kubectl get nodes
cd ~/tws-e-commerce-app_hackathon/terraform
bash apply-07-to-16.sh
```

## How node scaling works

Terraform `desired_size` on the EKS managed node group is ignored after create. Keep **one** managed node as the bootstrap pool (Karpenter + system pods). When HPA creates extra EasyShop pods that do not fit:

1. Pods go **Pending**
2. Karpenter launches SPOT `t3`/`t3a` nodes in the private subnets
3. When load drops, Karpenter consolidates empty/underused nodes (after 5 minutes)

Limits in `15_karpenter/nodepool.yaml`: 8 CPU / 16 GiB (about four `t3.large` nodes).

Apply `01_vpc` and `04_eks` from your PC **before** `15_karpenter` so discovery tags and IAM exist.

## Stack dependencies

| Stack | Reads from |
|-------|------------|
| `01`–`08`, `10`–`11`, `14`–`15` | `00_state` (bucket, region) |
| `04_eks` | `01_vpc`, `03_keys` |
| `05_jenkins` | `01_vpc`, `03_keys` |
| `06_bastion` | `01_vpc`, `03_keys`, `04_eks` |
| `07_alb-controller`, `10_ebs-csi-driver`, `14_external-secrets`, `15_karpenter` | `04_eks` |
| `08_external-dns` | `04_eks`, `02_route53_acm` |
| `11_storage-class` | `10_ebs-csi-driver` |
| `09_argocd`, `12_metrics-server`, `13_kube-prometheus-stack`, `16_logging` | none (Helm only; S3 backend hardcoded) |

## Ingress hostnames (external-dns creates DNS for these)

Set hosts in each app's Ingress; external-dns syncs them to Route 53:

| App | File |
|-----|------|
| Argo CD | `09_argocd/values.yaml` — `server.ingress.hostname` |
| Grafana / Prometheus | `13_kube-prometheus-stack/values.yaml` |
| Kibana | `helm-values/kibana.yaml` |
| Easyshop | `kubernetes/ingress.yaml` |

## Prerequisites

- AWS credentials on your PC
- SSH public key at `shared/terra-key.pub`
- Stacks **07–16**: run from **bastion**
