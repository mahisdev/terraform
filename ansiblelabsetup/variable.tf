variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_path" {}
variable "aws_key_name" {}
variable "aws_region" {
	description = "Region for the environment"
	default = "us-east-2"
}
variable "amis" {
	description = "AMIS for region"
	default = {
		us-east-2 = "ami-0c64dd618a49aeee8"
	}
}
variable "instance_type" {
	description = "Instance type like m,c and t"
	default = "t2.micro"
}
variable "vpc_cidr" {
	description = "VPC cidr block design"
	default = "192.168.0.0/16"
}
variable "public_subnet_cidr" {
	description = "Public subnet cidr block design"
	default = "192.168.1.0/24"
}
variable "private_subnet_cidr" {
	description = "Private subnet cidr block design"
	default = "192.168.2.0/24"
}
variable "public_availability_zone" {
	description = "Availability zone for public subnet"
	default = "us-east-2a"
}
variable "private_availability_zone" {
	description = "Availability zone for private subnet"
	default = "us-east-2b"
}
