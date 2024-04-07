# SPOT PLACEMENT SCORE (SPS)

# The Spot placement score gives the Region(s) or Availability Zone(s) a score of 1 to 10 indicating how likely a Spot request will succeed
# 10 - most likely but not garanteed
# 1 - not likely at all

# 1. via console
#  https://console.aws.amazon.com/ec2/ ->  Spot Requests ->  Spot placement score

# 2. with cli
cat <<EoF > ./sps-input.json
{
    "InstanceRequirementsWithMetadata": {
        "ArchitectureTypes": [
            "x86_64"
        ],
        "InstanceRequirements": {
            "VCpuCount": {
                "Min": 4,
                "Max": 8
            },
            "MemoryMiB": {
                "Min": 16384
            }
        }
    },
    "TargetCapacity": 100,
    "TargetCapacityUnitType": "vcpu",
    "SingleAvailabilityZone": false
}
EoF

aws ec2 get-spot-placement-scores --cli-input-json file://./sps-input.json


### OTHER
# filter out regions
cat <<EoF > ./sps-input.json
{
    "InstanceRequirementsWithMetadata": {
        "ArchitectureTypes": [
            "x86_64"
        ],
        "InstanceRequirements": {
            "VCpuCount": {
                "Min": 4,
                "Max": 8
            },
            "MemoryMiB": {
                "Min": 16384
            }
        }
    },
    "TargetCapacity": 100,
    "TargetCapacityUnitType": "vcpu",
    "SingleAvailabilityZone": false,
    "RegionNames": [
        "us-east-1",
        "us-east-2",
        "us-west-1",
        "us-west-2"
    ]
}
EoF

# including different instance types in the Spot placement score request
cat <<EoF > ./sps-input.json
{
    "InstanceTypes": [
        "m6i.xlarge",
        "m6i.2xlarge",
        "m6a.xlarge",
        "m6a.2xlarge",
        "m5.xlarge",
        "m5.2xlarge",
        "m5a.xlarge",
        "m5a.2xlarge"
    ],
    "TargetCapacity": 100,
    "TargetCapacityUnitType": "vcpu",
    "SingleAvailabilityZone": false
}
EoF
