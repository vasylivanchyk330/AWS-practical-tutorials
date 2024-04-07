

expender types: random (default), lowest-waste, priority 



#### change the expender type to `priority` / `lowest-waste`

1. 
`kubectl edit deployment cluster-autoscaler -n kube-system`

2. 
```
command:
  - ./cluster-autoscaler
  - --v=4
  - --stderrthreshold=info
  - --cloud-provider=[YourCloudProvider]  # This should already be set
  - --skip-nodes-with-local-storage=false
  - --expander=<priority|lowest-waste> # this line
```

3. for `priority`
```
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-priority-expander
  namespace: kube-system
data:
  priorities: |
    10:
      - .*large.*
    20:
      - .*small.*
```

4. 
`kubectl apply -f priority-expander-configmap.yaml`

5. 
`kubectl delete pod -l app=cluster-autoscaler -n kube-system`

