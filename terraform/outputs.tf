output "k3s_public_ip" {
  value       = module.k3s.public_ip
  description = "Public IP of k3s node — update kubeconfig with this IP"
}

output "k3s_instance_id" {
  value       = module.k3s.instance_id
  description = "EC2 instance ID — use for SSM session"
}

output "ecr_repository_url" {
  value = module.ecr.ecr_repository_url
}

output "next_steps" {
  value = <<-EOT
    === After terraform apply ===

    1. Wait ~3 mins for k3s + ArgoCD to install on the instance

    2. Connect via SSM (no SSH key needed):
       aws ssm start-session --target ${module.k3s.instance_id} --region ap-south-1

    3. Check setup log:
       sudo cat /var/log/k3s-init.log

    4. Get kubeconfig (run on your laptop):
       ssh -i <key> ec2-user@${module.k3s.public_ip} "sudo cat /etc/rancher/k3s/k3s.yaml" \
         | sed 's/127.0.0.1/${module.k3s.public_ip}/g' > ~/.kube/config

    5. Apply ArgoCD Application:
       kubectl apply -f https://raw.githubusercontent.com/Chetan7171/gitops-deploy/main/argocd-app.yaml

    6. Access ArgoCD UI (port-forward):
       kubectl port-forward svc/argocd-server -n argocd 8080:80
       Open: http://localhost:8080  (admin / see log above)

    === IMPORTANT: Destroy when done to avoid charges ===
       terraform destroy
  EOT
}
