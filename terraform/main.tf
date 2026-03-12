data "alicloud_vpcs" "existing" {
  name_regex = "FAC-VPC"
}

data "alicloud_vswitches" "existing" {
  ids = ["vsw-l4vvxjkc508ncrc9lin9k"]
}

#module "ecs" {
#  source = "./modules/ecs"
#  vpc_id     = data.alicloud_vpcs.existing.vpcs[0].id
#  vswitch_id = data.alicloud_vswitches.existing.vswitches[0].id
#}

module "rds" {
  source = "./modules/rds"
  vswitch_id  = data.alicloud_vswitches.existing.vswitches[0].id
  zone_id     = data.alicloud_vswitches.existing.vswitches[0].zone_id
  db_password = var.db_password
}

module "oss" {
  source = "./modules/oss"
  bucket_name = "nextcloud-storage"
}