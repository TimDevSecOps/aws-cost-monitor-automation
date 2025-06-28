#!/bin/bash
# 0 9 * * * /Users/tzhang/cron/get-daily-cost.sh >> /Users/tzhang/cron/log/aws-daily-cost.log 2>&1

OS=$(uname)
if [[ "$OS" == "Darwin" ]]; then
  YESTERDAY=$(date -v-1d +%Y-%m-%d)
else
  YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
fi
TODAY=$(date +%Y-%m-%d)

echo "==== Checking cost for: $YESTERDAY"

echo "==== Cost and Usage ===="
aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics "UnblendedCost" \
  --output table

echo "==== Budget Summary ===="
aws budgets describe-budget \
  --account-id $(aws sts get-caller-identity --query "Account" --output text) \
  --budget-name "TimDailyCostBudget" \
  --query '{Limit: Budget.BudgetLimit, Name: Budget.BudgetName}' \
  --output table
