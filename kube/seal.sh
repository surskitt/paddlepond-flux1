#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage: ${0} [-p PUB_KEY] [-f SECRETS_TEMPLATE]"
    echo "Options:"
    echo "  -p    location of the sealed secrets public key (defaults to SCRIPT_DIR/pub-key.pem"
    echo "  -f    only use this file for secrets templating"
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

check_dep envsubst
check_dep base64
check_dep kubeseal

D="$(dirname "${0}")"

PUB_KEY_FN="${D}/pub-cert.pem"
SECRET_FILE_SEARCH="${D}"

while getopts 'p:f:h' opt; do
    case "${opt}" in
        p)
            PUB_KEY_FN="${OPTARG}"
            ;;
        f)
            SECRET_FILE_SEARCH="${OPTARG}"
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

# get a single quoted list of all environment variables in format $ENV and ${ENV}
ev=$(
    echo -n \'
    env|cut -d '=' -f 1|while read -r e; do
        echo -n \ \$"${e}" \$\{"${e}"\}
    done
    echo \'
)

tmpl_check() {
    for i in $(tr ' ' '\n' <<< "${2}" | tr '=' '\n'); do
        if grep -q '^\$' <<< "${i}"; then
            echo "WARNING: ${i} was not substituted in ${1}"
        fi
    done | sort -u >&2
}

tmpl() {
    # use ev env to only substitute vars in the env
    t="$(envsubst "${ev}" < "${1}")"

    tmpl_check "${1}" "${t}"

    echo "${t}"
}

seal_values() {
    IFS="_" read -r ns n _ <<< "${1##*/}"

    vb64=$(tmpl "${1}" | base64 -w 0)

    cat <<- EOF | kubeseal --format=yaml --cert="${PUB_KEY_FN}" > "${1%/*}/01-${n}-values.yml"
	apiVersion: v1
	kind: Secret
	metadata:
	  name: ${n}-values
	  namespace: ${ns}
	data:
	  values: ${vb64}
	type: Opaque
	EOF
}

env_data() {
    t="$(envsubst "${ev}" < "${1}")"

    tmpl_check "${1}" "${t}"

    envsubst < "${1}" | while IFS="=" read -r k v; do
        echo "  ${k}": "$(base64 -w 0 <<< "${v}")"
    done
}

seal_env() {
    IFS="_" read -r ns n _ <<< "${1##*/}"

    cat <<- EOF | kubeseal --format=yaml --cert="${D}/pub-cert.pem" > "${1%/*}/01-${n}-env.yml"
	apiVersion: v1
	kind: Secret
	metadata:
	  name: ${n}-env
	  namespace: ${ns}
	data:
	$(env_data "${1}")
	type: Opaque
	EOF
}

find "${SECRET_FILE_SEARCH}" -name '*_*_values.tmpl' | while read -r v; do
    echo "Sealing ${v}"
    seal_values "${v}"
done

find "${SECRET_FILE_SEARCH}" -name '*_*_env.tmpl' | while read -r v; do
    echo "Sealing ${v}"
    seal_env "${v}"
done
