#!/bin/bash
set -euo pipefail

# global variables
budgetName="TimDailyCostBudget"
budgetLimit="0.2"  # USD
notifyEmail="timdevsecops@gmail.com"
awsAccountId=$(aws sts get-caller-identity --query "Account" --output text)
startDate=$(date -u +%Y-%m-%dT00:00:00Z)

echo "==== Creating budget: ${budgetName} for account: ${awsAccountId}"
aws budgets create-budget \
  --account-id "$awsAccountId" \
  --budget "{
    \"BudgetName\": \"$budgetName\",
    \"BudgetLimit\": {
      \"Amount\": \"$budgetLimit\",
      \"Unit\": \"USD\"
    },
    \"TimeUnit\": \"DAILY\",
    \"BudgetType\": \"COST\",
    \"TimePeriod\": {
      \"Start\": \"$startDate\"
    },
    \"CostTypes\": {
      \"IncludeCredit\": true,
      \"IncludeDiscount\": true,
      \"IncludeOtherSubscription\": true,
      \"IncludeRecurring\": true,
      \"IncludeRefund\": true,
      \"IncludeSubscription\": true,
      \"IncludeSupport\": true,
      \"IncludeTax\": true,
      \"IncludeUpfront\": true,
      \"UseAmortized\": false,
      \"UseBlended\": false
    }
  }"

echo "Done: Budget created."

echo "==== Create Notification."
aws budgets create-notification \
  --account-id "$awsAccountId" \
  --budget-name "$budgetName" \
  --notification '{
    "NotificationType": "ACTUAL",
    "ComparisonOperator": "GREATER_THAN",
    "Threshold": 72,
    "ThresholdType": "PERCENTAGE",
    "NotificationState": "ALARM"
  }' \
  --subscribers "[{\"SubscriptionType\": \"EMAIL\",\"Address\":\"$notifyEmail\"}]"

echo "Budget and notification successfully configured."
