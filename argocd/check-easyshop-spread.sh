#!/usr/bin/env bash
# =============================================================================
# check-easyshop-spread.sh
# =============================================================================
# Shows WHERE EasyShop pods landed (node + AZ) in a clear visual layout,
# then confirms node spread and AZ spread.
#
#   chmod +x argocd/check-easyshop-spread.sh
#   ./argocd/check-easyshop-spread.sh
# =============================================================================

set -euo pipefail

NAMESPACE="easyshop"
POD_LABEL="app=easyshop"
MIN_PODS=2

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
hr() { printf '%s\n' "-----------------------------------------------------------------"; }

zone_of_node() {
  kubectl get node "$1" \
    -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' \
    2>/dev/null || echo "unknown"
}

# =============================================================================
# STEP 1 — Cluster capacity (what we can spread onto)
# =============================================================================
echo
echo "================================================================="
echo " STEP 1: Cluster capacity"
echo "================================================================="
echo
echo "  Worker nodes available for scheduling:"
echo

printf "  %-28s  %-14s  %s\n" "NODE" "ZONE" "STATUS"
hr | sed 's/^/  /'

READY_NODE_COUNT=0
ALL_ZONES=""

while read -r NODE STATUS _; do
  [[ -z "${NODE:-}" ]] && continue
  ZONE=$(zone_of_node "${NODE}")
  printf "  %-28s  %-14s  %s\n" "${NODE%%.*}" "${ZONE}" "${STATUS}"
  if [[ "${STATUS}" == Ready* ]]; then
    READY_NODE_COUNT=$((READY_NODE_COUNT + 1))
    case " ${ALL_ZONES} " in
      *" ${ZONE} "*) ;;
      *) ALL_ZONES="${ALL_ZONES} ${ZONE}" ;;
    esac
  fi
done < <(kubectl get nodes --no-headers | awk '{print $1, $2}')

CLUSTER_ZONE_COUNT=$(echo "${ALL_ZONES}" | wc -w | tr -d ' ')

echo
echo "  Ready nodes : ${READY_NODE_COUNT}"
echo "  Ready AZs   : ${CLUSTER_ZONE_COUNT}  ($(echo ${ALL_ZONES}))"
echo

# =============================================================================
# STEP 2 — Collect Running easyshop pods
# =============================================================================
POD_ROWS=$(
  kubectl get pods -n "${NAMESPACE}" -l "${POD_LABEL}" \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' \
    2>/dev/null || true
)

if [[ -z "${POD_ROWS}" ]]; then
  echo "================================================================="
  echo " STEP 2: EasyShop pods"
  echo "================================================================="
  echo
  echo "  No Running easyshop pods in namespace '${NAMESPACE}'."
  echo "  Deploy first: kubectl apply -f argocd/easyshop-application.yaml"
  echo
  exit 1
fi

POD_COUNT=0
SEEN_NODES=""
SEEN_ZONES=""
# Parallel arrays via newline lists for bash 4 portability without assoc arrays for display
POD_LINES=""

while IFS=$'\t' read -r POD_NAME NODE_NAME; do
  [[ -z "${POD_NAME:-}" ]] && continue
  ZONE_NAME=$(zone_of_node "${NODE_NAME}")
  SHORT_NODE="${NODE_NAME%%.*}"
  SHORT_POD="${POD_NAME}"

  POD_LINES="${POD_LINES}${SHORT_POD}|${SHORT_NODE}|${ZONE_NAME}"$'\n'
  POD_COUNT=$((POD_COUNT + 1))

  case " ${SEEN_NODES} " in
    *" ${SHORT_NODE} "*) ;;
    *) SEEN_NODES="${SEEN_NODES} ${SHORT_NODE}" ;;
  esac
  case " ${SEEN_ZONES} " in
    *" ${ZONE_NAME} "*) ;;
    *) SEEN_ZONES="${SEEN_ZONES} ${ZONE_NAME}" ;;
  esac
done <<< "${POD_ROWS}"

UNIQUE_NODE_COUNT=$(echo "${SEEN_NODES}" | wc -w | tr -d ' ')
UNIQUE_ZONE_COUNT=$(echo "${SEEN_ZONES}" | wc -w | tr -d ' ')

# =============================================================================
# STEP 2a — Simple table
# =============================================================================
echo "================================================================="
echo " STEP 2: Where each EasyShop pod is running"
echo "================================================================="
echo
printf "  %-42s  %-22s  %s\n" "POD" "NODE" "ZONE"
hr | sed 's/^/  /'

while IFS='|' read -r P N Z; do
  [[ -z "${P:-}" ]] && continue
  printf "  %-42s  %-22s  %s\n" "${P}" "${N}" "${Z}"
done <<< "${POD_LINES}"

echo
echo "  Total Running pods : ${POD_COUNT}"
echo

# =============================================================================
# STEP 2b — Visual map by AZ (this is the "spread picture")
# =============================================================================
echo "================================================================="
echo " STEP 3: Spread map (pods grouped by availability zone)"
echo "================================================================="
echo
echo "  Ideal with 2 replicas + 2 AZs:"
echo
echo "       us-east-1a              us-east-1b"
echo "      +----------------+      +----------------+"
echo "      |  1 easyshop    |      |  1 easyshop    |"
echo "      +----------------+      +----------------+"
echo
echo "  Actual placement now:"
echo

# Build unique zone list from pods (and show empty Ready AZs with 0 pods)
MAP_ZONES="${SEEN_ZONES}"
for Z in ${ALL_ZONES}; do
  case " ${MAP_ZONES} " in
    *" ${Z} "*) ;;
    *) MAP_ZONES="${MAP_ZONES} ${Z}" ;;
  esac
