#!/bin/bash

YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"

PROJECT=$(oc project -q)

echo "🚀 Deploying Fully Configured IBM MQ Stack..."

# 1. Allow root-initContainer to run
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

# 2. Apply everything
oc apply -f $YAML_URL

# 3. Wait for readiness (MQSC auto-config finishes before readiness is true)
oc rollout status deployment/wmq --timeout=180s

echo "------------------------------------------------"
echo "✅ Deployment Complete!"
echo "User 'app' created with password 'password'"
echo "Queue 'IN.QUEUE' created with ALL permissions"
echo "Channel 'ONEFINSURV.SVRCONN' configured"
echo "------------------------------------------------"

# Final sanity check inside the pod
echo "🔍 Verifying OS User:"
oc exec deployment/wmq -c mq -- id app
