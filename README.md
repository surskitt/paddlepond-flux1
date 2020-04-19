# paddlepond

Configuration for my paddlepond k3s cluster. Applied automatically using flux gitops.

![paddlepond](paddlepond.png)

## Node setup

The cluster runs on 3 raspberry pis, node setup details can be found in the [nodes directory](nodes).

## Flux operator setup

Flux can be installed into the cluster using the [flux bootstrap script](kube/flux/bootstrap.sh). This will will install the controller that will manage all further deployments.

To allow flux to access the repo, a deploy key needs to be added. This can be obtained from the cluster installing [fluxctl](https://docs.fluxcd.io/en/1.19.0/references/fluxctl/) and running the following command.

    fluxctl identity --k8s-fwd-ns flux

Add this key in the repo settings with write access.

## Secrets

Secrets can be created by installing [kubeseal](https://github.com/bitnami-labs/sealed-secrets) and using the following:

To fetch the public key certificate from the repo:

    kubeseal --fetch-cert \
        --controller-namespace=sealed-secrets \
        --controller-name=sealed-secrets \
    > pub-cert.pem

Create secrets using the standard methods, outputting to file rather than deploying to the cluster.

    kubectl -n dev create secret generic basic-auth \
        --from-literal=user=admin \
        --from-literal=password=admin \
        --dry-run \
        -o json > basic-auth.json

Use the public key to sign the secrets and create a sealedsecrets manifest.

    kubeseal --format=yaml --cert=pub-cert.pem < basic-auth.json > basic-auth.yaml

Delete the json, check in the yaml.

### Editing secrets

The [ss_edit.sh](kube/ss_edit.sh) script can be used to edit existing sealed secrets files. Run with `-h` to see the options.

If you need to add a new secret value, this can be done using kubeseal's `--merge-into` flag. [More details can be found here](https://github.com/bitnami-labs/sealed-secrets#update-existing-secrets).
