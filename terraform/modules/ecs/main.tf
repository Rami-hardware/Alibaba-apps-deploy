resource "alicloud_security_group" "ecs_sg" {
  vpc_id = var.vpc_id
  name   = "nextcloud-ecs-sg"
}

locals {
  ecs_instances = {
    nextcloud = {
      disk_size = 500
    }
    office = {
      disk_size = 200
    }
  }
}

resource "alicloud_instance" "ecs" {
  for_each = local.ecs_instances

  instance_name = "nextcloud-${each.key}"

  instance_type = "ecs.c6.xlarge"
  image_id      = "ubuntu_24_04_x64_20G_alibase_20250916.vhd"

  vswitch_id = var.vswitch_id

  security_groups = [alicloud_security_group.ecs_sg.id]

  system_disk_category = "cloud_essd"
  system_disk_size     = each.value.disk_size

  internet_max_bandwidth_out = 10
  key_name                   = "RamiKey"
}