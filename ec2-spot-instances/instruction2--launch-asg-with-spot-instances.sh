# LAUNCHING EC2 SPOT INSTANCES VIA EC2 AUTO SCALING GROUP

# 1. Attribute-based instance type selection - ABIS - create asg policy file (which later during the creation of asg will be used as `--mixed-instances-policy` file)
cat <<EoF > ./asg-policy.json
{
   "LaunchTemplate":{
      "LaunchTemplateSpecification":{
         "LaunchTemplateId":"${LAUNCH_TEMPLATE_ID}",
         "Version":"1"
      },
      "Overrides":[{
         "InstanceRequirements": {
            "VCpuCount": {
               "Min": 2, 
               "Max": 2
            },
            "MemoryMiB": {
               "Min": 0
            },
            "CpuManufacturers": [
               "intel",
               "amd"
            ],
            "InstanceGenerations": [
               "current"
            ],
            "AcceleratorCount": {
               "Max": 0
            }
         }
      }]
   },
   "InstancesDistribution":{
      "OnDemandBaseCapacity":1,
      "OnDemandPercentageAboveBaseCapacity":25,
      "SpotAllocationStrategy":"price-capacity-optimized"
   }
}
EoF

# 1 OnDemand instance = 25%
# meaning for every 1 OnDemand (25%), there will be 3 spot instances (100-25=75%) 

# "SpotAllocationStrategy":"price-capacity-optimized" allocates instances from the Spot Instance pools that offer low prices and high capacity availability. It's the most universal allocation approach -- moderatevely expensive, ~3% of Spot interruptions rate
# other approaches:  
    # capacity-optimized -- most expensive, ~2% of Spot interruptions rate
    # lowest-price -- lest expensive, ~20% of Spot interruptions rate
#


# 2. retrieve the default VPC and then its subnets
export VPC_ID=$(aws ec2 describe-vpcs --filters Name=isDefault,Values=true | jq -r '.Vpcs[0].VpcId')
export SUBNETS=$(aws ec2 describe-subnets --filters Name=vpc-id,Values="${VPC_ID}")
export SUBNET_1=$((echo $SUBNETS) | jq -r '.Subnets[0].SubnetId')
export SUBNET_2=$((echo $SUBNETS) | jq -r '.Subnets[1].SubnetId')

# 3. create-auto-scaling-group
aws autoscaling create-auto-scaling-group --auto-scaling-group-name EC2SpotWorkshopASG --min-size 2 --max-size 20 --desired-capacity 10 --desired-capacity-type vcpu --vpc-zone-identifier "${SUBNET_1},${SUBNET_2}" --capacity-rebalance --mixed-instances-policy file://asg-policy.json



## CHECKING 

# which instances have been created within the Auto Scaling group
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names EC2SpotWorkshopASG

# which instances have been launched using the Spot purchasing model a
aws ec2 describe-instances --filters Name=instance-lifecycle,Values=spot Name=tag:aws:autoscaling:groupName,Values=EC2SpotWorkshopASG Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].[InstanceId]" --output text
# ... and which ones using the On-Demand
aws ec2 describe-instances --filters Name=tag:aws:autoscaling:groupName,Values=EC2SpotWorkshopASG Name=instance-state-name,Values=running --query "Reservations[*].Instances[? InstanceLifecycle==null].[InstanceId]" --output text







## ALTERNATIVE asg-policy.json FILE CONFIGURATIONS

# 1. select specific instance types manually instead of ABIS in your Auto Scaling group
cat <<EoF > ./asg-policy.json
{
   "LaunchTemplate":{
      "LaunchTemplateSpecification":{
         "LaunchTemplateId":"${LAUNCH_TEMPLATE_ID}",
         "Version":"1"
      },
      "Overrides":[
         {
            "InstanceType":"m5.large"
         },
         {
            "InstanceType":"c5.large"
         },
         {
            "InstanceType":"r5.large"
         },
         {
            "InstanceType":"m4.large"
         },
         {
            "InstanceType":"c4.large"
         },
         {
            "InstanceType":"r4.large"
         }
      ]
   },
   "InstancesDistribution":{
      "OnDemandBaseCapacity":1,
      "OnDemandPercentageAboveBaseCapacity":25,
      "SpotAllocationStrategy":"price-capacity-optimized"
   }
}
EoF


# 2. ABIS but select a mix of instance types of different sizes
cat <<EoF > ./asg-policy.json
{ 
    ....
      "Overrides":[{
         "InstanceRequirements": {
            "VCpuCount": {
               "Min": 2, 
               "Max": 4
            ...
      }]
   },
    ...
}
EoF
