#!/bin/bash

# Define the YAML URL to keep the script DRY (Don't Repeat Yourself)
YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"

# 1. Identify current project
PROJECT=$(oc project -q)

# Logic for Cleanup
if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Starting Cleanup for project: $PROJECT"
    # Deletes all resources labeled with app=wmq
    oc delete all,pvc,secrets,configmaps,routes -l $APP_LABEL
    echo "✅ Cleanup complete."
    exit 0
fi

# Logic for Deployment
echo "🚀 Starting MQ Deployment in project: $PROJECT"

# 2. Grant permissions (Essential for IBM MQ)
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

# 3. Apply the entire stack from GitHub
oc apply -f $YAML_URL

# 4. Wait for the pod
echo "⏳ Waiting for IBM MQ to initialize..."
oc rollout status deployment/wmq --timeout=120s

# 5. Output the Console URL and Verify the Queue
echo "------------------------------------------------"
echo "Deployment Complete!"
# Note: Ensure the route name in your YAML is 'mq-web-console'
CONSOLE_URL=$(oc get route mq-web-console -o jsonpath='{.spec.host}' 2>/dev/null)
echo "MQ Console: https://$CONSOLE_URL"
echo "------------------------------------------------"

echo "✅ Verifying IN.QUEUE for group 'app':"
oc exec deployment/wmq -- runmqsc QMGR <<< "DISPLAY AUTHREC PROFILE('IN.QUEUE') GROUP('app')"
