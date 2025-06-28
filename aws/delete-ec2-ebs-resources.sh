#!/bin/bash
set -euo pipefail

echo "Cleaning up EC2 instance and EBS volume..."
aws ec2 terminate-instances --instance-ids i-012a095c7c19d4a76 --region us-east-1
aws ec2 wait instance-terminated --instance-ids i-012a095c7c19d4a76 --region us-east-1
echo "EC2 instance terminated: i-012a095c7c19d4a76"

aws ec2 delete-volume --volume-id vol-017c765a19c1ef40b --region us-east-1
echo "EBS volume deleted: vol-017c765a19c1ef40b"
