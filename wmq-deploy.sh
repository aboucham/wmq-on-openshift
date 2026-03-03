#!/bin/bash

YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
PROJECT=$(oc project -q)

if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Cleaning up..."
    oc delete all,pvc,secrets,configmaps,routes -l app=wmq
    exit 0
fi

echo "🚀 Deploying Fully Configured IBM MQ Stack..."
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT
oc apply -f $YAML_URL

echo "⏳ Waiting for Queue Manager 'QMGR' to be ready..."
oc rollout status deployment/wmq --timeout=180s

echo "------------------------------------------------"
echo "✅ Deployment Complete!"
echo "Identity 'app' authorized via MQSC (ADOPTCTX enabled)"
echo "Exactly-Once State Queue: QMGR.STATE.QUEUE"
echo "Channel: ONEFINSURV.SVRCONN (HBINT 30s)"
echo "------------------------------------------------"

# Verify the Auth Records exist
echo "🔍 Verifying MQ Authority for 'app':"
oc exec deployment/wmq -c mq -- runmqsc QMGR <<< "DISPLAY AUTHREC PROFILE('IN.QUEUE') PRINCIPAL('app')"
