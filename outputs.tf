output "vpc_id" {
  description = "ID of the proof-of-concept VPC"
  value       = aws_vpc.poc.id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway"
  value       = aws_internet_gateway.poc.id
}

output "security_group_id" {
  description = "ID of the web and administrator security group"
  value       = aws_security_group.web_admin.id
}