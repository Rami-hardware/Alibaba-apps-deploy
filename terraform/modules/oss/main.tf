resource "alicloud_oss_bucket" "nextcloud" {
  bucket = "nextcloud-storage"
  acl    = "private"
}