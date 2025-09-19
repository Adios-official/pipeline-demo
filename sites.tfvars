region = "eu-central-1"
vpc_id = "vpc-098a239bad1a54322"
cluster_name = "emea-dev-site-2"
num_nodes = 1
num_nics = 1
instance_type = "t3.xlarge"
key_pair = "adios-keypair"
tags = {
  "Environment": "Development-Python-Tool",
  "Owner": "dev-team@f5.com",
  "SiteName": "emea-dev-site-2"
}
slo_subnet_ids = [
  "subnet-0d9c94fbbba9458db"
]
sli_subnet_ids = []
az_names = [
  "eu-central-1b"
]
api_p12_file = "creds.p12"
api_url = "https://sdc-support.console.ves.volterra.io/api"
ami = "ami-0d43e733ea176527a"
root_block_device = {
  "volume_size": 80,
  "volume_type": "gp2",
  "encrypted": false
}
eip_config = {
  "create_eip": true,
  "existing_allocation_ids": []
}
security_group_config = {
  "create_slo_sg": true,
  "create_sli_sg": true,
  "existing_slo_sg_id": "",
  "existing_sli_sg_id": ""
}