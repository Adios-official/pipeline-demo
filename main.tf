
##############################################################################################################################
# BLOCK 1 #  Create SMSV2 site object on XC
##############################################################################################################################
resource "volterra_securemesh_site_v2" "smsv2-site-object" {
  name      = var.cluster_name
  namespace = "system"
  block_all_services = true
  logs_streaming_disabled = true
 # Conditionally set HA based on num_nodes
  # Set HA based on num_nodes
  disable_ha = var.num_nodes == 1 ? true : false
  enable_ha  = var.num_nodes == 3 ? true : false

  re_select {
    geo_proximity = true
  }

  aws {
    not_managed {}
    }
  }


##############################################################################################################################
# BLOCK 2 #  Create site token on XC
##############################################################################################################################
resource "volterra_token" "smsv2-token" {
  name      = "${volterra_securemesh_site_v2.smsv2-site-object.name}-token"
  namespace = "system"
  type      = 1
  site_name = volterra_securemesh_site_v2.smsv2-site-object.name

  depends_on = [volterra_securemesh_site_v2.smsv2-site-object]
}


##############################################################################################################################
# BLOCK 3 # Create Elastic IP(s) (EIP) 
##############################################################################################################################
resource "aws_eip" "example" {
  count = var.eip_config.create_eip && length(var.eip_config.existing_allocation_ids) == 0 ? var.num_nodes : 0
    tags = {
    Name = "${var.cluster_name}-slo-nic-eip-${count.index + 1}"
  }
} 
  
##############################################################################################################################
# BLOCK 4 # Create Network Interfaces
##############################################################################################################################
# Create SLO NICs
resource "aws_network_interface" "slo_nics" {
  count       = var.num_nodes
  subnet_id   = var.slo_subnet_ids[count.index]
  security_groups = var.security_group_config.create_slo_sg ? [aws_security_group.slo_sg[0].id] : [var.security_group_config.existing_slo_sg_id]
  

  tags = {
    Name = "${var.cluster_name}-slo-nic-${count.index + 1}"
  }
}

# Create SLI NICs (only if num_nics == 2)
resource "aws_network_interface" "sli_nics" {
  count       = var.num_nics == 2 ? var.num_nodes : 0
  subnet_id   = var.sli_subnet_ids[count.index]
  security_groups = var.security_group_config.create_sli_sg ? [aws_security_group.sli_sg[0].id] : [var.security_group_config.existing_sli_sg_id]

  tags = {
    Name = "${var.cluster_name}-sli-nic-${count.index + 1}"
  }
}


##############################################################################################################################
# BLOCK 5 # Create EC2 instance(s) / CE Node(s)
##############################################################################################################################

resource "aws_instance" "ec2_instance" {
  count = var.num_nodes
  
  ami               = var.ami
  instance_type     = var.instance_type
  
  
 
  key_name          = var.key_pair
  #iam_instance_profile = var.instance_profile_name
  availability_zone = element(var.az_names, count.index)

  root_block_device {
    volume_size = var.root_block_device["volume_size"]
    volume_type = var.root_block_device["volume_type"]
  }

  # Attach the primary NIC (SLO)
  network_interface {
    network_interface_id = aws_network_interface.slo_nics[count.index].id
    device_index         = 0
  }

  # Attach the secondary NIC (SLI), only if num_nics == 2
  dynamic "network_interface" {
    for_each = var.num_nics == 2 ? [1] : []
    content {
      network_interface_id = aws_network_interface.sli_nics[count.index].id
      device_index         = 1
    }
  }


  user_data = <<EOF
#cloud-config
write_files:
- path: /etc/vpm/user_data
  content: |
    token: ${volterra_token.smsv2-token.id}
  owner: root
  permissions: '0644'
EOF

  

  tags = merge({
    Name = "${var.cluster_name}-node-${count.index + 1}"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "ves-io-site-name" = var.cluster_name
  }, var.tags)

    lifecycle {
    create_before_destroy = true
  }
  

  depends_on = [volterra_token.smsv2-token]
}

##############################################################################################################################
# BLOCK 6 # Associate Elastic IP with Network Interfaces (SLO)
##############################################################################################################################
# Associate Elastic IPs with the SLO NICs (if created)
resource "aws_eip_association" "associate_eip" {
  count                = var.eip_config.create_eip && length(var.eip_config.existing_allocation_ids) == 0 ? var.num_nodes : 0
  network_interface_id = aws_network_interface.slo_nics[count.index].id
  allocation_id        = aws_eip.example[count.index].id
}

# Associate existing Elastic IPs (only if create_eip is false)
resource "aws_eip_association" "associate_existing_eip" {
  count                = var.eip_config.create_eip ? 0 : length(var.eip_config.existing_allocation_ids)
  network_interface_id = aws_network_interface.slo_nics[count.index].id
  allocation_id        = var.eip_config.existing_allocation_ids[count.index]
}

##############################################################################################################################
# BLOCK 7 # Create the Security Group for (SLO) if user wants new security group needs to be created
##############################################################################################################################
# Create SLO Security Group (always needed)
resource "aws_security_group" "slo_sg" {
  count = var.security_group_config.create_slo_sg ? 1 : 0
  name        = "${var.cluster_name}-slo-sg"
  description = "Security group for SLO interfaces"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.cluster_name}-slo-sg"
  }, var.tags)
}

##############################################################################################################################
# BLOCK 8 # Create the Security Group for (SLI) if user wants new security group needs to be created
##############################################################################################################################
# Create SLI Security Group (only if num_nics == 2 and create_sli_sg is true)
resource "aws_security_group" "sli_sg" {
  count = var.num_nics == 2 && var.security_group_config.create_sli_sg ? 1 : 0

  name        = "${var.cluster_name}-sli-sg"
  description = "Security group for SLI interfaces (only when num_nics == 2)"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({
    Name = "${var.cluster_name}-sli-sg"
  }, var.tags)
}
