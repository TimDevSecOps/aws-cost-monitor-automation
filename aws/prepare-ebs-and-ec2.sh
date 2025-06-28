#!/bin/bash
set -euo pipefail

# define global variables
tagPrefix=tim-labs
ownerTag="{Key=Owner,Value=tim}"

region="us-east-1"
amiID="ami-0c2b8ca1dad447f8a"  # Amazon Linux 2 AMI for us-east-1
instanceType="t2.micro"
ebsSize=1  # GiB
deviceName="/dev/sdk"

echo "==== 1. Start to create EC2 instance..."
instanceId=$(aws ec2 run-instances \
  --region $region \
  --image-id $amiID \
  --instance-type $instanceType \
  --query "Instances[0].InstanceId" \
  --output text \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=${tagPrefix}-ec2},${ownerTag}]")

echo "OUTPUT: Instance created: $instanceId"

echo "=== 2. Waiting for instance to enter 'running' state..."
aws ec2 wait instance-running --instance-ids "$instanceId" --region $region

az=$(aws ec2 describe-instances \
  --instance-ids "$instanceId" \
  --region $region \
  --query "Reservations[0].Instances[0].Placement.AvailabilityZone" \
  --output text)

echo "OUTPUT: Availability Zone: $az"

echo "==== 3. Creating EBS volume..."
ebsVolumeId=$(aws ec2 create-volume \
  --size $ebsSize \
  --availability-zone $az \
  --volume-type gp2 \
  --region $region \
  --query "VolumeId" \
  --output text \
  --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=${tagPrefix}-1gb-vol},${ownerTag}]")

echo "OUTPUT: EBS volume created: $ebsVolumeId"

echo "==== 4. Waiting for volume to become available"
aws ec2 wait volume-available --volume-ids "$ebsVolumeId" --region $region

echo "==== 5. Attaching EBS volume to EC2"
aws ec2 attach-volume \
  --volume-id "$ebsVolumeId" \
  --instance-id "$instanceId" \
  --device "$deviceName" \
  --region $region

echo "==== 6. Waiting for attachment to complete."
aws ec2 wait volume-in-use --volume-ids "$ebsVolumeId" --region $region

echo "==== 7. Stopping EC2 instance."
aws ec2 stop-instances --instance-ids "$instanceId" --region $region

echo "==== 8. Waiting for EC2 to stop."
aws ec2 wait instance-stopped --instance-ids "$instanceId" --region $region

echo "OUPTUT:"
echo "All steps completed."
echo "Instance ID: $instanceId"
echo "Volume ID: $ebsVolumeId"

echo "==== 9. Generating cleanup script: delete-ec2-ebs-resources.sh"
cat <<EOF > delete-ec2-ebs-resources.sh
#!/bin/bash
set -euo pipefail

echo "Cleaning up EC2 instance and EBS volume..."
aws ec2 terminate-instances --instance-ids $instanceId --region $region
aws ec2 wait instance-terminated --instance-ids $instanceId --region $region
echo "EC2 instance terminated: $instanceId"

aws ec2 delete-volume --volume-id $ebsVolumeId --region $region
echo "EBS volume deleted: $ebsVolumeId"
EOF

chmod +x delete-ec2-ebs-resources.sh
echo "Cleanup script generated: delete-ec2-ebs-resources.sh"
