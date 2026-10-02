output "namespaces" {
  description = "name => name. Consumers reference this so Terraform orders them after the namespace exists."
  value       = { for k, ns in kubernetes_namespace_v1.this : k => ns.metadata[0].name }
}
