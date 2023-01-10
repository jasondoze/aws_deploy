#!/bin/bash

# If there is an instance, delete it
if [ $(aws ec2 describe-instances --filter Name=tag:Name,Values="aws-instance-01" 'Name=instance-state-name,Values=[running, stopped, pending]' --query 'length(Reservations[])>`0`' --out text) = 'True' ]
then
  aws ec2 terminate-instances --instance-ids i-0c8442492702f6f63 
  echo -e "==== Deleting EC2 instance ===="  
else 
  echo "==== No instance running ===="
fi