# CREATING A SPOT INTERRUPTION EXPERIMENT

# using AWS Fault Injection Simulator (FIS), you can validate the resiliency of your workload to the Spot interruptions, and optionally improve the workload resiliency by implementing check-pointing or cleanup tasks

### I. Create an IAM Role for AWS FIS

# 1. define a trust relationship file that allows the AWS FIS service to assume the role
# (so that AWS FIS can run experiments on your behalf)
cat <<EoF > ./fis_role_trust_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFISExperimentRoleAssumeRole",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                "fis.amazonaws.com"
                ]
            },
            "Action": "sts:AssumeRole"
        }

    ]
}
EoF

# 2. create
aws iam create-role --role-name my-fis-role --assume-role-policy-document file://fis_role_trust_policy.json


# 3. define a policy with required ec2 ections 
cat <<EoF > ./fis_role_permissions_policy.json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowFISExperimentRoleEC2Actions",
            "Effect": "Allow",
            "Action": [
                "ec2:RebootInstances",
                "ec2:StopInstances",
                "ec2:StartInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        },
        {
            "Sid": "AllowFISExperimentRoleSpotInstanceActions",
            "Effect": "Allow",
            "Action": [
                "ec2:SendSpotInstanceInterruptions"
            ],
            "Resource": "arn:aws:ec2:*:*:instance/*"
        }
    ]
}
EoF

# 4. create 
aws iam put-role-policy --role-name my-fis-role --policy-name my-fis-policy --policy-document file://fis_role_permissions_policy.json


# 5. export FIS role ARN
export FIS_ROLE_ARN=$(aws iam get-role --role-name my-fis-role | jq -r '.Role.Arn')




### II. Create the Spot interruption experiment template

# an FIS template must contain such sections: action, target, stop condition

# 1. Create an experiment template
cat <<EoF > ./spot_experiment.json
{
    "description": "Test Spot Instance interruptions",
    "targets": {
        "SpotInstancesInASG": {
            "resourceType": "aws:ec2:spot-instance",
            "resourceTags": {
                "aws:autoscaling:groupName": "EC2SpotWorkshopASG"
            },
            "filters": [
                {
                    "path": "State.Name",
                    "values": [
                        "running"
                    ]
                }
            ],
            "selectionMode": "PERCENT(50)"
        }
    },
    "actions": {
        "interruptSpotInstance": {
            "actionId": "aws:ec2:send-spot-instance-interruptions",
            "parameters": {
                "durationBeforeInterruption": "PT2M"
            },
            "targets": {
                "SpotInstances": "SpotInstancesInASG"
            }
        }
    },
    "stopConditions": [
        {
            "source": "none"
        }
    ],
    "roleArn": "${FIS_ROLE_ARN}",
    "tags": {}
}
EoF
# with "selectionMode", you can do `ALL`, `COUNT(n)`
# 


# 2. Create an experiment template using the json configuration and export FIS template id
export FIS_TEMPLATE_ID=$(aws fis create-experiment-template --cli-input-json file://spot_experiment.json | jq -r '.experimentTemplate.id')




### III. Run the Spot interruption experiment

aws fis start-experiment --experiment-template-id $FIS_TEMPLATE_ID

# as in the template, there is "selectionMode": "PERCENT(50)", you gonna see half of the instances being stopped
# (be acknowledged about the FIS has the quota of 5 instances -- the maximum number of EC2 Spot instance that can be interrupted by a single experiment)

# results:
    # the target Spot Instance receives an instance rebalance recommendation signal
    # after two minutes, the Spot Instance is terminated ("durationBeforeInterruption": "PT2M")
#


### OTHER

# How can I create an experiment template for interrupting Spot instances launched via the EC2 Fleet?
        "resourceTags": {
                "aws:ec2:fleet-id": "${FLEET_ID}"
            },

# `describe-spot-price-history` to retrieve the information on pricig
# OR  https://console.aws.amazon.com/ec2/ -> Spot Requests -> Pricing history