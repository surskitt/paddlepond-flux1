data "digitalocean_kubernetes_versions" "k8s_version" {}

resource "digitalocean_kubernetes_cluster" "cluster" {
  name    = "cluster"
  region  = "lon1"
  version = data.digitalocean_kubernetes_versions.k8s_version.latest_version

  node_pool {
    name = "default"
    size  = "s-1vcpu-2gb"
    node_count = 3
  }
}
