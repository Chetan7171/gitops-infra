#############################################
# Namespace for ArgoCD
#############################################

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

#############################################
# Install ArgoCD via Helm
#############################################

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.0"

  values = [
    <<EOF
server:
  service:
    type: LoadBalancer

configs:
  secret:
    argocdServerAdminPassword: "$2a$10$uQWy2yOj3Pa86VS1ezv5DO7uO3cu6sZHywkufzXkpAEpPOuD9mKWu"
EOF
  ]
}

#############################################
# Output
#############################################

output "argocd_namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}
