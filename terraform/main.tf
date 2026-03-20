module "vpc" {
  source = "./vpc"
}

module "eks" {
  source = "./eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}

module "argocd" {
  source = "./argocd"
}

module "monitoring" {
  source = "./monitoring"
}

module "storage" {
  source = "./storage"
}

module "iam" {
  source       = "./iam"
  cluster_name = module.eks.cluster_name
  vpc_id       = module.vpc.vpc_id
  oidc_issuer  = module.eks.oidc_issuer
}

module "ecr" {
  source = "./ecr"
}
