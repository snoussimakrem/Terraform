# Outputs are this stack's PUBLIC API: other stacks read them via terraform_remote_state.
output "vpc_id" { value = module.network.vpc_id }
output "vpc_cidr_block" { value = module.network.vpc_cidr_block }
output "public_subnet_ids" { value = module.network.public_subnet_ids }
output "private_subnet_ids" { value = module.network.private_subnet_ids }
output "security_group_ids" { value = module.network.security_group_ids }
