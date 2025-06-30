#!/bin/bash
# Author: Tim Zhang

# The goal:
# 1. Environment isolation: dev, test, and porod environments operate independently without interference
# 2. Role-based access control: seperated role for R&D, QA, and DevOps/SRE teams
# 3. Centralized governance: Unified management of security policies, billing controls, and logging etc.

# The example hierarchy will be created in Tim's demo organination.
# Root Account:
# ├── OU: org-sandbox
# │   └── account: acct-sandbox.labs # create IAM user: sandbox.labs
# ├── OU: org-env
# │   ├── account: acct-tim.devops  # create IAM user: tim.devops
# │   ├── OU: org-env-dev
# │   │   └── account: acct-dev-env.root # create IAM user: tim.dev, bob.dev etc.
# │   ├── OU: org-env-qa
# │   │   └── account: acct-qa-env.root  # create IAM user: tim.qa, bob.qa etc.
# │   └── OU: org-env-prod
# │       └── account: acct-prod-env.root  # create IAM user: tim.prod, bob.prod etc.
# ├── OU: org-monitor
# │    └── account: acct-monitor.ops  # logging & monitoring   # create IAM user: monitor.ops
# └── OU: org-sectool
#     └── account: acct-sectool.ops   # Security Tooling   # create IAM user: sectool.ops
