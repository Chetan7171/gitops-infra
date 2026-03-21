###############################
# k3s on t3.micro (free tier)
###############################

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_security_group" "k3s" {
  name        = "k3s-sg"
  description = "k3s single node"
  vpc_id      = var.vpc_id

  # Kubernetes API
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NodePort range (for accessing services from browser)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound (needed for ECR, GitHub, apt, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "k3s" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t3.micro"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.k3s.id]
  iam_instance_profile   = var.instance_profile_name

  root_block_device {
    volume_type = "gp2"
    volume_size = 20
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -e
    exec > /var/log/k3s-init.log 2>&1

    # Install k3s — disable traefik & metrics-server to save memory on t3.micro
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --disable=traefik --disable=metrics-server --write-kubeconfig-mode=644" sh -

    # Wait for k3s to be ready
    until /usr/local/bin/kubectl get nodes 2>/dev/null | grep -q "Ready"; do
      echo "Waiting for k3s..."
      sleep 5
    done
    echo "k3s is ready"

    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

    #########################################
    # ECR authentication helper
    # Runs on boot and refreshes every 6h
    #########################################
    cat > /usr/local/bin/refresh-ecr-secret.sh <<'SCRIPT'
    #!/bin/bash
    export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
    REGION="ap-south-1"
    ACCOUNT=$(aws sts get-caller-identity --query Account --output text --region $REGION 2>/dev/null)
    REGISTRY="${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com"
    TOKEN=$(aws ecr get-login-password --region $REGION 2>/dev/null)
    /usr/local/bin/kubectl create secret docker-registry ecr-secret \
      --docker-server="${REGISTRY}" \
      --docker-username="AWS" \
      --docker-password="${TOKEN}" \
      --namespace=default \
      --dry-run=client -o yaml | /usr/local/bin/kubectl apply -f -
    echo "ECR secret refreshed at $(date)"
    SCRIPT
    chmod +x /usr/local/bin/refresh-ecr-secret.sh

    # Run once now
    /usr/local/bin/refresh-ecr-secret.sh || true

    # Patch default service account to auto-use ECR secret
    /usr/local/bin/kubectl patch serviceaccount default -n default \
      -p '{"imagePullSecrets": [{"name": "ecr-secret"}]}' || true

    # Cron to refresh ECR token every 6 hours (tokens expire in 12h)
    echo "0 */6 * * * root /usr/local/bin/refresh-ecr-secret.sh >> /var/log/ecr-refresh.log 2>&1" \
      > /etc/cron.d/refresh-ecr

    #########################################
    # Install ArgoCD
    #########################################
    /usr/local/bin/kubectl create namespace argocd || true
    /usr/local/bin/kubectl apply -n argocd \
      -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.10.0/manifests/install.yaml

    # Run ArgoCD server without TLS (port-forward friendly)
    /usr/local/bin/kubectl patch deployment argocd-server -n argocd \
      --type='json' \
      -p='[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"--insecure"}]' || true

    # Save initial ArgoCD admin password to log
    echo "Waiting for ArgoCD secret..."
    sleep 60
    echo "ArgoCD admin password: $(/usr/local/bin/kubectl get secret argocd-initial-admin-secret \
      -n argocd -o jsonpath='{.data.password}' 2>/dev/null | base64 -d)" \
      >> /var/log/k3s-init.log

    echo "Setup complete!"
  USERDATA

  tags = {
    Name = "k3s-free-tier"
  }
}
