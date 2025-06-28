#!/bin/bash
set -euo pipefail

echo "Cleaning up EC2 instance and EBS volume..."
aws ec2 terminate-instances --instance-ids i-040cd5a7ecda7392c --region us-east-1
aws ec2 wait instance-terminated --instance-ids i-040cd5a7ecda7392c --region us-east-1
echo "EC2 instance terminated: i-040cd5a7ecda7392c"

aws ec2 delete-volume --volume-id vol-02c15d79a0dee3f4d --region us-east-1
echo "EBS volume deleted: vol-02c15d79a0dee3f4d"