done

for ZONE in ${MAP_ZONES}; do
  echo "  +---------------------------------------------------------------+"
  printf "  |  AZ: %-54s |\n" "${ZONE}"
  echo "  +---------------------------------------------------------------+"

  ZONE_POD_COUNT=0
  while IFS='|' read -r P N Z; do
    [[ -z "${P:-}" ]] && continue
    if [[ "${Z}" == "${ZONE}" ]]; then
      ZONE_POD_COUNT=$((ZONE_POD_COUNT + 1))
      printf "  |    * %-20s  on node %-22s |\n" "${P:0:20}" "${N}"
    fi
  done <<< "${POD_LINES}"

  if [[ "${ZONE_POD_COUNT}" -eq 0 ]]; then
    printf "  |    (no easyshop pods in this AZ)%-28s |\n" ""
  fi

  printf "  |  Pods in this AZ: %-42s |\n" "${ZONE_POD_COUNT}"
  echo "  +---------------------------------------------------------------+"
  echo
done

# =============================================================================
# STEP 2c — Visual map by NODE
# =============================================================================
echo "================================================================="
echo " STEP 4: Spread map (pods grouped by worker node)"
echo "================================================================="
echo

# Unique nodes from cluster Ready set + pods
MAP_NODES=""
while read -r NODE STATUS _; do
  [[ -z "${NODE:-}" ]] && continue
  [[ "${STATUS}" != Ready* ]] && continue
  SHORT="${NODE%%.*}"
  case " ${MAP_NODES} " in
    *" ${SHORT} "*) ;;
    *) MAP_NODES="${MAP_NODES} ${SHORT}" ;;
  esac
done < <(kubectl get nodes --no-headers | awk '{print $1, $2}')

for NODE in ${MAP_NODES}; do
  NODE_ZONE="?"
  # find zone for this short node name from pod lines or kubectl
  FULL_NODE=$(kubectl get nodes --no-headers | awk -v s="${NODE}" '$1 ~ s {print $1; exit}')
  if [[ -n "${FULL_NODE}" ]]; then
    NODE_ZONE=$(zone_of_node "${FULL_NODE}")
  fi

  echo "  +---------------------------------------------------------------+"
  printf "  |  NODE: %-20s  AZ: %-24s |\n" "${NODE}" "${NODE_ZONE}"
  echo "  +---------------------------------------------------------------+"

  NODE_POD_COUNT=0
  while IFS='|' read -r P N Z; do
    [[ -z "${P:-}" ]] && continue
    if [[ "${N}" == "${NODE}" ]]; then
      NODE_POD_COUNT=$((NODE_POD_COUNT + 1))
      printf "  |    * %-54s |\n" "${P}"
    fi
  done <<< "${POD_LINES}"

  if [[ "${NODE_POD_COUNT}" -eq 0 ]]; then
    printf "  |    (no easyshop pods on this node)%-26s |\n" ""
  fi

  printf "  |  Pods on this node: %-40s |\n" "${NODE_POD_COUNT}"
  echo "  +---------------------------------------------------------------+"
  echo
done

# =============================================================================
# STEP 5 — Pass / fail
# =============================================================================
echo "================================================================="
echo " STEP 5: Did spread succeed?"
echo "================================================================="
echo

FAIL_COUNT=0

echo "  Summary counts"
echo "    Running easyshop pods : ${POD_COUNT}   (need ${MIN_PODS}+)"
echo "    Distinct nodes used   : ${UNIQUE_NODE_COUNT}   (need 2 for node spread)"
echo "    Distinct AZs used     : ${UNIQUE_ZONE_COUNT}   (need 2 for AZ spread)"
echo

if [[ "${POD_COUNT}" -ge "${MIN_PODS}" ]]; then
  echo "  [OK]   Pod count"
else
  echo "  [FAIL] Pod count — only ${POD_COUNT} Running (need ${MIN_PODS}+)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [[ "${UNIQUE_NODE_COUNT}" -ge 2 ]]; then
  echo "  [OK]   NODE spread  — each pod is on a DIFFERENT worker"
elif [[ "${READY_NODE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] NODE spread  — cluster only has ${READY_NODE_COUNT} Ready node"
else
  echo "  [FAIL] NODE spread  — both pods share the SAME worker"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [[ "${UNIQUE_ZONE_COUNT}" -ge 2 ]]; then
  echo "  [OK]   AZ spread    — each pod is in a DIFFERENT zone"
elif [[ "${READY_NODE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] AZ spread    — need Ready nodes in 2 AZs first"
else
  echo "  [FAIL] AZ spread    — both pods are in the SAME zone"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo
echo "================================================================="
echo " RESULT"
echo "================================================================="
echo

if [[ "${FAIL_COUNT}" -eq 0 && "${UNIQUE_NODE_COUNT}" -ge 2 && "${UNIQUE_ZONE_COUNT}" -ge 2 ]]; then
  echo "  SUCCESS — EasyShop IS spread across nodes AND AZs."
  echo
  echo "  Picture:"
  echo "    Zone A  -->  1 pod"
  echo "    Zone B  -->  1 pod"
  echo
  exit 0
fi

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "  PARTIAL — no hard failures, but full multi-AZ spread"
  echo "  needs 2 Ready nodes in 2 different zones."
  echo
  exit 0
fi

echo "  FAILED — ${FAIL_COUNT} check(s) did not pass."
echo "  Look at STEP 3 (AZ map) and STEP 4 (node map) above."
echo
exit 1
