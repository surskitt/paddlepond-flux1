#!/usr/bin/env sh

if [ "${#}" -lt 1 ]; then
    echo "Usage: ${0} orig.yml"
    exit 1
fi

if [[ "${1}" != *.yml && "${1}" != *.yaml ]]; then
    echo 'Error: *.yml or *.yaml file expected'
    exit 1
fi

if [ ! -f "${1}" ]; then
    echo "Error: ${1} does not exist"
    exit 1
fi

ext="${1#*.}"
new_fn="${1%.${ext}}_joincmd.yml"

orig_yml="$(<${1})"

k3s_join_token="$(ssh gadwall.lan sudo cat /var/lib/rancher/k3s/server/node-token)"

cat << EOF > "${new_fn}"
${orig_yml}

runcmd:
  - curl -sfL https://get.k3s.io | K3S_URL=https://192.168.2.1:6443 K3S_TOKEN=${k3s_join_token} sh -
EOF
