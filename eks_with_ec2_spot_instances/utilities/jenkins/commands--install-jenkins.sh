
# add the repo
helm repo add jenkins https://charts.jenkins.io

# search repo to see the charts
helm search repo jenkins


# create helm values for jenkins
# nodeSelectors:
#   On-Demand nodes -- intent: control-apps, eks.amazonaws.com/capacityType: ON_DEMAND
#   Spot nodes      -- intent: jenkins-agents, eks.amazonaws.com/capacityType: SPOT
cat << EOF > values.yaml
---
controller:
  componentName: "jenkins-controller"
  image: "jenkins/jenkins"
  tag: "2.303.2-lts-jdk11"
  resources:
    requests:
      cpu: "1024m"
      memory: "4Gi"
    limits:
      cpu: "4096m"
      memory: "8Gi"

  servicePort: 80
  serviceType: LoadBalancer

  nodeSelector:
    intent: control-apps
    eks.amazonaws.com/capacityType: ON_DEMAND

serviceAccountAgent:
  create: false

agent:
  enabled: true
  image: "jenkins/inbound-agent"
  tag: "4.11-1"
  workingDir: "/home/jenkins/agent"
  componentName: "jenkins-agent"
  resources:
    requests:
      cpu: "512m"
      memory: "512Mi"
    limits:
      cpu: "1024m"
      memory: "1Gi"

  nodeSelector:
    intent: jenkins-agents
    eks.amazonaws.com/capacityType: SPOT
  connectTimeout: 300
  # Pod name
  podName: "jenkins-agent"
EOF

# create the Jenkins server
helm install cicd jenkins/jenkins -f values.yaml
# this will bring pod(s) for Jenkins

# watch for Jenkins Controller pod to boot
kubectl get pods -w


# Once the pod status changes to running, 
# get the load balancer address which will allow us to login to the Jenkins dashboard
export SERVICE_IP=$(kubectl get svc --namespace default cicd-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo "Jenkins running at : http://$SERVICE_IP/login"
# examples output: http://a47cfc8b6f49411e9bb3c0a177920747-1075946478.eu-west-1.elb.amazonaws.com/login


# when logging in, use "admin" as username, and the output of the following command as the password
printf $(kubectl get secret --namespace default cicd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

# get Jenkins logs from lvl of pod
kubectl logs -f <pod name from last step> -c jenkins