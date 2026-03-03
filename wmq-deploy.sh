#!/bin/bash

# Define the YAML URL to keep the script DRY (Don't Repeat Yourself)
YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"

PROJECT=$(oc project -q)

if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Cleaning up project: $PROJECT"
    oc delete all,pvc,secrets,routes -l app=wmq
    exit 0
fi

echo "🚀 Deploying IBM MQ Stack..."

# 1. Grant SCC permissions for UID 1001 and InitContainer chown
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

# 2. Apply YAML from GitHub
oc apply -f $YAML_URL

# 3. Wait for Readiness Probe to pass
echo "⏳ Waiting for MQ Container and Queue Manager to initialize..."
oc rollout status deployment/wmq --timeout=150s

# 4. Success Output
echo "------------------------------------------------"
echo "✅ Deployment Successful!"
CONSOLE_URL=$(oc get route mq-web-console -o jsonpath='{.spec.host}')
echo "MQ Console: https://$CONSOLE_URL"
echo "------------------------------------------------"
echo "The Queue Manager is now running. You can create your queues"
echo "via the Web Console or by running:"
echo "oc exec deployment/wmq -- runmqsc QMGR"
