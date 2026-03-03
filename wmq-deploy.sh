#!/bin/bash

# Define the YAML URL to keep the script DRY (Don't Repeat Yourself)
YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"

PROJECT=$(oc project -q)

if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Cleaning up..."
    oc delete all,pvc,secrets,configmaps,routes -l app=wmq
    exit 0
fi

echo "🚀 Deploying IBM MQ..."
# Set permissions so InitContainer can fix volume ownership
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

oc apply -f $YAML_URL

echo "⏳ Waiting for Container Rollout..."
oc rollout status deployment/wmq --timeout=120s

# CRITICAL: Wait for MQSC to finish processing before running verification
echo "⏳ Waiting for Queue Manager to finish auto-configuration..."
sleep 15 

# Check if MQ is actually running
if oc exec deployment/wmq -- dspmq | grep -q 'STATUS(Running)'; then
    echo "✅ QMGR is Running."
    echo "------------------------------------------------"
    echo "MQ Console: https://$(oc get route mq-web-console -o jsonpath='{.spec.host}')"
    echo "------------------------------------------------"
    echo "🔍 Verifying IN.QUEUE:"
    oc exec deployment/wmq -- runmqsc QMGR <<< "DISPLAY QLOCAL(IN.QUEUE)"
else
    echo "❌ QMGR failed to start. Checking MQSC logs..."
    oc logs deployment/wmq | grep "AMQ5776E"
    exit 1
fi
