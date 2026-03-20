module "vpc" {
  source = "./vpc"
}

module "eks" {
  source = "./eks"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
}

module "argocd" {
  source     = "./argocd"
  depends_on = [module.eks]
}

module "monitoring" {
  source     = "./monitoring"
  depends_on = [module.eks]
}

module "storage" {
  source     = "./storage"
  depends_on = [module.eks]
}

module "iam" {
  source       = "./iam"
  cluster_name = module.eks.cluster_name
  vpc_id       = module.vpc.vpc_id
  oidc_issuer  = module.eks.oidc_issuer
  depends_on   = [module.eks]
}

module "ecr" {
  source = "./ecr"
}
