# 1. Identify current project
PROJECT=$(oc project -q)

# 2. Grant permissions to run as the IBM MQ user (Essential for OpenShift)
oc adm policy add-scc-to-user anyuid -z default -n $PROJECT

# 3. Apply the entire stack
oc apply -f https://raw.githubusercontent.com/aboucham/wmq-on-openshift/refs/heads/main/mq-full-setup.yaml

# 4. Wait for the pod to be ready (approx 30-60 seconds)
echo "Waiting for IBM MQ to initialize..."
oc rollout status deployment/wmq --timeout=120s

# 5. Output the Console URL and Verify the Queue
echo "------------------------------------------------"
echo "Deployment Complete!"
echo "MQ Console: $(oc get route mq-console -o jsonpath='{"https://"}{.spec.host}')"
echo "------------------------------------------------"
echo "Verifying IN.QUEUE for group 'app':"
oc exec deployment/wmq -- runmqsc QMGR <<< "DISPLAY AUTHREC PROFILE('IN.QUEUE') GROUP('app')"
