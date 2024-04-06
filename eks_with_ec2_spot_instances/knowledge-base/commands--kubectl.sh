

# how to get kube-ops-view url
kubectl get svc kube-ops-view | tail -n 1 | awk '{ print "Kube-ops-view URL = http://"$4 }'


# get SPOT nodes 
kubectl get nodes \
  --label-columns=eks.amazonaws.com/capacityType \
  --selector=eks.amazonaws.com/capacityType=SPOT

# get ON_DEMEND nodes
kubectl get nodes \
  --label-columns=eks.amazonaws.com/capacityType \
  --selector=eks.amazonaws.com/capacityType=SPOT

# find out the external url
svc_name="<svc_name>"
kubectl get svc $svc_name | tail -n 1 | awk '{ print "URL = http://"$4 }'  

# cluster autoscaler logs
kubectl logs -f deployment/cluster-autoscaler-aws-cluster-autoscaler -n kube-system --tail=10

# CA - which type of node has been added
kubectl get node --selector=key=value --show-labels

# setting simple HPA 
kubectl autoscale deployment monte-carlo-pi-service --cpu-percent=50 --min=3 --max=100
kubectl get hpa -w


