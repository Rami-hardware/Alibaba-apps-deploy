output "rds_endpoint" {
  value = alicloud_db_instance.rds.connection_string
}

output "database_name" {
  value = alicloud_db_database.nextcloud_db.name
}

output "db_user" {
  value = alicloud_db_account.db_user.name
}
output "database_name" {
  value = alicloud_db_database.nextcloud_db.name
}

output "db_user" {
  value = alicloud_db_account.db_user.name
}