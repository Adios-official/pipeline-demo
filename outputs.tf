#########################################################################################################
# OUTPUT OF PUBLIC IPs Allocated to SLO
#########################################################################################################
output "allocated_public_ips_to_SLO" {
  description = "List of public IPs allocated to the instances."
  value = var.eip_config.create_eip == true && length(aws_eip.example) > 0 ? [for eip in aws_eip.example : eip.public_ip] : [for eip_alloc in var.eip_config.existing_allocation_ids : data.aws_eip.lookup[eip_alloc].public_ip]
}

# Data resource to fetch public IPs for existing allocation IDs
data "aws_eip" "lookup" {
  for_each = toset(var.eip_config.existing_allocation_ids)  # Loop over allocation IDs
  id       = each.key  # Use the allocation ID to fetch the EIP
}


