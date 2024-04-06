resource "kubernetes_horizontal_pod_autoscaler_v2" "example" {
  metadata {
    name = "example-hpa"
    namespace = "default"
  }

  spec {
    max_replicas = 10
    min_replicas = 2
    scale_target_ref {
      api_version = "apps/v1"
      kind       = "Deployment"
      name       = "example-deployment"
    }

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type               = "Utilization"
          average_utilization = 50
        }
      }
    }
  }
}
