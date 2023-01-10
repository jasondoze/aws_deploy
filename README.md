# AWS_Deploy

## Mac OS only

<br>
# Overview

## This script is for deploying infrascructure in amazon.
---

### This script installs and configures the brew, awscli, and jq command-line utilities if they are not already installed on the system.


### Next, it prompts the user to configure their AWS credentials using the aws configure command.

<br>

### Then, it sets the Amazon Machine Image (AMI) used to create the EC2 instance, and checks if a security group with the specified name exists. If it does not exist, the script creates the security group and adds ingress and egress rules to it.

<br>

### Next, the script checks if an EC2 instance with the specified AMI ID, instance type, and security group ID already exists. If it does not exist, the script creates the EC2 instance. If it does exist, the script prints a message indicating that the instance already exists.

<br>

### Finally, the script prints the public IP address of the EC2 instance.

<br>

### Run this command in the terminal after replacing XXX with your keys.
---

`export AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=XXX AWS_DEFAULT_REGION=XXX; bash aws.sh`   

<br>

### Run this command to terminate the instance

`aws ec2 terminate-instances --instance-ids i-0c7a8fbcd9463a3eb`


<br>

# Amazon secret store, put this pem key in there

```
aws get-secret-value --secret-id secret_rsa_id
aws create-secret --name secret_rsa_id --secret-string ./aws_rsa_key_pair.pem --description "SSH for aws log in"
```

<br>

```
{
  key: "private key is stored in AWS secretsmanager",
  
  test: "aws secretsmanager get-secret-value --secret-id ${AWS_VM}",
  action: "aws secretsmanager create-secret --name ${AWS_VM} --secret-string file://${AWS_VM}.pem --description \"SSH private key for ${AWS_VM}\""
},
```