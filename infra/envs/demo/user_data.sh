#!/bin/bash
set +x
echo "STARTING SCRIPT BUILD..."
#sudo yum update -y 
aws s3 cp s3://goliiive-general-share/authorized_keys/dev/authorized_keys /home/ec2-user/.ssh/ 

# sudo yum install mariadb jq -y      # for RHEL/CentOS


# export AWS_DEFAULT_REGION="us-east-1"

# json="$(aws secretsmanager get-secret-value --secret-id rds\!cluster-476b8c2b-238e-43ac-9c5d-849b681372e0)"
# # Extract the SecretString, then parse it to get username and password
# username=$(echo "$json" | jq -r '.SecretString | fromjson | .username')
# password=$(echo "$json" | jq -r '.SecretString | fromjson | .password')

# #GRANT ALL PRIVILEGES ON `goliiive_sandbox`.*  TO 'goliiive_sandbox'@'%';
#  #aws s3 cp  s3://goliiive-general-share/db-migrations/sandbox/goliiive_sandbox.sql.gz .
#  gunzip <   goliiive_sandbox.sql.gz   | mysql -h  rds-goliiive-aurora-sandbox.cluster-c3i6lk7nwzwu.us-east-1.rds.amazonaws.com -u $username -p$password goliiive_sandbox


