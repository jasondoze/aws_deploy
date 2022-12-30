#!/bin/bash

# Set the keys
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY

# Set the region
region=us-east-1

# Set the AMI ID
ami=ami-0b59bfac6be064b78

# Check if the security group exists (if it is -z zero length)
security_group_id=$(aws ec2 describe-security-groups --group-names ssh_http --region $region --output json | jq -r '.SecurityGroups[0].GroupId')
if [ -z "$security_group_id" ]
then
  # Create the security group
  security_group_id=$(aws ec2 create-security-group --group-name ssh_http --description "Allow SSH and HTTP" --region $region --output json | jq -r '.GroupId')
  echo -e "\n==== Security group created ===="

  # Add an ingress rule to the security group to allow incoming SSH connections using the aws ec2 authorize-security-group-ingress command
  # The --group-id flag specifies the ID of the security group to modify
  # The --protocol flag specifies the protocol (TCP in this case)
  # The --port flag specifies the port number (22 for SSH)
  # The --cidr flag specifies the IP address range that is allowed to make the connection
  # The --region flag specifies the region in which the security group was created
  aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region
  aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region

  # Add an egress rule to the security group to allow all outbound traffic using the aws ec2 authorize-security-group-egress command
  # The --group-id flag specifies the ID of the security group to modify
  # The --protocol flag specifies the protocol (-1 for all protocols)
  # The --port flag specifies the port number (0 for all ports)
  # The --cidr flag specifies the IP address range that is allowed to receive the outbound traffic
  # The --region flag specifies the region in which the security group was created
  aws ec2 authorize-security-group-egress --group-id $security_group_id --protocol -1 --port 0 --cidr 0.0.0.0/0 --region $region

# If the security group already exists, print a message
else
  echo -e "\n==== Security group already exists ===="
fi

# Check if the EC2 instance already exists using the aws ec2 describe-instances command
# The --filters flag specifies filters to use to describe the instances
# The "Name=image-id,Values=$ami" filter specifies that only instances with the specified AMI ID should be returned
# The "Name=instance-type,Values=t2.micro" filter specifies that only instances with the specified instance type should be returned
# The "Name=security-group-id,Values=$security_group_id" filter specifies that only instances with the specified security group ID should be returned
# The --region flag specifies the region in which the instances were created
# The --output json flag specifies that the output should be in JSON format
# The jq command is used to extract the instance ID from the output
instance_id=$(aws ec2 describe-instances --filters "Name=image-id,Values=$ami" "Name=instance-type,Values=t2.micro" "Name=security-group-id,Values=$security_group_id" --region $region --output json | jq -r '.Reservations[].Instances[].InstanceId')

# If the EC2 instance does not exist, create it
if [ -z "$instance_id" ]
then
  # Create the EC2 instance using the aws ec2 run-instances command
  # The --image-id flag specifies the ID of the AMI to use to launch the instance
  # The --instance-type flag specifies the type of instance to launch
  # The --security-group-ids flag specifies the security group ID to use for the instance
  # The --count flag specifies the number of instances to launch
  # The --region flag specifies the region in which the instance will be launched
  # The --output json flag specifies that the output should be in JSON format
  # The jq command is used to extract the instance ID from the output
  instance_id=$(aws ec2 run-instances --image-id $ami --instance-type t2.micro --security-group-ids $security_group_id --count 1 --region $region --output json | jq -r '.Instances[].InstanceId')
  echo -e "\n==== EC2 instance created ===="

# Wait for the EC2 instance to be running using the aws ec2 wait instance-running command
# The --instance-ids flag specifies the ID of the instance to wait for
# The --region flag specifies the region in which the instance was launched
aws ec2 wait instance-running --instance-ids $instance_id --region $region

# Retrieve the public IP address of the EC2 instance using the aws ec2 describe-instances command
# The --instance-ids flag specifies the ID of the instance to describe
# The --region flag specifies the region in which the instance was launched
# The --output json flag specifies that the output should be in JSON format
# The jq command is used to extract the public IP address from the output
public_ip=$(aws ec2 describe-instances --instance-ids $instance_id --region $region --output json | jq -r '.Reservations[].Instances[].PublicIpAddress')

# Log the public IP address of the EC2 instance
echo "Public IP address of EC2 instance: $public_ip"
