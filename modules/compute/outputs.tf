output "mode" { value = var.mode }
output "cluster_name" { value = var.cluster_name }
output "endpoint" {
  description = "API server URL (eks mode; null for kind - use kubeconfig)."
  value       = one(aws_eks_cluster.this[*].endpoint)
}
output "ca_data" {
  description = "Base64 CA certificate (eks mode)."
  value       = try(aws_eks_cluster.this[0].certificate_authority[0].data, null)
}
output "kubeconfig_path" { value = var.mode == "kind" ? pathexpand(var.kubeconfig_path) : null }
