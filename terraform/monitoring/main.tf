#############################################
# Namespace for Monitoring Stack
#############################################

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

#############################################
# Install kube-prometheus-stack via Helm
#############################################

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "56.6.0"

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.adminPassword"
    value = "grafana123"
  }
}

#############################################
# Outputs
#############################################

output "grafana_url" {
  value = "Run: kubectl get svc -n monitoring | grep grafana"
}
