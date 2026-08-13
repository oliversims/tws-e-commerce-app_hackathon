#!/usr/bin/env bash
# Destroy bastion stacks 13_kube-prometheus-stack → 07_alb-controller.
# Run on the bastion (needs kubectl / Helm access to the private EKS API).
# Order is the reverse of apply-07-to-13.sh.
#
# Before running: delete the easyshop Argo CD app / namespace if present
# (Ingresses/ALBs left behind can block later destroys).
#
# After each destroy, wait until related workloads/namespaces are gone so the
# next destroy is not racing ALB Ingress finalizers.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Wait until a namespace is fully deleted (ALB Ingress finalizers can delay this).
wait_ns_gone() {
  local ns="$1" timeout="${2:-600}"
  echo ">> waiting for namespace ${ns} to disappear (timeout ${timeout}s)"
  kubectl get ns "${ns}" >/dev/null 2>&1 || return 0
  kubectl wait --for=delete "namespace/${ns}" --timeout="${timeout}s" \
    || echo "WARNING: namespace ${ns} still present after ${timeout}s (check Ingress finalizers)"
}

# Wait until a Deployment is fully deleted.
wait_deploy_gone() {
  local ns="$1" name="$2" timeout="${3:-300}"
  echo ">> waiting for deploy/${name} gone from ${ns}"
  kubectl get deploy "${name}" -n "${ns}" >/dev/null 2>&1 || return 0
  kubectl wait --for=delete "deploy/${name}" -n "${ns}" --timeout="${timeout}s" \
    || echo "WARNING: deploy/${name} still present after ${timeout}s"
}

# ---------------------------------------------------------------------------
# 13_kube-prometheus-stack
# Destroys: Prometheus, Grafana, Alertmanager Helm release (namespace monitoring)
# Wait: namespace gone — ~1–2 min (ALB teardown)
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-1: Destroy kube-prometheus-stack using Terraform"
echo "==============================="
cd "${ROOT}/13_kube-prometheus-stack"
terraform init
terraform destroy --auto-approve
# Helm often leaves the namespace; Ingress ALB finalizers can block deletion.
kubectl get ingress -n monitoring -o name 2>/dev/null | while read -r ing; do
  kubectl patch -n monitoring "$ing" --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
done
kubectl delete namespace monitoring --wait=false 2>/dev/null || true
wait_ns_gone monitoring 900

# ---------------------------------------------------------------------------
# 12_metrics-server
# Destroys: metrics-server Helm release in kube-system
# Wait: deploy gone — ~20s
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-2: Destroy metrics-server using Terraform"
echo "==============================="
cd "${ROOT}/12_metrics-server"
terraform init
terraform destroy --auto-approve
wait_deploy_gone kube-system metrics-server 300

# ---------------------------------------------------------------------------
# 11_storage-class
# Destroys: default StorageClass "ebs-storage-class"
# Wait: StorageClass gone — ~2s
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-3: Destroy StorageClass using Terraform"
echo "==============================="
cd "${ROOT}/11_storage-class"
terraform init
terraform destroy --auto-approve
until ! kubectl get storageclass ebs-storage-class >/dev/null 2>&1; do sleep 2; done

# ---------------------------------------------------------------------------
# 10_ebs-csi-driver
# Destroys: EBS CSI driver Helm release + IRSA role
# Wait: ~10s
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-4: Destroy EBS CSI Driver using Terraform"
echo "==============================="
cd "${ROOT}/10_ebs-csi-driver"
terraform init
terraform destroy --auto-approve
# controller pods should leave kube-system
sleep 10

# ---------------------------------------------------------------------------
# 09_argocd
# Destroys: Argo CD Helm release (namespace argocd)
# Wait: namespace gone — ~1–2 min (ALB teardown)
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-5: Destroy Argo CD using Terraform"
echo "==============================="
cd "${ROOT}/09_argocd"
terraform init
terraform destroy --auto-approve
kubectl get ingress -n argocd -o name 2>/dev/null | while read -r ing; do
  kubectl patch -n argocd "$ing" --type=json -p='[{"op":"remove","path":"/metadata/finalizers"}]' 2>/dev/null || true
done
kubectl delete namespace argocd --wait=false 2>/dev/null || true
wait_ns_gone argocd 900

# ---------------------------------------------------------------------------
# 08_external-dns
# Destroys: ExternalDNS Helm release + IRSA policy/role
# Wait: deploy gone — ~20s
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-6: Destroy ExternalDNS using Terraform"
echo "==============================="
cd "${ROOT}/08_external-dns"
terraform init
terraform destroy --auto-approve
wait_deploy_gone kube-system external-dns 300

# ---------------------------------------------------------------------------
# 07_alb-controller
# Destroys: AWS Load Balancer Controller Helm release + IRSA policy/role
# Wait: ~15s
# ---------------------------------------------------------------------------
echo
echo "==============================="
echo "STEP-7: Destroy ALB Controller using Terraform"
echo "==============================="
cd "${ROOT}/07_alb-controller"
terraform init
terraform destroy --auto-approve
sleep 15

echo "Done: destroyed 13_kube-prometheus-stack → 07_alb-controller."
