##############################################################################################################################
# BLOCK 1 #  BASIC AWS VARIABLES
##############################################################################################################################
# AWS Region
region = "eu-central-1"

# VPC Information
vpc_id = "vpc-098a239bad1a54322"

#test23
##############################################################################################################################
# BLOCK 2 #  BASIC VARIABLES FOR CE 
# AWS Instance Information - Resources required per node: Minimum 4 vCPUs, 14 GB RAM, and 80 GB disk storage
# CHANGE THESE VALUES AS PER YOUR USE-CASE
##############################################################################################################################

# Base name for EC2 instances
cluster_name = "adios-awsedmo-git"    # Name for the customer Edge ( Each node will take this name followed by suffix like node-1, node-2 etc. )
num_nodes           = 3                      # Choose if you need a Single Node CE or an HA CE with 3 Nodes
num_nics            = 2                      # Use 1 for single NIC or 2 for dual NIC. If you need dual NIC, please fill section  # VPC Network for SLI
instance_type = "t3.xlarge"
ami = "ami-0d43e733ea176527a"
root_block_device = {                        # The root block device is the primary disk used to store the operating system and boot the instance.
  volume_size         = 80                   # Disk size in GB. 80 GB is minimum. (default size depends on the AMI, but you can override it).
  volume_type         = "gp2"                # Type of EBS volume (e.g., gp2 for General Purpose SSD, io1 for Provisioned IOPS SSD).
  encrypted           = false                # Whether the root volume is encrypted (default: false).
  }       
  key_pair            = "adios-keypair"         # This would be existing SSH key pair in AWS for Command line access to the nodes.
  tags = {                                   # Tags you would like to add to the nodes in the CE cluster. 
  "Environment"       = "Development"
  "customer_tag_1"    = "placeholder1"
  "Owner"             = "a.adityakiran@f5.com"
  "customer_tag_2"    = "placeholder2"
  }
  
  #instance_profile_name = "f5-xc-test-role"




##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.1 SLO CONFIG 
# Provide distinct SLO subnet values for each node if 3 nodes
# Carefully choose the public_ip_assignment type
##############################################################################################################################


# Subnet IDs (ensure these match the number of nodes if num_nodes = 3)
# Add your Subnet IDs here for SLO, 1 for each node in case of 3 nodes. For 1 node just 1 value is enough in the list.
slo_subnet_ids = [
  "subnet-059e3fda95314551d", # For node-1
  "subnet-0d9c94fbbba9458db", # For node-2
  "subnet-0e5f950266e0da4e1"  # For node-3
]

#slo_subnet_ids = ["subnet-059e3fda95314551d", "subnet-0d9c94fbbba9458db", "subnet-0e5f950266e0da4e1"]
#sli_subnet_ids = ["subnet-03a63abc02e7bbc2f", "subnet-060e182f9a5eb9efe", "subnet-002f328411355c7be"]
##############################################################################################################################
# BLOCK 3 #  NETWORKING AND NETWORK INTERFACES FOR NODES
# 3.2 SLI CONFIG 
# VALUES ARE ONLY CONSUMED IF YOU NEED DUAL NIC AND YOU HAVE GIVEN num_nics = 2
# Provide distinct SLI subnet values for each node if 3 nodes
##############################################################################################################################

# Subnet IDs (ensure these match the number of nodes if num_nodes = 3)
# Add your Subnetwork/Subnet name here for SLI, 1 for each node in case of 3 nodes. For 1 node just 1 value is enough in the list.
sli_subnet_ids = [
  "subnet-03a63abc02e7bbc2f", # For node-1
  "subnet-060e182f9a5eb9efe", # For node-2
  "subnet-002f328411355c7be"  # For node-3
]

##############################################################################################################################
# BLOCK 4 # PUBLIC IP ASSIGNMENT VARIABLES
##############################################################################################################################

# Elastic IP configuration (either create new EIPs or use existing ones)
# These are the Public Elastic IPs that would be then assigned to the SLO interface 
# If you don't want EIPs to be created by the code, you can use your existing EIPs by choosing create_eip as false and providing existing EIP Allocation IDs

eip_config = {
  create_eip  = true
  existing_allocation_ids = [
    
    ]  # Leave empty if create_eip is true, otherwise provide existing EIP Allocation IDs
}


##############################################################################################################################
# BLOCK 5 # AVAILABILITY ZONE DETAILS
# Provide distinct Availability zone values for each node if 3 nodes
##############################################################################################################################
# Availability Zones (ensure these match the number of nodes if num_nodes = 3)
az_names = [
  "eu-central-1a", # For node-1
  "eu-central-1b", # For node-2
  "eu-central-1c"  # For node-3
]


# User Data (Cloud-init to write token to /etc/vpm/user_data)
#proxy = "http://ec2-3-70-200-33.eu-central-1.compute.amazonaws.com:3128"

##############################################################################################################################
# BLOCK 6 # SECURITY GROUP DETAILS
##############################################################################################################################

# Security group configuration (either create new Security groups or use existing ones)
# When you choose to create new Security groups , the code creates a security group which has an allow all policy.
# If you want to add further rules, you can add in main.tf or you add additional rules to the security group after the site provisioning is complete.

security_group_config = {
  create_slo_sg     = true
  create_sli_sg     = true
  existing_slo_sg_id = ""    # Leave empty if create_slo_sg is true, otherwise provide existing Security group IDs for SLO interface
  existing_sli_sg_id = ""    # Leave empty if create_sli_sg is true, otherwise provide existing Security group  IDs for SLI interface
}


##############################################################################################################################
# BLOCK 7 # API CREDENTIAL DETAILS , TENANT DETAILS FROM DISTRIBUTED CLOUD
##############################################################################################################################

# These are arguments to supply your API credentials for interacting with the XC Tenant
api_p12_file = "creds.p12"
api_url      = "https://sdc-support.console.ves.volterra.io/api"
