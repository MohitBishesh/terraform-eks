output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs ordered by availability_zones"
  value       = [for az in var.availability_zones : aws_subnet.public[az].id]
}

output "private_subnet_ids" {
  description = "Private subnet IDs ordered by availability_zones"
  value       = [for az in var.availability_zones : aws_subnet.private[az].id]
}

output "nat_gateway_id" {
  description = "Single NAT Gateway ID"
  value       = aws_nat_gateway.this.id
}

output "nat_gateway_public_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}
