#!/usr/bin/env bash
# =============================================================================
# check-easyshop-spread.sh
# =============================================================================
# Shows WHERE EasyShop pods landed (node + AZ), then checks topology spread.
# Matches kubernetes/easyshop-deployment.yaml:
#   replicas: 3
#   maxSkew: 1 on kubernetes.io/hostname and topology.kubernetes.io/zone
#   whenUnsatisfiable: DoNotSchedule
#
#   chmod +x argocd/check-easyshop-spread.sh
#   ./argocd/check-easyshop-spread.sh
# =============================================================================

set -euo pipefail

NAMESPACE="easyshop"
POD_LABEL="app=easyshop"
MAX_SKEW=1

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
hr() { printf '%s\n' "-----------------------------------------------------------------"; }

zone_of_node() {
  kubectl get node "$1" \
    -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}' \
    2>/dev/null || echo "unknown"
}

count_on() {
  local needle="$1"
  local field="$2"
  local n=0
  while IFS='|' read -r P N Z; do
    [[ -z "${P:-}" ]] && continue
    if [[ "${field}" == "node" && "${N}" == "${needle}" ]]; then
      n=$((n + 1))
    elif [[ "${field}" == "zone" && "${Z}" == "${needle}" ]]; then
      n=$((n + 1))
    fi
  done <<< "${POD_LINES}"
  echo "${n}"
}

skew_of() {
  local field="$1"
  shift
  local min="" max=""
  for item in "$@"; do
    [[ -z "${item}" ]] && continue
    local c
    c=$(count_on "${item}" "${field}")
    if [[ -z "${min}" || "${c}" -lt "${min}" ]]; then min="${c}"; fi
    if [[ -z "${max}" || "${c}" -gt "${max}" ]]; then max="${c}"; fi
  done
  if [[ -z "${min}" ]]; then
    echo "0"
    return
  fi
  echo $((max - min))
}

# =============================================================================
# STEP 1 — Cluster capacity
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
MAP_NODES=""

while read -r NODE STATUS _; do
  [[ -z "${NODE:-}" ]] && continue
  ZONE=$(zone_of_node "${NODE}")
  SHORT="${NODE%%.*}"
  printf "  %-28s  %-14s  %s\n" "${SHORT}" "${ZONE}" "${STATUS}"
  if [[ "${STATUS}" == Ready* ]]; then
    READY_NODE_COUNT=$((READY_NODE_COUNT + 1))
    case " ${MAP_NODES} " in
      *" ${SHORT} "*) ;;
      *) MAP_NODES="${MAP_NODES} ${SHORT}" ;;
    esac
    case " ${ALL_ZONES} " in
      *" ${ZONE} "*) ;;
      *) ALL_ZONES="${ALL_ZONES} ${ZONE}" ;;
    esac
  fi
done < <(kubectl get nodes --no-headers | awk '{print $1, $2}')

CLUSTER_ZONE_COUNT=$(echo "${ALL_ZONES}" | wc -w | tr -d ' ')

DESIRED=$(kubectl get deploy easyshop -n "${NAMESPACE}" \
  -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "")
MIN_PODS="${DESIRED:-3}"

echo
echo "  Ready nodes : ${READY_NODE_COUNT}"
echo "  Ready AZs   : ${CLUSTER_ZONE_COUNT}  ($(echo ${ALL_ZONES}))"
echo "  Desired pods: ${MIN_PODS}  (Deployment spec.replicas / HPA)"
echo

# =============================================================================
# STEP 2 — Collect easyshop pods
# =============================================================================
POD_ROWS=$(
  kubectl get pods -n "${NAMESPACE}" -l "${POD_LABEL}" \
    --field-selector=status.phase=Running \
    -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.nodeName}{"\n"}{end}' \
    2>/dev/null || true
)

PENDING_ROWS=$(
  kubectl get pods -n "${NAMESPACE}" -l "${POD_LABEL}" --no-headers 2>/dev/null \
    | awk '$3=="Pending" {print $1}' || true
)

if [[ -z "${POD_ROWS}" ]]; then
  echo "================================================================="
  echo " STEP 2: EasyShop pods"
  echo "================================================================="
  echo
  echo "  No Running easyshop pods in namespace '${NAMESPACE}'."
  echo "  Deploy first: kubectl apply -f argocd/easyshop-application.yaml"
  echo
  if [[ -n "${PENDING_ROWS}" ]]; then
    echo "  Pending pods (spread may be blocking schedule):"
    echo "${PENDING_ROWS}" | sed 's/^/    /'
    echo
  fi
  exit 1
fi

POD_COUNT=0
SEEN_NODES=""
SEEN_ZONES=""
POD_LINES=""

while IFS=$'\t' read -r POD_NAME NODE_NAME; do
  [[ -z "${POD_NAME:-}" ]] && continue
  ZONE_NAME=$(zone_of_node "${NODE_NAME}")
  SHORT_NODE="${NODE_NAME%%.*}"

  POD_LINES="${POD_LINES}${POD_NAME}|${SHORT_NODE}|${ZONE_NAME}"$'\n'
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

