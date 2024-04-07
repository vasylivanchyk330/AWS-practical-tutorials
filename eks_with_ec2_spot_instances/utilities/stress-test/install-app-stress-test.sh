#!/bin/bash

mkdir -p ~/environment/submit_mc_pi_k8s_requests/
curl -o ~/environment/submit_mc_pi_k8s_requests/submit_mc_pi_k8s_requests.py https://raw.githubusercontent.com/ruecarlo/eks-workshop-sample-api-service-go/master/stress_test_script/submit_mc_pi_k8s_requests.py
chmod +x ~/environment/submit_mc_pi_k8s_requests/submit_mc_pi_k8s_requests.py
curl -o ~/environment/submit_mc_pi_k8s_requests/requirements.txt https://raw.githubusercontent.com/ruecarlo/eks-workshop-sample-api-service-go/master/stress_test_script/requirements.txt
sudo python3 -m pip install -r ~/environment/submit_mc_pi_k8s_requests/requirements.txt

# run first stress test
URL=$(kubectl get svc monte-carlo-pi-service | tail -n 1 | awk '{ print $4 }')
~/environment/submit_mc_pi_k8s_requests/submit_mc_pi_k8s_requests.py -p 1 -r 1 -i 1 -u "http://${URL}"
