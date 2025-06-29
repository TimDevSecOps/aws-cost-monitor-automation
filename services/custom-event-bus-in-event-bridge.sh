#!/bin/bash
# Author: Tim Zhang

# Demo for event-bridge for product development:
# The case:
# 	1.	Create a custom Event Bus
# 	2.	Create a Lambda function (in Python)
# 	3.	Create an EventBridge Rule to route events to the Lambda function
# 	4.	Manually trigger an event using the CLI
# 	5.	View the log output in CloudWatch

iamRole=demo-role-for-eb
lambdaFunc=demoReceiveEBFunc
customEBName=demo-event-bus
customEBRule=demo-event-rule

# 1. Create IAM role, policy
echo "==== 1. Create role: ${iamRole}"
aws iam create-role \
  --role-name ${iamRole} \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": { "Service": "lambda.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }]
  }'

echo "Attach role to policy: ${iamRole} to AWSLambdaBasicExecutionRole"
aws iam attach-role-policy \
  --role-name ${iamRole} \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

roleARN=$(aws iam get-role --role-name ${iamRole} --query 'Role.Arn' --output text)
echo "Get role ARN: ${roleARN}"

# 2. Create lambda function.
echo "==== 2. Create lambda function: ${lambdaFunc}"
mkdir demo-lambda-eb
cd demo-lambda-eb
echo '
def lambda_handler(event, context):
    print("I got this event:", event)
' > lambda_function.py
zip function.zip lambda_function.py

echo "Upload lambda func to AWS"
aws lambda create-function \
  --function-name ${lambdaFunc} \
  --runtime python3.12 \
  --handler lambda_function.lambda_handler \
  --role ${roleARN} \
  --zip-file fileb://function.zip

funcARN=$(aws lambda get-function --function-name ${lambdaFunc} --query 'Configuration.FunctionArn' --output text)
echo "Get lambda func ARN: ${funcARN}"

# 3. Create custom event bus
echo "==== 3. Create custom event bus: ${customEBName}"
aws events create-event-bus --name ${customEBName}

echo "put rule for custom event bus: rule {customEBRule}"
aws events put-rule \
  --name ${customEBRule} \
  --event-bus-name ${customEBName} \
  --event-pattern '{"source": ["my.custom.source"]}'

ruleARN=$(aws events describe-rule --name ${customEBRule} --event-bus-name ${customEBName} --query 'Arn' --output text)
echo "Get rule ARN: ${ruleARN}"

echo "put lambda function target for custom event bus: target ${funcARN}"
aws events put-targets \
  --rule ${customEBRule} \
  --event-bus-name ${customEBName} \
  --targets "Id"="1","Arn"="${funcARN}"

echo "Add permission for lambda function"
aws lambda add-permission \
  --function-name ${lambdaFunc} \
  --statement-id EventBridgeInvokeLambda \
  --action lambda:InvokeFunction \
  --principal events.amazonaws.com \
  --source-arn ${ruleARN}

# 4. send a test event
echo "==== 4. send a test event"
aws events put-events --entries "[
  {
    \"Source\": \"my.custom.source\",
    \"DetailType\": \"TestEvent\",
    \"Detail\": \"{\\\"message\\\": \\\"Hello EventBridge!\\\"}\",
    \"EventBusName\": \"${customEBName}\"
  }
]"

# 5. check the cloudwatch log:
# login AWS Console:
#   --> CloudWatch -> Logs -> Log groups
#   --> Find name: /aws/lambda/${lambdaFunc}
#   --> click, and check the log stream
echo "==== 5. check cloudwatch log"
logStream=$(aws logs describe-log-streams \
  --log-group-name /aws/lambda/${lambdaFunc} \
  --order-by LastEventTime \
  --descending \
  --limit 1 \
  --query 'logStreams[0].logStreamName' \
  --output text)
echo "logStream name: ${logStream}"

aws logs get-log-events \
  --log-group-name /aws/lambda/${lambdaFunc} \
  --log-stream-name ${logStream}

# get this output in the log:
# {
#     "timestamp": 1751214589590,
#     "message": "I got this event: {'version': '0', 'id': 'b5eb3e39-d3da-89dc-fde9-11367c90c141', 'detail-type': 'TestEvent', 'source': 'my.custom.source', 'account': '684909421373', 'time': '2025-06-29T16:29:49Z', 'region': 'us-east-1', 'resources': [], 'detail': {'message': 'Hello EventBridge!'}}\n",
#     "ingestionTime": 1751214590799
# },
# success!!!