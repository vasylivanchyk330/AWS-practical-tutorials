### LAUNCHING EC2 SPOT INSTANCES VIA EC2 FLEET

# In a single API call, a fleet can launch multiple instances

# 1. create the configuration file to launch the EC2 Fleet with ABIS
cat <<EoF > ./ec2-fleet-config.json
{
   "SpotOptions":{
      "SingleInstanceType": true,
      "SingleAvailabilityZone": true,
      "MinTargetCapacity": 4,
      "AllocationStrategy": "price-capacity-optimized",
      "InstanceInterruptionBehavior": "terminate"
   },
   "OnDemandOptions":{
      "AllocationStrategy": "lowest-price",
      "SingleInstanceType": true,
      "SingleAvailabilityZone": true,
      "MinTargetCapacity": 0
   },
   "LaunchTemplateConfigs":[
      {
         "LaunchTemplateSpecification":{
            "LaunchTemplateId":"${LAUNCH_TEMPLATE_ID}",
            "Version":"1"
         },
         "Overrides":[{
            "InstanceRequirements": {
               "VCpuCount": {
                  "Min": 2, 
                  "Max": 4
               },
               "MemoryMiB": {
                  "Min": 0
               },
               "CpuManufacturers": [
                  "intel"
               ]
            }
         }]
      }
   ],
   "TargetCapacitySpecification":{
      "TotalTargetCapacity": 4,
      "OnDemandTargetCapacity": 0,
      "DefaultTargetCapacityType": "spot"
   },
   "Type":"instant"
}
EoF

# for HPC, these 2 options are highly recommended 
    # "SingleInstanceType": true,   
    # "SingleAvailabilityZone": true,
# "Type":"instant" -- a synchronous one-time request for the desired capacity
# other types:
    # request -- asynchronous one-time request for your desired capacity
    # maintain -- asynchronous request for your desired capacity, and maintains capacity by automatically replenishing any interrupted Spot Instances
#


# 2. create the fleet and export fleet id
export FLEET_ID=$(aws ec2 create-fleet --cli-input-json file://ec2-fleet-config.json | jq -r '.FleetId')




### CHECKING

# check detailes
aws ec2 describe-fleets --fleet-ids "${FLEET_ID}"

# which instances have been launched using the Spot purchasing model and which ones using the On-Demand
aws ec2 describe-instances --filters Name=instance-lifecycle,Values=spot Name=tag:aws:ec2:fleet-id,Values=${FLEET_ID} Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].[InstanceId]" --output text


### ERROR HANDLING

# if the type is `instant`, there might be an error indicating that the minimum request for instances could not be met.
# the EC2 Fleet is not able to meet the target capacity of Spot or On-Demand instances
# DO: provide additional diversification or change the type to request or maintain