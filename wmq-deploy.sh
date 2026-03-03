#!/bin/bash

YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"
PROJECT=$(oc project -q)

# Optional Cleanup
if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Cleaning up IBM MQ resources in $PROJECT..."
    oc delete all,pvc,secrets,configmaps,routes -l $APP_LABEL
    exit 0
fi

echo "🚀 Deploying Fully Configured IBM MQ Stack..."

# 1. Allow root-initContainer to run (required for volume chown)
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

# 2. Apply the manifest (ConfigMap contains the security bypass logic)
oc apply -f $YAML_URL

# 3. Wait for readiness (MQSC auto-config finishes before readiness is true)
echo "⏳ Waiting for Queue Manager 'QMGR' to initialize and apply MQSC..."
oc rollout status deployment/wmq --timeout=180s

echo "------------------------------------------------"
echo "✅ Deployment Complete!"
echo "Identity 'app' authorized via MQSC (OS password check: OPTIONAL)"
echo "Queue 'IN.QUEUE' created with ALL permissions"
echo "Channel 'ONEFINSURV.SVRCONN' configured"
echo "------------------------------------------------"

# Final sanity check: Verify the MQ identity permissions instead of OS id
echo "🔍 Verifying MQ Authority for 'app':"
oc exec deployment/wmq -c mq -- runmqsc QMGR <<< "DISPLAY AUTHREC PROFILE('IN.QUEUE') PRINCIPAL('app')"
