#!/bin/bash

# This script installs and configures the required command-line utilities, creates EC2 instances with the specified Amazon Machine Image (AMI) ID, ports, security group, and connects to the instance via Secure Shell (SSH). Additionally, it also stores the RSA key in AWS Secrets Manager for secure management.

# Homebrew should be installed
if ( which brew > /dev/null )
then
  echo -e "\n==== Homebrew currently installed ====\n"
else 
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo -e "\n==== Installed homebrew ====\n"
fi

# Install aws cli
if ( which aws > /dev/null ) 
then
  echo -e "\n==== Awscli currently installed ====\n"
else 
  brew install awscli
  echo "\n==== Installed awscli ====\n"
fi

# aws configure get cli_pager=less

# Create key pair and store locally 
if ( aws ec2 describe-key-pairs --profile default --key-name aws_rsa_key )
then
  echo -e "\n==== Key pair present ====\n"
else
  aws ec2 create-key-pair --profile default --key-name aws_rsa_key --query 'KeyMaterial' --output text > aws_rsa_key.pem && chmod 0600 aws_rsa_key.pem 
  echo -e "\n==== Created key pair ====\n"
fi

if ( aws secretsmanager get-secret-value --profile default --secret-id rsa_secret_id --query 'SecretString' ) 
then 
  # Update the RSA key in Secrets Manager
  aws secretsmanager update-secret --profile default --secret-id rsa_secret_id --secret-string "$(cat aws_rsa_key.pem)" --description "SSH for aws log in"
  echo -e "\n==== Updated key pair in secrets manager ====\n"
else
  # Create a new RSA key in Secrets Manager
  aws secretsmanager create-secret --profile default --name rsa_secret_id --secret-string "$(cat aws_rsa_key.pem)" --description "SSH for aws log in"
  echo -e "\n==== Added key pair to secrets manager ====\n"
fi

# Create the security group, add a rule to the security group to allow SSH and HTTP access from anywhere  
if ( aws ec2 describe-security-groups --profile default --group-name ssh_http --output text)
then
  echo -e "\n==== Security group present ====\n"
else 
  aws ec2 create-security-group --profile default --group-name ssh_http --description "Allow SSH and HTTP" --output text
  aws ec2 authorize-security-group-ingress --profile default --group-id $(aws ec2 describe-security-groups --profile default --group-name ssh_http --query 'SecurityGroups[*].[GroupId]' --output text) --protocol tcp --port 22 --cidr 0.0.0.0/0
  aws ec2 authorize-security-group-ingress --profile default --group-id $(aws ec2 describe-security-groups --profile default --group-name ssh_http --query 'SecurityGroups[*].[GroupId]' --output text) --protocol tcp --port 80 --cidr 0.0.0.0/0
  echo -e "\n==== Security group created ====\n"
fi

# Create an EC2 instance
if [ $(aws ec2 describe-instances --profile default --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'length(Reservations[])>`0`' --output text) = 'True' ]
then
  echo -e "\n==== EC2 instance present ====\n"
else
  aws ec2 run-instances --profile default --image-id ami-06878d265978313ca --instance-type t2.micro --security-group-ids $(aws ec2 describe-security-groups --profile default --group-name ssh_http --query 'SecurityGroups[*].[GroupId]' --output text) --count 1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="aws-instance-01"}]' --key-name   --associate-public-ip-address
  echo -e "\n==== EC2 instance created ====\n"
fi

echo -e "\n==== Wait for EC2 instance running ====\n"
aws ec2 wait instance-running --profile default --instance-ids $(aws ec2 describe-instances --profile default --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].InstanceId' --output text) 
echo -e "\n==== EC2 instance running ====\n"

# Connect to instance via SSH
sleep 30
echo -e "\n==== SSH into instance ====\n"
ssh -o StrictHostKeyChecking=no -i ./aws_rsa_key.pem ubuntu@$(aws ec2 describe-instances --profile default --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

# aws configure set cli_pager=""