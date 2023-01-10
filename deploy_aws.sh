#!/bin/bash

# This script installs and configures the required command-line utilities, creates an EC2 instance with the specified AMI ID and security group, and prints the public IP address of the instance.

# Homebrew should be installed
if ( which brew > /dev/null ) 
then
  echo -e "==== homebrew already installed ===="
else 
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "==== installing homebrew ===="
fi

# Install aws cli
if ( which aws > /dev/null ) 
then
  echo -e "\n==== awscli already installed ===="
else 
  brew install awscli
  echo "\n==== installing awscli ===="
fi

# Install jq
if ( which jq > /dev/null ) 
then
  echo -e "\n==== jq already installed ===="
else 
  brew install jq
  echo "\n==== installing jq ===="
fi

# Check if an aws key-pair is present
#  pipe the key pair to jq and write that key pair to a file named id_rsa 
if ( aws ec2 describe-key-pairs --key-name aws_rsa_key_pair --out text )
then
  echo -e "==== key pair present ===="
else
  echo -e "==== creating key pair ===="
  aws ec2 create-key-pair --key-name aws_rsa_key_pair --query 'KeyMaterial' --output text > aws_rsa_key_pair.pem 
  chmod 0600 aws_rsa_key_pair.pem 
fi

# Check if the security group exists (if it is -z zero length)
security_group_id=$(aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --output json | jq -r '.SecurityGroups[0].GroupId')
if [ -z "$security_group_id" ]
then
  # Create the security group
  security_group_id=$(aws ec2 create-security-group --group-name ssh_http --description "Allow SSH and HTTP" --region $AWS_DEFAULT_REGION --output json | jq -r '.GroupId')
  echo -e "==== security group created ===="

  # Add an ingress rule to the security group to allow incoming SSH connections using the aws ec2 authorize-security-group-ingress command
  # The --group-id flag specifies the ID of the security group to modify
  # The --protocol flag specifies the protocol (TCP in this case)
  # The --port flag specifies the port number (22 for SSH)
  # The --cidr flag specifies the IP address range that is allowed to make the connection
  # The --region flag specifies the region in which the security group was created
  aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $AWS_DEFAULT_REGION
  aws ec2 authorize-security-group-ingress --group-id $security_group_id --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_DEFAULT_REGION

  # Add an egress rule to the security group to allow all outbound traffic using the aws ec2 authorize-security-group-egress command
  # The --group-id flag specifies the ID of the security group to modify
  # The --protocol flag specifies the protocol (-1 for all protocols)
  # The --port flag specifies the port number (0 for all ports)
  # The --cidr flag specifies the IP address range that is allowed to receive the outbound traffic
  # The --region flag specifies the region in which the security group was created
  aws ec2 authorize-security-group-egress --group-id $security_group_id --protocol -1 --port 0 --cidr 0.0.0.0/0 --region $AWS_DEFAULT_REGION

# If the security group already exists, print a message
else
  echo -e "==== security group already exists ===="
fi

<<exists
# specify the AMI ID to check for
ami_id=""

# check if the specified AMI exists in the us-east-1 region
exists=$(aws ec2 describe-images --image-ids $ami_id --region us-east-1 --output text --query 'Images[*].ImageId')

# If the AMI doesn't exist
if [ -z "$exists" ]
then
  # Find the latest Linux t2.micro image in the us-east-1 region
  ami_id=$(aws ec2 describe-images --filters 'Name=architecture,Values=x86_64' 'Name=virtualization-type,Values=hvm' 'Name=root-device-type,Values=ebs' 'Name=block-device-mapping.volume-type,Values=gp2' 'Name=is-public,Values=true' 'Name=name,Values=amzn2-ami-hvm-2.0.*-x86_64-gp2' 'Name=owner-alias,Values=amazon' --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text --region us-east-1)
fi

# Assign the AMI ID to a variable for use in other parts of the script
ami_var=$ami_id
exists

# If the EC2 instance does not exist, create it
if [ $(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'length(Reservations[])>`0`' --out text) = 'False' ]
then
  # Create the EC2 instance using the aws ec2 run-instances command
  # The --image-id flag specifies the ID of the AMI to use to launch the instance
  # The --instance-type flag specifies the type of instance to launch
  # The --key-name flag specifies the rsa key-pair
  # The --security-group-ids flag specifies the security group ID to use for the instance
  # The --count flag specifies the number of instances to launch
  # The --region flag specifies the region in which the instance will be launched
  # The --output json flag specifies that the output should be in JSON format
  # The jq command is used to extract the instance ID from the output
 aws ec2 run-instances --image-id ami-06878d265978313ca --instance-type t2.micro --key-name aws_rsa_key_pair --security-group-ids $security_group_id --count 1 --region $AWS_DEFAULT_REGION --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=aws-instance-01}]" 
  echo -e "==== EC2 instance created ===="

  # Wait for the EC2 instance to be running using the aws ec2 wait instance-running command
  # The --instance-ids flag specifies the ID of the instance to wait for
  # The --region flag specifies the region in which the instance was launched
  aws ec2 wait instance-running --instance-ids $instance_id --region $AWS_DEFAULT_REGION
  
else 
  echo "Instance already created"
fi

# Log into the the EC2 instance with ssh
ssh -i ./aws_rsa_key_pair.pem ubuntu@$(aws ec2 describe-instances --instance-ids $instance_id --region $AWS_DEFAULT_REGION --output json | jq -r '.Reservations[].Instances[].PublicIpAddress')   
