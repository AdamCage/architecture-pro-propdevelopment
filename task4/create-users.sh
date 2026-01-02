#!/usr/bin/env bash
set -euo pipefail

# Task4: создание пользователей (x509) через CSR API Kubernetes.
# Плюсы: не нужен доступ к ca.key Minikube (актуально для Windows+WSL и для "реальных" кластеров).
#
# Требования:
# - minikube запущен
# - текущий kubectl-контекст имеет права создавать/подтверждать CSR (обычно это admin в minikube)

CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/certs"
KCFG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/kubeconfigs"
mkdir -p "${CERT_DIR}" "${KCFG_DIR}"

k() {
  if [[ -n "${KUBECTL:-}" ]]; then
    ${KUBECTL} "$@"
    return
  fi
  if command -v kubectl >/dev/null 2>&1; then
    if kubectl cluster-info >/dev/null 2>&1; then
      kubectl "$@"
      return
    fi
  fi
  if command -v minikube >/dev/null 2>&1; then
    minikube kubectl -- "$@"
    return
  fi
  if command -v minikube.exe >/dev/null 2>&1; then
    minikube.exe kubectl -- "$@"
    return
  fi
  echo "ERROR: kubectl не доступен (и minikube kubectl тоже). Установи kubectl/minikube или выставь KUBECTL." >&2
  exit 1
}

b64dec() {
  # GNU base64: -d, Busybox: -d, macOS: -D
  if base64 --help 2>/dev/null | grep -q -- "--decode"; then
    base64 --decode
  else
    # macOS
    base64 -D
  fi
}

# Берём server и CA из текущего контекста, при этом CA получаем через --flatten (будет certificate-authority-data)
SERVER="$(k config view --raw --minify -o jsonpath='{.clusters[0].cluster.server}')"
CA_DATA="$(k config view --raw --minify --flatten -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')"
CLUSTER_NAME="$(k config view --raw --minify -o jsonpath='{.clusters[0].name}')"

CA_FILE="${CERT_DIR}/cluster-ca.crt"
echo "${CA_DATA}" | b64dec > "${CA_FILE}"

make_user () {
  local user="$1"
  local group="$2"
  local ns="$3"    # default namespace for context

  local udir="${CERT_DIR}/${user}"
  mkdir -p "${udir}"

  echo "==> Creating user=${user}, group=${group}"

  # 1) key + csr (CN=username, O=group)
  openssl genrsa -out "${udir}/${user}.key" 2048 >/dev/null 2>&1
  openssl req -new -key "${udir}/${user}.key" -out "${udir}/${user}.csr" -subj "/CN=${user}/O=${group}" >/dev/null 2>&1

  # 2) CSR object in K8s
  local csr_name="csr-${user}"
  local csr_b64
  csr_b64="$(base64 -w 0 < "${udir}/${user}.csr" 2>/dev/null || base64 < "${udir}/${user}.csr" | tr -d '\n')"

  # Пересоздаём CSR (чтобы скрипт был идемпотентным)
  k delete certificatesigningrequest "${csr_name}" >/dev/null 2>&1 || true

  k apply -f - <<YAML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${csr_name}
spec:
  request: ${csr_b64}
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages:
    - client auth
YAML

  # 3) approve
  k certificate approve "${csr_name}" >/dev/null

  # 4) wait for cert
  echo -n "    waiting for certificate..."
  for i in $(seq 1 60); do
    local cert_data
    cert_data="$(k get csr "${csr_name}" -o jsonpath='{.status.certificate}' || true)"
    if [[ -n "${cert_data}" ]]; then
      echo " ok"
      echo "${cert_data}" | b64dec > "${udir}/${user}.crt"
      break
    fi
    sleep 1
  done

  if [[ ! -f "${udir}/${user}.crt" ]]; then
    echo ""
    echo "ERROR: сертификат для ${user} не выдан за 60 секунд. Проверь права на approve CSR." >&2
    exit 1
  fi

  # 5) kubeconfig for user
  local kcfg="${KCFG_DIR}/${user}.kubeconfig"
  rm -f "${kcfg}"

  k config --kubeconfig="${kcfg}" set-cluster "${CLUSTER_NAME}" \
    --server="${SERVER}" \
    --certificate-authority="${CA_FILE}" \
    --embed-certs=true >/dev/null

  k config --kubeconfig="${kcfg}" set-credentials "${user}" \
    --client-certificate="${udir}/${user}.crt" \
    --client-key="${udir}/${user}.key" \
    --embed-certs=true >/dev/null

  k config --kubeconfig="${kcfg}" set-context "${user}@${ns}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${user}" \
    --namespace="${ns}" >/dev/null

  k config --kubeconfig="${kcfg}" use-context "${user}@${ns}" >/dev/null

  # also add to default kubeconfig (optional, but convenient)
  k config set-credentials "${user}" \
    --client-certificate="${udir}/${user}.crt" \
    --client-key="${udir}/${user}.key" \
    --embed-certs=true >/dev/null

  k config set-context "${user}@${ns}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${user}" \
    --namespace="${ns}" >/dev/null

  echo "    kubeconfig: ${kcfg}"
}

# Минимум 2 пользователя (делаем 3 для покрытия всех типов ролей)
make_user "alice" "sales-viewers" "sales"
make_user "bob"   "platform-ops"  "platform"
make_user "carol" "security-auditors" "default"

echo ""
echo "==> Done."
echo "Проверка (примеры):"
echo "  kubectl --context alice@sales auth can-i get pods -n sales"
echo "  kubectl --context alice@sales auth can-i get secrets -n sales        # ожидается: no"
echo "  kubectl --context bob@platform auth can-i create namespace           # ожидается: yes"
echo "  kubectl --context carol@default auth can-i get secrets -n sales       # ожидается: yes"
