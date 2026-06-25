# Terraform — apply order

Apply stacks **in folder number order**. Run from your **PC** unless noted.

## Required now (core platform + Argo CD)

| # | Stack | Where | Notes |
|---|--------|--------|--------|
| 00 | `00_state` | PC | S3 state bucket — run once |
| 01 | `01_vpc` | PC | VPC, subnets, NAT |
| 02 | `02_route53_acm` | PC | `simsoliver.com` hosted zone + ACM wildcard cert |
| 03 | `03_keys` | PC | SSH key for EC2 |
| 04 | `04_eks` | PC | EKS cluster (private API) |
| 05 | `05_jenkins` | PC | Jenkins CI server |
| 06 | `06_bastion` | PC | Bastion — apply **after** `04_eks` |
| 07 | `07_alb-controller` | **Bastion** | AWS Load Balancer Controller |
| 08 | `08_external-dns` | **Bastion** | Auto Route 53 records from Ingress hostnames |
| 13 | `13_metrics-server` | **Bastion** | Metrics API for HPA + `kubectl top` — **before** easyshop HPA |
| 09 | `09_argocd` | **Bastion** | Argo CD — apply **after** `07` + `08` |

## Optional later

| # | Stack | When you need it |
|---|--------|------------------|
| 10 | `10_ebs-csi-driver` | Dynamic EBS volumes (MongoDB PVC) |
| 11 | `11_storage-class` | Default StorageClass — after `10_ebs-csi-driver` |
| 12 | `12_kube-prometheus-stack` | Monitoring (Grafana / Prometheus) |

## Bastion workflow (stacks 07–13)

```powershell
cd terraform/06_bastion
terraform output -raw ssh_command

# on bastion:
sudo cloud-init status --wait
kubectl get nodes
cd ~/tws-e-commerce-app_hackathon/terraform/07_alb-controller && terraform init && terraform apply
cd ~/tws-e-commerce-app_hackathon/terraform/08_external-dns && terraform init && terraform apply
cd ~/tws-e-commerce-app_hackathon/terraform/13_metrics-server && terraform init && terraform apply
cd ~/tws-e-commerce-app_hackathon/terraform/10_ebs-csi-driver && terraform init && terraform apply
cd ~/tws-e-commerce-app_hackathon/terraform/11_storage-class && terraform init && terraform apply
cd ~/tws-e-commerce-app_hackathon/terraform/09_argocd && terraform init && terraform apply
# optional:
cd ~/tws-e-commerce-app_hackathon/terraform/12_kube-prometheus-stack && terraform init && terraform apply
```

## Stack dependencies

| Stack | Reads from |
|-------|------------|
| All stacks | `00_state` (bucket, region) |
| `04_eks` | `01_vpc`, `03_keys` |
| `05_jenkins` | `01_vpc`, `03_keys` |
| `06_bastion` | `01_vpc`, `03_keys`, `04_eks` |
| `07_alb-controller`, `10_ebs-csi-driver`, `13_metrics-server` | `04_eks` |
| `08_external-dns` | `04_eks`, `02_route53_acm` |
| `11_storage-class` | `10_ebs-csi-driver` |

## Ingress hostnames (external-dns creates DNS for these)

Set hosts in each app's Ingress; external-dns syncs them to Route 53:

| App | File |
|-----|------|
| Argo CD | `09_argocd/values.yaml` — `server.ingress.hostname` |
| Grafana / Prometheus | `12_kube-prometheus-stack/values.yaml` |
| Easyshop | `kubernetes/09-ingress.yaml` |

## Prerequisites

- AWS credentials on your PC
- SSH public key at `shared/terra-key.pub`
- Stacks **07–12**: run from **bastion**
