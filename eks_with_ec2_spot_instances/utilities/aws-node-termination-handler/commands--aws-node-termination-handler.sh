# here, there are some commands for installing aws-node-termination-handler on self-managed nodes
# after such installing, run stress test

# add repo and install aws-node-termination-handler limited to only self-managed node groups
helm repo add eks https://aws.github.io/eks-charts
helm install aws-node-termination-handler \
             --namespace kube-system \
             --version 0.21.0 \
             --set nodeSelector.type=self-managed-spot \
             eks/aws-node-termination-handler
#

# kubectl get daemonsets --all-namespaces
kubectl get daemonsets --all-namespaces


# run 4000 requests (as we have twice the capacity) each expected to take ~1.3sec
time ~/environment/submit_mc_pi_k8s_requests/submit_mc_pi_k8s_requests.py -p 100 -r 40 -i 30000000 -u "http://${URL}"

# get nodes, with label-columns
kubectl get nodes --label-columns=alpha.eksctl.io/nodegroup-name,eks.amazonaws.com/capacityType,type