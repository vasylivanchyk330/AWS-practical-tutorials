#!/bin/bash

mkdir $HOME/environment/kube-ops-view

for file in kustomization.yaml rbac.yaml deployment.yaml service.yaml; do mkdir -p $HOME/environment/kube-ops-view/; curl "https://raw.githubusercontent.com/awslabs/ec2-spot-workshops/master/content/using_ec2_spot_instances_with_eks/030_k8s_tools/k8_tools.files/kube_ops_view/${file}" > $HOME/environment/kube-ops-view/${file}; done

kubectl apply -k $HOME/environment/kube-ops-view

# get the details
kubectl get svc kube-ops-view | tail -n 1 
# Opening the URL in the browser will provide the current state of our cluster