#######################################
# Namespace for PostgreSQL
#######################################

resource "kubernetes_namespace" "postgres" {
  metadata {
    name = "postgres"
  }
}

#######################################
# StorageClass for EBS gp3
#######################################

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"
  }

  storage_provisioner = "ebs.csi.aws.com"

  parameters = {
    type = "gp3"
  }

  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
}

#######################################
# Secret for PostgreSQL password
#######################################

resource "kubernetes_secret" "postgres_secret" {
  metadata {
    name      = "postgres-secret"
    namespace = kubernetes_namespace.postgres.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = "postgres"
  }

  type = "Opaque"
}

#######################################
# PostgreSQL via Helm
#######################################

resource "helm_release" "postgresql" {
  name       = "postgresql"
  namespace  = kubernetes_namespace.postgres.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"

  set {
    name  = "auth.username"
    value = "postgres"
  }

  set {
    name  = "auth.password"
    value = "postgres"
  }

  set {
    name  = "auth.database"
    value = "users"
  }

  set {
    name  = "primary.persistence.storageClass"
    value = "gp3"
  }

  set {
    name  = "primary.persistence.size"
    value = "10Gi"
  }
}

output "postgresql_service" {
  value = "postgresql.postgres.svc.cluster.local"
}
