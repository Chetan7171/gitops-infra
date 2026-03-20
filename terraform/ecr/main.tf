#########################################
# Create ECR Repository
#########################################

resource "aws_ecr_repository" "app_service" {
  name                 = "app-service"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

#########################################
# Optional: Cleanup old images
#########################################

resource "aws_ecr_lifecycle_policy" "cleanup" {
  repository = aws_ecr_repository.app_service.name

  policy = <<EOF
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep only 10 latest images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 10
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
EOF
}
