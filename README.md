## These scripts, specifically for Mac OS users, provide automation to deploy and destroy infrastructure within the Amazon Web Services platform using the AWS CLI.

<br>

# Deploy

1. The script first ensures that necessary utilities, such as brew and the AWS command line interface, are installed on the system.

2. It then proceeds to verify the presence of an RSA key pair, creating one if necessary and securely storing it locally as aws_rsa_key_pair.pem.

3. It subsequently checks for the existence of a specified security group, creating one and configuring ingress rules if it does not exist.

4. The script then checks for the presence of an EC2 instance matching specified parameters, such as AMI ID, instance type, and security group ID, creating one if necessary and informing the user if it already exists.

5. Finally, the script waits for the instance to become active before providing SSH access to it.

<br>

### Run this command in the terminal replacing XXX with your AWS access keys.
 
<br>

`export AWS_ACCESS_KEY_ID=XXX AWS_SECRET_ACCESS_KEY=XXX AWS_DEFAULT_REGION=XXX; bash aws_deploy.sh`   

<br>

# Destroy 

### This script is used to remove any trace of an AWS EC2 instance deployment from your local machine. It performs the following actions:

1. Deletes the IP fingerprints of the AWS instances from the known_hosts file, which is used to store information about SSH connections.
2. Terminates the EC2 instances that were created as part of the deployment.
3. Deletes the AWS key pairs and RSA key pairs used to connect to the instances.
4. Removes any security groups that were created during the deployment.
5. This script ensures that all resources created during the deployment are cleaned up, and that any information about the instances is removed from your local machine.

<br>

To destroy, run the following command: 
<br>

`bash destroy_aws.sh`