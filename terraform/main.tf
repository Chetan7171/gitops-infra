module "vpc" {
  source = "./vpc"
}

module "iam" {
  source = "./iam"
}

module "ecr" {
  source = "./ecr"
}

module "k3s" {
  source                = "./k3s"
  vpc_id                = module.vpc.vpc_id
  subnet_id             = module.vpc.public_subnet_id
  instance_profile_name = module.iam.instance_profile_name
  depends_on            = [module.iam]
}
