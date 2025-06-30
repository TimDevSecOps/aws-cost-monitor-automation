#!/bin/bash
# Author: Tim Zhang
# Flow:
# [SNS Topic] ──(subscribe)──▶ [Lambda Function]
#    ▲                           │
#    │                           └── Trigger code to run (pass SNS message)
#    └── publish message

set -euo pipefail

# === CONFIGURATION ===
REGION="us-east-1"
TOPIC_NAME="my-sns-topic"
LAMBDA_NAME="my-sns-handler"
LAMBDA_RUNTIME="python3.12"
ROLE_NAME="sns-lambda-execution-role"
ZIP_FILE="lambda.zip"
HANDLER="lambda_function.lambda_handler"  # filename.function_name

echo "Step 1: Create SNS Topic."
TOPIC_ARN=$(aws sns create-topic \
  --name "$TOPIC_NAME" \
  --region "$REGION" \
  --query 'TopicArn' --output text)

echo "SNS Topic created: $TOPIC_ARN"

# === Create IAM Role for Lambda ===
echo "Step 2: Create IAM Role for Lambda execution."

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST_POLICY" \
  --region "$REGION" >/dev/null

echo "Attaching basic execution policy to role."
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
  --region "$REGION"

# Wait a bit for IAM propagation
echo "Waiting for IAM role to become usable."
sleep 10

ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query 'Role.Arn' --output text)
echo "IAM Role ARN: $ROLE_ARN"

# === Create Lambda function ===
echo "Step 3: Create Lambda function..."

echo "Generating simple Python Lambda handler..."
cat > lambda_function.py <<EOF
def lambda_handler(event, context):
    print("=== SNS Event ===")
    print(event)
    return {
        'statusCode': 200,
        'body': 'SNS message processed.'
    }
EOF

echo "Zipping Lambda function to $ZIP_FILE..."
zip -q "$ZIP_FILE" lambda_function.py

aws lambda create-function \
  --function-name "$LAMBDA_NAME" \
  --runtime "$LAMBDA_RUNTIME" \
  --handler "$HANDLER" \
  --role "$ROLE_ARN" \
  --zip-file "fileb://$ZIP_FILE" \
  --region "$REGION"

echo "Lambda function created: $LAMBDA_NAME"

# === Add permission to allow SNS to invoke Lambda ===
echo "Step 4: Add invoke permission for SNS -> Lambda."

aws lambda add-permission \
  --function-name "$LAMBDA_NAME" \
  --statement-id sns-invoke-permission \
  --action "lambda:InvokeFunction" \
  --principal sns.amazonaws.com \
  --source-arn "$TOPIC_ARN" \
  --region "$REGION"

# === Subscribe Lambda to SNS ===
echo "Step 5: Subscribe Lambda to SNS Topic."

accountId=$(aws sts get-caller-identity --query Account --output text)
echo "account ID: ${accountId}"

aws sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol lambda \
  --notification-endpoint "arn:aws:lambda:$REGION:${accountId}:function:$LAMBDA_NAME" \
  --region "$REGION"

# === Publish a test message ===
echo "Step 6: Publish a test message to SNS Topic."

aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message "Hello from SNS to Lambda!" \
  --region "$REGION"

echo "Done. Check CloudWatch Logs for Lambda execution output."

echo "Step 7: Fetching latest CloudWatch Logs for Lambda function..."

LOG_GROUP="/aws/lambda/$LAMBDA_NAME"

# Get the latest log stream (based on lastEventTime descending)
LATEST_LOG_STREAM=$(aws logs describe-log-streams \
  --log-group-name "$LOG_GROUP" \
  --order-by "LastEventTime" \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text \
  --region "$REGION")

echo "Latest Log Stream: $LATEST_LOG_STREAM"

# Retrieve and print logs
echo "===== Lambda Execution Logs ====="
aws logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LATEST_LOG_STREAM" \
  --region "$REGION" \
  --limit 50 \
  --query 'events[*].message' \
  --output text

echo "Logs fetched. If the Lambda was triggered, you should see SNS event details above."

# OUTPUT: success
# START RequestId: c908a261-3e02-4889-8162-74afe18c42cc Version: $LATEST
# === SNS Event ===