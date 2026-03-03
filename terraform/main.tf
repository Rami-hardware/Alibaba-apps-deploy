provider "alicloud" {
  region = "me-central-1"
}

# Get available zone
data "alicloud_zones" "default" {
  available_resource_creation = "Instance"
}

locals {
  availability_zone = data.alicloud_zones.default.zones[0].id
}

# Lookup existing VPC
data "alicloud_vpcs" "existing" {
  name_regex = "FAC-VPC"
}

# Create new Security Group inside existing VPC
resource "alicloud_security_group" "default" {
  vpc_id = data.alicloud_vpcs.existing.vpcs[0].id
  name   = "nextcloud-sg"
}

# Create ECS instance
resource "alicloud_instance" "instance" {
  availability_zone = local.availability_zone

  security_groups = [alicloud_security_group.default.id]

  instance_type        = "ecs.c9i.xlarge"
  system_disk_category = "cloud_essd"
  system_disk_size     = 200

  image_id      = "ubuntu_24_04_x64_20G_alibase_20250916.vhd"
  instance_name = "nextcloud-ecs"

  # Use your existing vSwitch directly
  vswitch_id = "vsw-l4vvxjkc508ncrc9lin9k"

  internet_max_bandwidth_out = 10
  key_name                   = "RamiKey"
}

#  SECURITY: Allow only required ports (recommended)
resource "alicloud_security_group_rule" "allow_http" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "80/80"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_https" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "443/443"
  priority          = 1
  security_group_id = alicloud_security_group.default.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  policy            = "accept"
  port_range        = "22/22"
  priority          = 1
  security_group_id = alicloud_security_group.default.id

  #  Change this to YOUR IP for better security
  cidr_ip = "0.0.0.0/0"
}