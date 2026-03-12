resource "alicloud_security_group" "ecs_sg" {
  vpc_id = var.vpc_id
  name   = "nextcloud-ecs-sg"
}

resource "alicloud_instance" "ecs" {
  instance_name = "nextcloud-ecs-office"

  instance_type = "ecs.c6.xlarge"
  image_id      = "ubuntu_24_04_x64_20G_alibase_20250916.vhd"

  vswitch_id = var.vswitch_id

  system_disk_category = "cloud_essd"
  system_disk_size     = 500

  security_groups = [alicloud_security_group.ecs_sg.id]

  internet_max_bandwidth_out = 10
  key_name                   = "RamiKey"
}