#!/usr/bin/env bash

#
# Edit sealed secrets yaml files
#

usage() {
    echo "Usage: ${0} [-p PUB_KEY] [-n NAMESPACE] -s SECRETS_FILE -S SECRET_NAME"
    echo "Options:"
    echo "  -p    location of the sealed secrets public key"
    echo "  -n    sealed-secrets namespace"
    echo "  -s    secrets file to decrypt"
    echo "  -S    name of secret to edit"
    echo "  -h    show this help"
}

check_dep() {
    dep="${1}"

    if ! type "${dep}" >/dev/null 2>&1; then
        echo "Error: ${dep} is not installed" >&2
        exit 1
    fi
}

check_opt() {
    if [ -z "${1}" ]; then
        echo "${2}" >&2
        echo >&2
        usage >&2
        exit 1
    fi
}

check_dep kubeseal
check_dep yq
check_dep kubectl
check_dep git
check_dep base64

SS_PUBLIC_KEY="$(git rev-parse --show-toplevel)/kube/pub-cert.pem"
SS_NAMESPACE="sealed-secrets"

while getopts 'p:n:s:S:h' opt; do
    case "${opt}" in
        p)
            SS_PUBLIC_KEY="${OPTARG}"
            ;;
        n)
            SS_NAMESPACE="${OPTARG}"
            ;;
        s)
            SECRETS_FILE="${OPTARG}"
            ;;
        S)
            SECRET_NAME="${OPTARG}"
            ;;
        h)
            usage
            exit
            ;;
        ?)
            usage >&2
            exit 1
            ;;
    esac
done

if [ ! -f "${SS_PUBLIC_KEY}" ]; then
    echo "Error: ${SS_PUBLIC_KEY} does not exist" >&2
    exit 1
fi

check_opt "${SECRETS_FILE}" "Error: pass a secrets file using -y"
check_opt "${SECRET_NAME}"  "Error: pass a secret name using -S"

SS_PRIV="$(kubectl -n ${SS_NAMESPACE} get secret -l sealedsecrets.bitnami.com/sealed-secrets-key -o yaml)"

SECRETS=$(kubeseal --recovery-unseal --recovery-private-key <(echo "${SS_PRIV}") --cert "${SS_PUBLIC_KEY}" < "${SECRETS_FILE}")

TEMPSECRET="$(mktemp)"
yq -r ".data[\"${SECRET_NAME}\"]" <<< "${SECRETS}"|base64 -d > "${TEMPSECRET}"

${EDITOR:-vim} "${TEMPSECRET}"
NEWSECRET="$(base64 -w 0 ${TEMPSECRET})"

rm "${TEMPSECRET}"

yq ".data[\"${SECRET_NAME}\"] = \"${NEWSECRET}\"" <<< "${SECRETS}" | kubeseal --format=yaml --cert="${SS_PUBLIC_KEY}" > "${SECRETS_FILE}"
