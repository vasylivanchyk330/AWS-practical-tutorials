#!/bin/bash

URL=$(kubectl get svc monte-carlo-pi-service | tail -n 1 | awk '{ print $4 }')
# run 2000 requests and check running time
time ~/environment/submit_mc_pi_k8s_requests/submit_mc_pi_k8s_requests.py -p 100 -r 20 -i 30000000 -u "http://${URL}"

# result: ~1.3sec
