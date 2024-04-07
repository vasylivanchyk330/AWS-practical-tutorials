# CREATING A LAUNCH TEMPLATE

# 1. create a launch template file 
cat << EOF > launch-template-data.json
{
  "ImageId": "%ami-id%",
  "TagSpecifications": [
    {
      "ResourceType": "instance",
      "Tags": [
        {
          "Key": "Name",
          "Value": "mySpotWorkshop"
        }
      ]
    }
  ],
  "UserData": "I2Nsb3VkLWNvbmZpZwpyZXBvX3VwZGF0ZTogdHJ1ZQpyZXBvX3VwZ3JhZGU6IGFsbAoKcGFja2FnZXM6CiAgLSBodHRwZAogIC0gY3VybAoKcnVuY21kOgogIC0gWyBzaCwgLWMsICJhbWF6b24tbGludXgtZXh0cmFzIGluc3RhbGwgLXkgZXBlbCIgXQogIC0gWyBzaCwgLWMsICJ5dW0gLXkgaW5zdGFsbCBzdHJlc3MtbmciIF0KICAtIFsgc2gsIC1jLCAiZWNobyBoZWxsbyB3b3JsZC4gTXkgaW5zdGFuY2UtaWQgaXMgJChjdXJsIC1zIGh0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L21ldGEtZGF0YS9pbnN0YW5jZS1pZCkuIE15IGluc3RhbmNlLXR5cGUgaXMgJChjdXJsIC1zIGh0dHA6Ly8xNjkuMjU0LjE2OS4yNTQvbGF0ZXN0L21ldGEtZGF0YS9pbnN0YW5jZS10eXBlKS4gPiAvdmFyL3d3dy9odG1sL2luZGV4Lmh0bWwiIF0KICAtIFsgc2gsIC1jLCAic3lzdGVtY3RsIGVuYWJsZSBodHRwZCIgXQogIC0gWyBzaCwgLWMsICJzeXN0ZW1jdGwgc3RhcnQgaHR0cGQiIF0KCgo="
}
EOF


# 2. replace ami placeholder 

# First, this command looks up the latest Amazon Linux 2 AMI
export ami_id=$(aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-kernel*gp2" "Name=virtualization-type,Values=hvm" "Name=root-device-type,Values=ebs" --query "sort_by(Images, &CreationDate)[-1].ImageId" --output text)

# substitute ami id in the file
sed -i.bak -e "s#%instanceProfile%#$instanceProfile#g" -e "s#%ami-id%#$ami_id#g" launch-template-data.json


# 3. Create the launch template
aws ec2 create-launch-template --launch-template-name TemplateForWebServer --launch-template-data file://launch-template-data.json


# 4. decrypt user-data script
aws ec2 describe-launch-template-versions  --launch-template-name TemplateForWebServer --output json | jq -r '.LaunchTemplateVersions[].LaunchTemplateData.UserData' | base64 --decode


# 5. export ami id as a var and check it's content
export LAUNCH_TEMPLATE_ID=$(aws ec2 describe-launch-templates --filters Name=launch-template-name,Values=TemplateForWebServer | jq -r '.LaunchTemplates[0].LaunchTemplateId')

echo $LAUNCH_TEMPLATE_ID