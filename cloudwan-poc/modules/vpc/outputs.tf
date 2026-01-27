output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_arn" {
  description = "VPC ARN"
  value       = aws_vpc.main.arn
}

output "attachment_subnet_id" {
  description = "Attachment subnet ID"
  value       = aws_subnet.attachment.id
}

output "workload_subnet_id" {
  description = "Workload subnet ID"
  value       = aws_subnet.workload.id
}

output "tgw_attachment_id" {
  description = "Transit Gateway VPC attachment ID"
  value       = aws_ec2_transit_gateway_vpc_attachment.main.id
}

output "cloudwan_attachment_id" {
  description = "CloudWAN VPC attachment ID"
  value       = aws_networkmanager_vpc_attachment.main.id
}

output "test_instance_id" {
  description = "Test EC2 instance ID"
  value       = aws_instance.test.id
}

output "test_instance_public_ip" {
  description = "Test EC2 instance public IP"
  value       = aws_instance.test.public_ip
}

output "test_instance_private_ip" {
  description = "Test EC2 instance private IP"
  value       = aws_instance.test.private_ip
}