NODE_SKEW=$(skew_of node ${MAP_NODES})
ZONE_SKEW=$(skew_of zone ${ALL_ZONES})

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
if [[ -n "${PENDING_ROWS}" ]]; then
  echo "  Pending pods       :"
  echo "${PENDING_ROWS}" | sed 's/^/    /'
  echo "  (Pending + DoNotSchedule usually means spread could not place the pod.)"
fi
echo

# =============================================================================
# STEP 3 — Visual map by AZ
# =============================================================================
echo "================================================================="
echo " STEP 3: Spread map (pods grouped by availability zone)"
echo "================================================================="
echo
echo "  Ideal with ${MIN_PODS} replicas and 3 AZs (maxSkew ${MAX_SKEW}):"
echo
echo "       us-east-1a              us-east-1b              us-east-1c"
echo "      +----------------+      +----------------+      +----------------+"
echo "      |  1 easyshop    |      |  1 easyshop    |      |  1 easyshop    |"
echo "      +----------------+      +----------------+      +----------------+"
echo
echo "  Actual placement now:"
echo

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
# STEP 4 — Visual map by NODE
# =============================================================================
echo "================================================================="
echo " STEP 4: Spread map (pods grouped by worker node)"
echo "================================================================="
echo

for NODE in ${MAP_NODES}; do
  NODE_ZONE="?"
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
# STEP 5 — Pass / fail (maxSkew 1 across ALL ready nodes and AZs)
# =============================================================================
echo "================================================================="
echo " STEP 5: Did spread succeed?"
echo "================================================================="
echo

FAIL_COUNT=0

echo "  Summary counts"
echo "    Running easyshop pods : ${POD_COUNT}   (need ${MIN_PODS}+)"
echo "    Distinct nodes used   : ${UNIQUE_NODE_COUNT}"
echo "    Distinct AZs used     : ${UNIQUE_ZONE_COUNT}"
echo "    Hostname skew         : ${NODE_SKEW}   (need <= ${MAX_SKEW}; counts empty Ready nodes)"
echo "    Zone skew             : ${ZONE_SKEW}   (need <= ${MAX_SKEW}; counts empty Ready AZs)"
echo

if [[ "${POD_COUNT}" -ge "${MIN_PODS}" ]]; then
  echo "  [OK]   Pod count"
else
  echo "  [FAIL] Pod count — only ${POD_COUNT} Running (need ${MIN_PODS}+)"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [[ -n "${PENDING_ROWS}" ]]; then
  echo "  [FAIL] Pending pods — scheduler could not place at least one replica"
  FAIL_COUNT=$((FAIL_COUNT + 1))
else
  echo "  [OK]   No Pending easyshop pods"
fi

if [[ "${READY_NODE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] NODE spread  — cluster only has ${READY_NODE_COUNT} Ready node"
elif [[ "${NODE_SKEW}" -le "${MAX_SKEW}" ]]; then
  echo "  [OK]   NODE spread  — hostname maxSkew ${NODE_SKEW} <= ${MAX_SKEW}"
else
  echo "  [FAIL] NODE spread  — hostname maxSkew ${NODE_SKEW} > ${MAX_SKEW}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

if [[ "${CLUSTER_ZONE_COUNT}" -lt 2 ]]; then
  echo "  [SKIP] AZ spread    — need Ready nodes in 2 AZs first"
elif [[ "${ZONE_SKEW}" -le "${MAX_SKEW}" ]]; then
  echo "  [OK]   AZ spread    — zone maxSkew ${ZONE_SKEW} <= ${MAX_SKEW}"
else
  echo "  [FAIL] AZ spread    — zone maxSkew ${ZONE_SKEW} > ${MAX_SKEW}"
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi

echo
echo "================================================================="
echo " RESULT"
echo "================================================================="
echo

if [[ "${FAIL_COUNT}" -eq 0 && "${NODE_SKEW}" -le "${MAX_SKEW}" && "${ZONE_SKEW}" -le "${MAX_SKEW}" && "${POD_COUNT}" -ge "${MIN_PODS}" ]]; then
  echo "  SUCCESS — EasyShop is spread within maxSkew ${MAX_SKEW} on nodes AND AZs."
  echo
  echo "  Picture:"
  for ZONE in ${MAP_ZONES}; do
    echo "    ${ZONE}  -->  $(count_on "${ZONE}" zone) pod(s)"
  done
  echo
  exit 0
fi

if [[ "${FAIL_COUNT}" -eq 0 ]]; then
  echo "  PARTIAL — no hard failures, but full spread needs more Ready nodes/AZs."
  echo
  exit 0
fi

echo "  FAILED — ${FAIL_COUNT} check(s) did not pass."
echo "  Look at STEP 3 (AZ map) and STEP 4 (node map) above."
echo
exit 1
