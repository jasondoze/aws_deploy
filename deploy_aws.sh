#!/bin/bash

# This script installs and configures the required command-line utilities, creates EC2 instances with the specified AMI ID, ports, security group, and connects to the instance via SSH.

# Homebrew should be installed
if ( which brew > /dev/null ) 
then
  echo -e "\n==== Homebrew currently installed ====\n"
else 
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo -e "\n==== Installing homebrew ====\n"
fi

# Install aws cli
if ( which aws > /dev/null ) 
then
  echo -e "\n==== Awscli currently installed ====\n"
else 
  brew install awscli
  echo "\n==== Installing awscli ====\n"
fi

# aws configure get cli_pager=less

# Create key pair and store locally 
if ( aws ec2 describe-key-pairs --key-name aws_rsa_key_pair --output text )
then
  echo -e "\n==== Key pair present ====\n"
else
  echo -e "\n==== Creating key pair ====\n"
  aws ec2 create-key-pair --key-name aws_rsa_key_pair --query 'KeyMaterial' --output text > aws_rsa_key_pair.pem && chmod 0600 aws_rsa_key_pair.pem 
fi

# Create the security group
if ( aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --output text )
then
  echo -e "\n==== Security group present ====\n"
else 
  aws ec2 create-security-group --group-name ssh_http --description "Allow SSH and HTTP" --region $AWS_DEFAULT_REGION --output text
  # Add a rule to the security group to allow SSH access from anywhere
  aws ec2 authorize-security-group-ingress --group-id $(aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --query 'SecurityGroups[*].[GroupId]' --output text) --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $AWS_DEFAULT_REGION
  # Add a rule to the security group to allow HTTP access from anywhere
  aws ec2 authorize-security-group-ingress --group-id $(aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --query 'SecurityGroups[*].[GroupId]' --output text) --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_DEFAULT_REGION
  echo -e "\n==== Security group created ====\n"
fi

# Create an EC2 instance
if [ $(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'length(Reservations[])>`0`' --output text) = 'True' ]
then
  echo -e "\n==== EC2 instance present ====\n"
else 
  aws ec2 run-instances --image-id ami-06878d265978313ca --instance-type t2.micro --security-group-ids $(aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --query 'SecurityGroups[*].[GroupId]' --output text) --count 1 --region $AWS_DEFAULT_REGION --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value="aws-instance-01"}]' --key-name aws_rsa_key_pair --associate-public-ip-address
  echo -e "\n==== EC2 instance created ====\n"
fi

echo -e "\n==== Wait for instance running ====\n"
aws ec2 wait instance-running --instance-ids $(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].InstanceId' --output text) 

# Connect to instance via SSH
sleep 30
echo -e "\n==== SSH into instance ====\n"
ssh -o StrictHostKeyChecking=no -i ./aws_rsa_key_pair.pem ubuntu@$(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text)

# aws configure set cli_pager=""