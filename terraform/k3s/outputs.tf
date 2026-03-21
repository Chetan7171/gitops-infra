output "public_ip" {
  value       = aws_instance.k3s.public_ip
  description = "Public IP of k3s node"
}

output "instance_id" {
  value       = aws_instance.k3s.id
  description = "EC2 instance ID (use for SSM session)"
}
