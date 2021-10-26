

output "vpc_name" {
  value = module.jenkins-vpc.network_name
}

output "subnet_names" {
  value = module.jenkins-vpc.subnets_names
}