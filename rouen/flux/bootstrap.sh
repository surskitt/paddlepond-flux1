#!/usr/bin/env bash

FLUX_HELM_OPERATOR_CRD_URL=https://raw.githubusercontent.com/fluxcd/helm-operator/master/deploy/crds.yaml

check_dep() {
    dep="${1}"

    if ! type "${dep}" >/dev/null 2>&1; then
        echo "Error: ${dep} is not installed" >&2
        exit 1
    fi
}

check_dep helm
check_dep kubectl

helm repo add fluxcd https://charts.fluxcd.io

kubectl create ns flux

kubectl apply -f "${FLUX_HELM_OPERATOR_CRD_URL}"

helm upgrade -i flux fluxcd/flux --wait \
    --namespace flux \
    --version 1.2.0 \
    --set git.url=git@github.com:shanedabes/paddlepond.git \
    --set git.path=rouen \
    --set image.tag=1.18.0

helm upgrade -i helm-operator fluxcd/helm-operator --wait \
    --namespace flux \
    --set git.ssh.secretName=flux-git-deploy \
    --set helm.versions=v3 \
    --set image.tag=1.0.1
