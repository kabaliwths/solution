Hello, I slightly modified the Cloudformation files to use only 2 public subnets without the privates ones and the Nat Gateways. The reason for is that I created a free tier AWS account and didn't want to get charged specially for Nat Gateways. However the code should work fine without any problems with both public/private.


Since we de don't know the ECS Sercive and the ECS Cluster in advance we need to find a way and pass that information to lambda function through an event and handle accordingly the event object from lambda_handler(event, context).

My idea was to create an ECR repository under a namespace for e.g Accountid.dkr.ecr.eu-west-1.amazonaws.com/NAMESPACE/REPO where the namespace is the name of the ECS cluster and the repository name is the ECS Service name. 

I used a Cloudwatch event similar to the following. Whenever we have a successfull push to ECR repository our target, which in our case is the lambda function, will be triggered. 


  {
        "source": [
            "aws.ecr"
        ],
        "detail-type": [
            "ECR Image Action"
        ],
        "detail": {
            "action-type": [
                "PUSH"
            ],
            "result": [
                "SUCCESS"
            ]
        }
   }

The function is getting all the appropriate information from event object such us (the namespace of the ecr url (Cluster name) and the repository name (Service name), image-tag). I want to mention here that I created manually the ECS service with the docker image I built from the folder hello-world. Its basically a python flask with an endpoint listening in port 8000. However this can be done from the lambda function in the 1st iteration by checking if the ECS service exist and if not then creating with create_service() function. Just wanted to mention this since I tested only the part where we update the service with the a new docker image tag.


docker build -t datawire/hello-world .    -> Build the image
docker tag ff6233d0ceb9 247212451018.dkr.ecr.us-east-2.amazonaws.com/production/hello:1
docker push 247212451018.dkr.ecr.us-east-2.amazonaws.com/production/hello:1


Whenever we push a new docker image to ECR, a new task definition is created with that image. Later on with the function get_latest_task_definition_revision we get the latest revision number from that task definition and with update_service we update the service with the new revision. Inside update_task_definition I define the container port 8000, but we can find a way to pass that parameter including an env file inside the lambda folder function. Like zip function.zip function.py .env


If I had more time I would try to implement this with a CodePipeline where I could  build the image via a CodeBuiled build and a buildspec.yml, push the image to ECR and later in another stange execute the lambda function.


