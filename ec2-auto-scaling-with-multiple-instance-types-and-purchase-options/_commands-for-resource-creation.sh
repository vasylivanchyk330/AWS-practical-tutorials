

####################################################
# 1. printout CF template output 

# export the name of the stack defined in the file ./ec2-auto-scaling-with-multiple-instance-types-and-purchase-options.yaml
export stack_name=myEC2Workshop

# print out the output
for output in $(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[].OutputKey' --output text)
do
	export $output=$(aws cloudformation describe-stacks --stack-name $stack_name --query 'Stacks[].Outputs[?OutputKey==`'$output'`].OutputValue' --output text)
	eval "echo $output : \"\$$output\""
done

# the output will be 
    # awsRegionId : eu-west-1
    # instanceProfile : arn:aws:iam::012345678910:instance-profile/running-workloads-at-scale-instanceProfile-1AWCE0JMHIRI4
    # vpc : vpc-0f0a34a6f7f3f999f
    # instanceSecurityGroup : sg-0ce120b3dde73b545
    # publicSubnet2 : subnet-0278bf57661c1f82b
    # publicSubnet1 : subnet-0f7bec73da5be90c2
    # cloud9Environment : cloud9Environment-C8KgzeALZ6w0
    # loadBalancerSecurityGroup : sg-0b6df7c3ed7c9118d
#


####################################################
# 2. CREATE AN EC2 LAUNCH TEMPLATE 

# ./launch-template-data.json - a template with placeholders
# to substitute placeholders with the actual values, use this commands:

# export the latest Amazon Linux 2 AMI
export ami_id=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-kernel*gp2" "Name=virtualization-type,Values=hvm" "Name=root-device-type,Values=ebs" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

# make a substitution of the placeholders
sed -i.bak -e "s#%instanceProfile%#$instanceProfile#g" -e "s/%instanceSecurityGroup%/$instanceSecurityGroup/g" -e "s#%ami-id%#$ami_id#g" -e "s#%UserData%#$(cat user-data.txt | base64 --wrap=0)#g" launch-template-data.json

# create
aws ec2 create-launch-template --launch-template-name myEC2Workshop --launch-template-data file://launch-template-data.json

# check
aws ec2 describe-launch-template-versions --launch-template-name myEC2Workshop
aws ec2 describe-launch-template-versions  --launch-template-name myEC2Workshop --output json | jq -r '.LaunchTemplateVersions[].LaunchTemplateData.UserData' | base64 --decode



####################################################
# 3. DEPLOY THE AWS ELASTIC LOAD BALANCER

# these files are files to be used for ELB creation:
    # ./application-load-balancer.json 
    # ./target-group.json
    # ./modify-target-group.json
    # ./listener.json
# they also contained placeholders

# to create ELB:


# A. LB

# make a substitution of the placeholders
sed -i.bak -e "s#%publicSubnet1%#$publicSubnet1#g" -e "s#%publicSubnet2%#$publicSubnet2#g" -e "s#%loadBalancerSecurityGroup%#$loadBalancerSecurityGroup#g" application-load-balancer.json

# create
aws elbv2 create-load-balancer --cli-input-json file://application-load-balancer.json

# export LoadBalancerArn for later use
export LoadBalancerArn=$(aws elbv2 describe-load-balancers --name myEC2Workshop --query LoadBalancers[].LoadBalancerArn --output text)



# B. Target Group

# make a substitution of the placeholder  
sed -i.bak -e "s#%vpc%#$vpc#g" target-group.json

# create target group
aws elbv2 create-target-group --cli-input-json file://target-group.json

# export TargetGroupArn for later use
export TargetGroupArn=$(aws elbv2 describe-target-groups --names myEC2Workshop --query TargetGroups[].TargetGroupArn --output text)



# C. apply additional configuration to th Target Group

# make a substitution of the placeholder
sed -i.bak -e "s#%TargetGroupArn%#$TargetGroupArn#g" modify-target-group.json
# create
aws elbv2 modify-target-group-attributes --cli-input-json file://modify-target-group.json


# D. Listener

# make a substitution of the placeholder
sed -i.bak -e "s#%LoadBalancerArn%#$LoadBalancerArn#g" -e "s#%TargetGroupArn%#$TargetGroupArn#g" listener.json
# create
aws elbv2 create-listener --cli-input-json file://listener.json



####################################################
# 4. CREATE AN EC2 AUTO SCALING GROUP

# make a substitution of placeholders
sed -i.bak -e "s#%TargetGroupARN%#$TargetGroupArn#g" -e "s#%publicSubnet1%#$publicSubnet1#g" -e "s#%publicSubnet2%#$publicSubnet2#g" asg.json

# apply
aws autoscaling create-auto-scaling-group --cli-input-json file://asg.json

# checks
# before applying, you can preview all the instance types selected by these requirements
aws ec2 get-instance-types-from-instance-requirements \
    --cli-input-yaml file://asg.json \
    --output table
#


####################################################
# 5. BROWSE TO THE WEB APP
# Open your web browser and browse to the DNS name (URL)



####################################################
# 6. USING DYNAMIC SCALING IN ASG

# apply
aws autoscaling put-scaling-policy --cli-input-json file://asg-automatic-scaling.json



####################################################
# 7. STRESS THE APP WITH AWS SYSTEMS MANAGER
# (with stress-ng utility)

# apply 
aws ssm send-command --cli-input-json file://ssm-stress.json