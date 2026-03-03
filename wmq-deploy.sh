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

# 4. Wait for the pod to be technically running
echo "⏳ Waiting for MQ Pod to be scheduled..."
oc rollout status deployment/wmq --timeout=120s

# 5. Wait for the Queue Manager process to actually start
echo "⏳ Waiting for Queue Manager 'QMGR' to reach RUNNING state..."
MAX_RETRIES=30
COUNT=0
while ! oc exec deployment/wmq -- dspmq | grep -q 'STATUS(Running)'; do
    if [ $COUNT -eq $MAX_RETRIES ]; then
        echo "❌ Timeout waiting for QMGR to start."
        exit 1
    fi
    echo -n "."
    sleep 2
    ((COUNT++))
done
echo -e "\n✅ QMGR is officially Running!"

# 6. Output the Console URL and Verify the Queue
echo "------------------------------------------------"
echo "Deployment Complete!"
CONSOLE_URL=$(oc get route mq-web-console -o jsonpath='{.spec.host}')
echo "MQ Console: https://$CONSOLE_URL"
echo "------------------------------------------------"

echo "✅ Verifying IN.QUEUE for group 'app':"
oc exec deployment/wmq -- runmqsc QMGR <<< "DISPLAY AUTHREC PROFILE('IN.QUEUE') GROUP('app')"
