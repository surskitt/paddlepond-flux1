# Paddlepond k3s cluster node setup

## Important notes

The following steps produces my specific setup. This assumes nodes with the names mentioned below and IPS of 192.168.2.1-3. Static IPs aren't used at present since I have setup the nodes in my router to always receive the same IPs.

## Prerequisites

- [flash](https://github.com/hypriot/flash)
- [Ubuntu server raspberry pi image](https://ubuntu.com/download/raspberry-pi)

## Setup

This directory contains cloud init config files that can be used alongside the flash tool to provision the k3s raspberry pi nodes. To flash an sd card, run:

    sudo flash -d <DEVICE> -u <NODE_YML> -F firmware/nobtcmd.txt -f <UBUNTU_IMAGE_FILE>

The image files are:

- **gadwall**: master node
- **pochard/muscovy**: worker nodes

(They're ducks).

The existing yaml files will give three nodes, with the master node ready and the workers ready to be joined either manually or with [k3sup](https://github.com/alexellis/k3sup).

## Alternative setup

Alternatively, the included scripts can be used to create config for the worker nodes that will allow them to join the master automatically.

First, provision the master node as normal. Wait for it to be ready before continuing.

    ssh gadwall.lan cat /etc/rancher/k3s/k3s.yaml|sed 's#127.0.0.1#192.168.2.1#g' > ~/.kube/config
    watch kubectl get nodes

Once the node is ready, run `addjoincmd.sh` against the worker node configs.

    ./addjoincmd.sh pochard.yml
    ./addjoincmd.sh muscovy.yml

This will produce `pochard_joincmd.yml` and `muscovy_join.yml`. These configs can be flashed using the above command. When booted, a 3 node cluster will be ready after a few minutes.
