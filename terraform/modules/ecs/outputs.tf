output "ecs_public_ips" {
  value = {
    for name, instance in alicloud_instance.ecs :
    name => instance.public_ip
  }
}