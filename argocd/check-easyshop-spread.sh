#!/usr/bin/env bash
# =============================================================================
# check-easyshop-spread.sh
# =============================================================================
# Purpose:
#   After EasyShop is deployed, show where the app pods are running
#   (which worker node + which availability zone) and confirm topology
#   spread is working (or explain why it cannot work yet).
#
# Where to run:
#   Bastion host (needs kubectl access to the EKS cluster)
#
# How to run:
#   chmod +x argocd/check-easyshop-spread.sh
#   ./argocd/check-easyshop-spread.sh
# =============================================================================

set -euo pipefail

# --- Settings -----------------------------------------------------------------
NAMESPACE="easyshop"
POD_LABEL="app=easyshop"
MIN_PODS=2

# =============================================================================
# STEP 1 — Show every worker node and its AZ
# Why: topology spread can only use zones/nodes that actually exist.
# =============================================================================
echo
echo "================================================================="
echo " STEP 1: Cluster nodes and availability zones"
echo "================================================================="
echo
kubectl get nodes -L topology.kubernetes.io/zone -o wide
echo

# Count Ready nodes (STATUS column starts with Ready)
READY_NODE_COUNT=$(
  kubectl get nodes --no-headers \
    | awk '$2 ~ /^Ready/ { n++ } END { print n+0 }'
)

echo "Ready worker nodes: ${READY_NODE_COUNT}"
echo

# =============================================================================
# STEP 2 — List Running easyshop pods with node + AZ
# Why: this is the proof of where Kubernetes placed each replica.
# =============================================================================
echo "================================================================="
echo " STEP 2: EasyShop pods (node + AZ)"
echo "================================================================="
echo

# Pod name + node name for each Running easyshop pod
POD_ROWS=$(
  kubectl get pods -n "${NAMESPACE}" -l "${POD_LABEL}" \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' \
    2>/dev/null || true
)

if [[ -z "${POD_ROWS}" ]]; then
  echo "No Running easyshop pods found in namespace '${NAMESPACE}'."
  echo
  echo "Deploy first:"
  echo "  kubectl apply -f argocd/easyshop-application.yaml"
  echo
  exit 1
fi

# Table header
printf "  %-42s %-32s %s\n" "POD" "NODE" "ZONE"
printf "  %-42s %-32s %s\n" \
  "------------------------------------------" \
  "--------------------------------" \
  "------------"

POD_COUNT=0
SEEN_NODES=""
SEEN_ZONES=""

# For each pod: look up that node's AZ label and print a row
while IFS=$'\t' read -r POD_NAME NODE_NAME; do
  [[ -z "${POD_NAME:-}" ]] && continue

  # AZ label Kubernetes puts on every EKS node
  ZONE_NAME=$(
    kubectl get node "${NODE_NAME}" \
      -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' \
      2>/dev/null || echo "unknown"
  )

  printf "  %-42s %-32s %s\n" "${POD_NAME}" "${NODE_NAME}" "${ZONE_NAME}"

  POD_COUNT=$((POD_COUNT + 1))

  # Track unique nodes (space-separated list)
  case " ${SEEN_NODES} " in
    *" ${NODE_NAME} "*) ;;
    *) SEEN_NODES="${SEEN_NODES} ${NODE_NAME}" ;;
  esac

  # Track unique zones
  case " ${SEEN_ZONES} " in
    *" ${ZONE_NAME} "*) ;;
    *) SEEN_ZONES="${SEEN_ZONES} ${ZONE_NAME}" ;;
  esac
done <<< "${POD_ROWS}"

# Word-count = number of unique entries
UNIQUE_NODE_COUNT=$(echo "${SEEN_NODES}" | wc -w | tr -d ' ')
UNIQUE_ZONE_COUNT=$(echo "${SEEN_ZONES}" | wc -w | tr -d ' ')

echo
echo "  Running easyshop pods : ${POD_COUNT}   (expect ${MIN_PODS}+)"
echo "  Distinct nodes used   : ${UNIQUE_NODE_COUNT}"
echo "  Distinct AZs used     : ${UNIQUE_ZONE_COUNT}"
echo

# =============================================================================
# STEP 3 — Pass / skip / fail checks
# Why: turn the table into a clear yes/no for node spread and AZ spread.
# Soft topology (ScheduleAnyway) cannot invent nodes/AZs that do not exist.
# =============================================================================
echo "================================================================="
echo " STEP 3: Spread checks"
echo "================================================================="
echo

FAIL_COUNT=0

# --- Check A: enough pods Running --------------------------------------------
if [[ "${POD_COUNT}" -ge "${MIN_PODS}" ]]; then
  echo "  [OK]   Pod count — ${POD_COUNT} Running easyshop pod(s)."
else
  echo "  [FAIL] Pod count — need at least ${MIN_PODS} Running pods (got ${POD_COUNT})."
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Check B: Constraint 1 — spread across NODES -----------------------------
if [[ "${UNIQUE_NODE_COUNT}" -ge 2 ]]; then
  echo "  [OK]   Node spread — pods are on different worker nodes."
elif [[ "${READY_NODE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] Node spread — only ${READY_NODE_COUNT} Ready node in the cluster."
  echo "         Scale the node group to 2 workers, then re-run this script."
else
  echo "  [FAIL] Node spread — pods share the SAME node."
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# --- Check C: Constraint 2 — spread across AVAILABILITY ZONES ----------------
if [[ "${UNIQUE_ZONE_COUNT}" -ge 2 ]]; then
  echo "  [OK]   AZ spread — pods are in different availability zones."
elif [[ "${READY_NODE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] AZ spread — need Ready nodes in 2 AZs first."
  echo "         (Usually: desiredSize=2 on the EKS node group.)"
else
  echo "  [FAIL] AZ spread — pods are in the SAME availability zone."
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

# =============================================================================
# STEP 4 — Final result
# =============================================================================
echo
echo "================================================================="
echo " STEP 4: Final result"
echo "================================================================="
echo

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "  SUCCESS — spread looks good,"
  echo "  or checks were skipped until the cluster has enough capacity."
  echo
  exit 0
fi

echo "  FAILED — ${FAIL_COUNT} check(s) did not pass."
echo "  Review STEP 2 (pod placement) and STEP 3 messages above."
echo
exit 1
