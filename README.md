To Deploy:

```
oc new-project wmq
oc project wmq
curl -sSL https://raw.githubusercontent.com/aboucham/wmq-on-openshift/main/wmq-deploy.sh | bash
```

To Cleanup:

```
curl -sSL https://raw.githubusercontent.com/aboucham/wmq-on-openshift/main/wmq-deploy.sh | bash -s -- --cleanup
```
