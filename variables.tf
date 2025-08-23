##############################################################################################################################
# BLOCK 1 #  AWS BASIC VARIABLES
##############################################################################################################################

variable "region" {
  description = "AWS region to launch the EC2 instances"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

##############################################################################################################################
# BLOCK 2 #  BASIC VARIABLES FOR CE 
##############################################################################################################################

variable "cluster_name" {
  description = "Base name for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "Instance type for the EC2 instances"
  type        = string
}

variable "num_nodes" {
  description = "Number of nodes to create (1 or 3)"
  type        = number
  validation {
    condition     = contains([1, 3], var.num_nodes)
    error_message = "The number of nodes must be either 1 or 3. The value '2' or any other value is not supported."
  }
}

# Number of NICs per node (1 or 2)
variable "num_nics" {
  description = "Number of NICs per instance (1 for single NIC, 2 for dual NIC)"
  type        = number
  validation {
    condition     = contains([1, 2], var.num_nics)
    error_message = "The number of Interfaces must be either 1 or 2. Any other value is not supported in this code."
  }
}


variable "ami" {
  description = "AMI ID for the EC2 instances"
  type        = string
}

variable "root_block_device" {
  description = "Block device configuration"
  type        = object({
    volume_size = number
    volume_type = string
  })
}

variable "key_pair" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "az_names" {
  description = "List of availability zones (1 if num_nodes = 1, 3 if num_nodes = 3)"
  type        = list(string)
}

variable "tags" {
  description = "Tags for EC2 instances"
  type        = map(string)
}
##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.1 SLO CONFIG 
##############################################################################################################################
variable "slo_subnet_ids" {
  description = "List of subnet IDs (1 if num_nodes = 1, 3 if num_nodes = 3)"
  type        = list(string)
}

##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.2 SLI CONFIG 
##############################################################################################################################

variable "sli_subnet_ids" {
  description = "List of subnets for the SLI NIC (only used if num_nics = 2)"
  type        = list(string)

}



#variable "security_group_ids" {
#  description = "List of security group IDs"
#  type        = list(string)
#}



#variable "instance_profile_name" {
#  description = "IAM instance profile name"
#  type        = string
#}






#variable "proxy" {
#  description = "Proxy to be used in the user data script"
#  type        = string
#}



#variable "delay_between_nodes" {
#  description = "Delay between the creation of each node (in seconds)"
#  type        = number
#  default     = 0  # Optional, not used in the main code
#}

##############################################################################################################################
# BLOCK 4 # PUBLIC IP ASSIGNMENT VARIABLES
##############################################################################################################################
variable "eip_config" {
  description = "Elastic IP configuration: either create new or use existing EIPs"
  type = object({
    create_eip    = bool
    existing_allocation_ids = list(string) # List of existing EIP IDs to associate if create_eip is false
  })
  default = {
    create_eip    = true
    existing_allocation_ids = []
  }

  validation {
    condition = (
      var.eip_config.create_eip == true && length(var.eip_config.existing_allocation_ids) == 0 || var.eip_config.create_eip == false && length(var.eip_config.existing_allocation_ids) != 0
    ) 
    error_message = "Validation failed:If 'create_eip' is true, 'existing_allocation_ids' should be empty. || If 'create_eip' is false, 'existing_allocation_ids' should not be empty and its length should match 'num_nodes'."
  }
}

##############################################################################################################################
# BLOCK 5 # SECURITY GROUP VARIABLES
##############################################################################################################################

# Security Group Configuration as an object
variable "security_group_config" {
  description = <<EOT
Configuration for Security Groups:
- create_slo_sg: Boolean to indicate whether to create a new SLO security group.
- create_sli_sg: Boolean to indicate whether to create a new SLI security group (only if num_nics == 2).
- existing_slo_sg_id: Existing security group ID for SLO (required if create_slo_sg is false).
- existing_sli_sg_id: Existing security group ID for SLI (required if create_sli_sg is false).
EOT
  type = object({
    create_slo_sg     = bool
    create_sli_sg     = bool
    existing_slo_sg_id = string
    existing_sli_sg_id = string
  })

  # Combined validation for both SLO and SLI security groups
# Combined validation for both SLO and SLI security groups
validation {
  condition = (
    # SLO security group validation
    (var.security_group_config.create_slo_sg && length(var.security_group_config.existing_slo_sg_id) == 0) || 
    (var.security_group_config.create_slo_sg == false && length(var.security_group_config.existing_slo_sg_id) > 0)
  ) && (
    # SLI security group validation 
      (var.security_group_config.create_sli_sg && length(var.security_group_config.existing_sli_sg_id) == 0) ||
      (var.security_group_config.create_sli_sg == false && length(var.security_group_config.existing_sli_sg_id) > 0)   
  )
    error_message = <<EOT
Invalid security group configuration. Please ensure that:
  - If create_slo_sg is false, existing_slo_sg_id must be provided.
  - If create_slo_sg is true, existing_slo_sg_id must be empty.
  - If create_sli_sg is false, existing_sli_sg_id must be provided.
  - If create_sli_sg is true, existing_sli_sg_id must be empty.
EOT
 }
}

##############################################################################################################################
# BLOCK 6 # AVAILABILITY ZONE DETAILS , TENANT DETAILS FROM DISTRIBUTED CLOUD
##############################################################################################################################

variable "api_p12_file" {
  description = "Path to the Volterra API Key"
  type        = string
}

variable "api_url" {
  description = "Volterra API URL"
  type        = string
}

