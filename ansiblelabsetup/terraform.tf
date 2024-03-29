provider "aws" {
	access_key = "${var.aws_access_key}"
	secret_key = "${var.aws_secret_key}"
	region = "${var.aws_region}"
}

/* VPC */
resource "aws_vpc" "default" {
	cidr_block = "${var.vpc_cidr}"
	enable_dns_hostnames = true
	tags = {
		Name = "ansible_vpc"
	}
}
resource "aws_internet_gateway" "default" {
	vpc_id = "${aws_vpc.default.id}"
}

/* PUBLIC Subnet */
resource "aws_subnet" "public" {
	vpc_id = "${aws_vpc.default.id}"
	cidr_block = "${var.public_subnet_cidr}"
	availability_zone = "${var.public_availability_zone}"
	tags = {
		Name = "ansible_public"
	}
}
resource "aws_route_table" "default" {
	vpc_id = "${aws_vpc.default.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.default.id}"
	}
	tags = {
		Name = "Ansible_public"
	}
}
resource "aws_route_table_association" "default" {
	subnet_id = "${aws_subnet.public.id}"
	route_table_id = "${aws_route_table.default.id}"
}

/* PRIVATE SUBNET */
resource "aws_subnet" "private" {
        vpc_id = "${aws_vpc.default.id}"
        cidr_block = "${var.private_subnet_cidr}"
        availability_zone = "${var.private_availability_zone}"
        tags = {
                Name = "ansible_private"
        }
}

/* SECURITY GROUP */
resource "aws_security_group" "default" {
	name = "vpc_web"
	description = "Allow http,ssh and IMCP"
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
        ingress {
                from_port = 443
                to_port = 443 
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                from_port = 22 
                to_port = 22 
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        ingress {
                from_port = -1 
                to_port = -1
                protocol = "icmp" 
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                from_port = 80
                to_port = 80
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                from_port = 443
                to_port = 443
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                from_port = 22
                to_port = 22
                protocol = "tcp"
                cidr_blocks = ["0.0.0.0/0"]
        }
        egress {
                from_port = -1
                to_port = -1
                protocol = "icmp"
                cidr_blocks = ["0.0.0.0/0"]
        }

	vpc_id = "${aws_vpc.default.id}"
	tags = {
		Name = "Ansible_SG"
	}
}

/* INSTANCES */
resource "aws_instance" "slave1" {
	ami = "${lookup(var.amis, var.aws_region)}"
	availability_zone = "${var.private_availability_zone}"
	instance_type = "${var.instance_type}"
	key_name = "${var.aws_key_name}"
	vpc_security_group_ids = ["${aws_security_group.default.id}"]
	subnet_id = "${aws_subnet.private.id}"
	associate_public_ip_address = true
	tags = {
		Name = "Slave1"
	}
}
resource "aws_instance" "slave2" {
        ami = "${lookup(var.amis, var.aws_region)}"
        availability_zone = "${var.private_availability_zone}"
        instance_type = "${var.instance_type}"
        key_name = "${var.aws_key_name}"
        vpc_security_group_ids = ["${aws_security_group.default.id}"]
        subnet_id = "${aws_subnet.private.id}"
        associate_public_ip_address = true
        tags = {
                Name = "Slave2"
        }
}
resource "aws_instance" "master" {
        ami = "${lookup(var.amis, var.aws_region)}"
        availability_zone = "${var.public_availability_zone}"
        instance_type = "${var.instance_type}"
        key_name = "${var.aws_key_name}"
        vpc_security_group_ids = ["${aws_security_group.default.id}"]
        subnet_id = "${aws_subnet.public.id}"
        associate_public_ip_address = true
        tags = {
                Name = "master"
        }
	connection {
	type = "ssh"
	host = "${aws_instance.master.public_ip}"
	user = "ec2-user"
	private_key = "${file("~/.ssh/Mahi_amazon.pem")}"
	}
	provisioner "file" {
		source = "/root/.ssh/Mahi_amazon.pem"
		destination = "~/.ssh/Mahi_amazon.pem"
	}
	provisioner "remote-exec" {
		inline = [
			"sudo bash -c 'cp /home/ec2-user/.ssh/Mahi_amazon.pem /root/.ssh/'",
			"sudo bash -c 'chmod 400 /root/.ssh/Mahi_amazon.pem'",
			"sudo bash -c 'pip install ansible'",
			"sudo bash -c 'mkdir /ansible'",
			"sudo bash -c 'chmod 777 /ansible'",
			"sudo bash -c 'echo [defaults]' > /ansible/ansible.cfg",
			"sudo bash -c 'echo inventory = ./hosts' >> /ansible/ansible.cfg",
			"sudo bash -c 'echo [prod]' > /ansible/hosts",
			"sudo bash -c 'echo ${aws_instance.master.private_ip} ansible_ssh_private_key_file=~/.ssh/Mahi_amazon.pem ansible_user=ec2-user ansible_become=yes ansible_become_user=root' >> /ansible/hosts",
			"sudo bash -c 'echo [dev]' >> /ansible/hosts",
			"sudo bash -c 'echo ${aws_instance.slave1.private_ip} ansible_ssh_private_key_file=~/.ssh/Mahi_amazon.pem ansible_user=ec2-user ansible_become=yes ansible_become_user=root' >> /ansible/hosts",
			"sudo bash -c 'echo ${aws_instance.slave2.private_ip} ansible_ssh_private_key_file=~/.ssh/Mahi_amazon.pem ansible_user=ec2-user ansible_become=yes ansible_become_user=root' >> /ansible/hosts",
			"sudo bash -c 'chmod 666 /ansible'",
			"sudo bash -c 'chmod 666 /ansible/ansible.cfg /ansible/hosts'",
			"sudo su - root -c 'ansible -i /ansible/hosts -m command -a 'uptime' all'"
		]
	} 
}
