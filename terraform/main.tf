provider "alicloud" {
  region = "me-central-1"
}

# 2. Define the desired zone in a local variable for reuse.
locals {
  # This selects the first available zone from the data source lookup.
  availability_zone = data.alicloud_zones.default.zones[0].id
}

data "alicloud_zones" "default" {
  available_resource_creation = "Instance"
}

data "alicloud_vpcs" "existing" {
  name_regex = "FAC-VPC" # Change if your VPC name is different
}

data "alicloud_vswitch" "existing" {
  id = "vsw-l4vvxjkc508ncrc9lin9k"
}

resource "alicloud_security_group" "default" {
  vpc_id = alicloud_vpc.vpc.id
}

resource "alicloud_instance" "instance" {
  availability_zone = local.availability_zone
  security_groups = [alicloud_security_group.default.id]
  instance_type              = "ecs.c9i.xlarge"
  system_disk_category       = "cloud_essd"
  image_id                   = "ubuntu_24_04_x64_20G_alibase_20250916.vhd"
  instance_name              = "nextcloud-ecs"
  vswitch_id = data.alicloud_vswitches.existing.vswitches[0].id
  internet_max_bandwidth_out = 10
  key_name = "RamiKey"
  system_disk_size = 200
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip = "0.0.0.0/0"
}
resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip = "0.0.0.0/0"
}
data "alicloud_oss_bucket" "existing" {
  bucket = "your-existing-bucket-name"
}