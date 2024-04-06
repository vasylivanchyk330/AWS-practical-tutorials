# here are some sample commands for ec2-instance-selector utility


# excluding
ec2-instance-selector --vcpus 4 --memory 16 --gpus 0 --current-generation -a x86_64 --deny-list '.*[ni].*'   
# excluding n and i (enhanced network and intel-based)


# with output as a table 
ec2-instance-selector --vcpus 4 --memory 16 --gpus 0 --current-generation -a x86_64 --output table-wide