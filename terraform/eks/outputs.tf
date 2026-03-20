# Required data sources so this module can output cluster info

data "aws_eks_cluster" "eks" {
  name = aws_eks_cluster.eks.name
}

data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

# Outputs for kubernetes/helm providers and IAM module

output "cluster_name" {
  value = aws_eks_cluster.eks.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_ca" {
  value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "oidc_issuer" {
  value = data.aws_eks_cluster.eks.identity[0].oidc[0].issuer
}
