#terraform
#Ansible Lab Setup
Ansible lab set up in AWS cloud, 
script will create below resources
Three Ec2 instances
VPC, 2 sunets(public and private)
IGW
SG
ansible installation will be on root

#Pre-requisites
Copy your pem file to ~/.ssh/ or /root/.ssh (copy it on machine where you are cloning)
make sure you have right permissions to your AWS account
  

#Variable 
Modify variable according to your requirement 

#Modification required files

variable.tf
terraform.tfvars
terraform.tf




