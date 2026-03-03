#!/bin/bash

YAML_URL="https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml"
APP_LABEL="app=wmq"
#!/bin/bash

PROJECT=$(oc project -q)

if [[ "$1" == "--cleanup" ]]; then
    echo "🧹 Cleaning up..."
    oc delete all,pvc,secrets,routes -l app=wmq
    exit 0
fi

echo "🚀 Deploying IBM MQ Stack..."
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

oc apply -f $YAML_URL

echo "⏳ Waiting for Queue Manager to be ready..."
oc rollout status deployment/wmq --timeout=180s

echo "🛠️ Configuring MQ Channels and Permissions..."
# Using ALLMQI to avoid Reason Code 2046
printf "DEFINE QLOCAL('IN.QUEUE') REPLACE\nDEFINE CHANNEL('ONEFINSURV.SVRCONN') CHLTYPE(SVRCONN) TRPTYPE(TCP) REPLACE\nSET CHLAUTH('ONEFINSURV.SVRCONN') TYPE(ADDRESSMAP) ADDRESS('*') USERSRC(MAP) MCAUSER('app') ACTION(REPLACE)\nSET AUTHREC PROFILE('IN.QUEUE') OBJTYPE(QUEUE) PRINCIPAL('app') AUTHADD(ALLMQI)\nSET AUTHREC PROFILE('QMGR') OBJTYPE(QMGR) PRINCIPAL('app') AUTHADD(ALLMQI)\nREFRESH SECURITY\nEND" | oc exec -i deployment/wmq -c mq -- runmqsc QMGR

echo "------------------------------------------------"
echo "✅ Deployment Complete!"
CONSOLE_URL=$(oc get route mq-web-console -o jsonpath='{.spec.host}')
echo "MQ Console: https://$CONSOLE_URL/ibmmq/console/"
echo "------------------------------------------------"
echo "🔍 Testing connectivity for user 'app'..."
echo "password" | oc exec -i deployment/wmq -c mq -- sh -c "export MQSERVER='ONEFINSURV.SVRCONN/TCP/localhost(1414)'; /opt/mqm/samp/bin/amqsputc IN.QUEUE QMGR -u app"
