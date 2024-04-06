#### optimization

#### Amazon EKS managed node groups
- does all the automation for a lifecycle
- tags nodes with k8s.io/cluster-autoscaler/enabled=true and k8s.io/cluster-autoscaler/
- option for stop inctances -
    - tagged with eks.amazonaws.com/capacityType: SPOT
    - capacity-optimized

#### Spot Instance diversification
- ASG -  of instance types that provide approximately equal capacity
- use ec2-instance-selector utility

#### Spot Best Practices - applied out of the box:
- Capacity Optimized -- from the most-available spare capacity pools
- Capacity Rebalance -- proactively replacing instances that are at higher risk of being interrupted




#### AUTOSCALING

- Horizontal Pod Autoscaler (HPA)
    - scales the pods in a deployment or replica set
    - implemented as a K8s API resource and a controller
    - controller manager queries the resource utilization against the metrics I specified in each HorizontalPodAutoscaler definition
    - metrics -- resource, custom, multiple, metrics AP

    - `kubectl autoscale deployment monte-carlo-pi-service --cpu-percent=50 --min=3 --max=10`

- Cluster Autoscaler (CA)
    - pod scaling as well as scaling nodes in a cluster
    - default K8s component
    - automatically regulates the size of an Auto Scaling Group

    - expender type: random (default), lowest-waste, priority 

    - terraform e.g.: `module "eks_blueprints_addons" {enable_cluster_autoscaler = true}` 
    - logs with `kubectl logs -f deployment/cluster-autoscaler-aws-cluster-autoscaler -n kube-system --tail=10`
    
    - better alternative to CA -- Karpenter, k8s-spot-rescheduler, descheduler