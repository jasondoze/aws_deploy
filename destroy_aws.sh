#!/bin/bash

# This script deletes IP fingerprint from AWS in Known hosts, terminates EC2 instances, deletes AWS key pairs, the RSA key pair, and security groups created in the deploy_aws script. It also removes aws fingerprints from known_hosts.

# Delete IP fingerprint from AWS to known_hosts
 ssh-keygen -F "~/.ssh/known_hosts" -R $(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].PublicIpAddress' --output text) 
# echo -e "\n==== Deleting host from known host ====\n"

# Check for instance
if [ $( aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'length(Reservations[])>`0`' --output text ) = 'True' ]
then
  # Terminate the instance
  aws ec2 terminate-instances --instance-ids $( aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].InstanceId' --output text ) 
  echo -e "\n==== Terminating EC2 instance ====\n"
else
  echo -e "\n==== No EC2 instance present ====\n"
fi

# Delete the key pair
if ( aws ec2 describe-key-pairs --key-name aws_rsa_key_pair )
then
  aws ec2 delete-key-pair --key-name aws_rsa_key_pair
  echo -e "\n==== Deleting RSA key pair ====\n"
else
  echo -e "\n==== No RSA key pair present ====\n"
fi

# Delete the RSA key pair file
if [ -f ./aws_rsa_key_pair.pem ]
then 
  rm -f ./aws_rsa_key_pair.pem
  echo -e "\n==== Deleted the key pair file ====\n"
else 
  echo -e "\n==== No key pair file present ====\n"
fi

# Delete the security group
if ( aws ec2 describe-security-groups --group-names ssh_http --region $AWS_DEFAULT_REGION --output text )
then
  aws ec2 wait instance-terminated --instance-ids $( aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'Reservations[*].Instances[*].InstanceId' --output text ) 
  echo -e "\n==== Deleting security group ====\n"
  aws ec2 delete-security-group --group-name ssh_http --region $AWS_DEFAULT_REGION 
else
  echo -e "\n==== No security group present ====\n"
fi
echo -e "\n==== Deleted security group ====\n"