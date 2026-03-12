resource "alicloud_oss_bucket" "nextcloud" {
  bucket = var.bucket_name
  acl    = "private"
}