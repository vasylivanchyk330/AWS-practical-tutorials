

2 types of jobs:
- freestyle
- pipelines (translated into groovy)


2 modes for configuring a place to run:
- new node
- cloud (including docker; by installing plugin)


plugins
- docker, aws, kubernetes etc
- blueocean - basic plugin for cicd pipeline, it has better interface
- Naginator - basic plugin for failed job restarts
- Jenkins Job DSL - more advanced for failed job restarts
    - when sharding 
    e.g. of dsl script:
    ```
    job('DSL-Test') {
        scm {
            git('git://github.com/quidryan/aws-sdk-test.git')
        }
        triggers {
            scm('H/15 * * * *')
        }
        steps {
            maven('-e clean test')
        }
    }
    ```


#### socat container
to make the local host be able to communicate with your jenkins container, you need to proxy the traffic using the alpine/socat container
```
# run the container
docker run -d --restart=always \
    --network jenkins \ # you should've created this network already
    -p 127.0.0.1:2376:2375 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    alpine/socat \
    tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock

# get the socat cont ip address for later use
docker inspect <container_id> | grep IPAddress
```


#### some commands for Jenkins run on docker
```
docker exec -it jenkins-container-name bash
cd /var/jenkins_home # here's all the most interesting is located
cd /var/jenkins_home/workspace
```

#### Jenkins server with ASGs
CI/CD workloads can benefit of Cluster Autoscaler ability to scale down to 0.
Capacity will be provided just when needed, which increases further cost savings.

