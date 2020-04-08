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
