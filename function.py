import json
import boto3

def lambda_handler(event, context):
    account="247212451018.dkr.ecr.us-east-2.amazonaws.com/"
    client = boto3.client('ecs')
    repo = event["detail"]["repository-name"]
    image_tag = event["detail"]["image-tag"]
    cluster = repo.split("/")[0].capitalize()
    service  = repo.split("/")[1]
    task_definition = service + ":" + image_tag
    repo_image = account + repo + ":" + image_tag
    update_task_definition(client, service, repo_image)
    latest_task_definition = get_latest_task_definition_revision(client, service)
    print(latest_task_definition)
    update_service(client, cluster, service, latest_task_definition)


def update_service (client, cluster, service, task_definition):
    client.update_service(
        cluster=cluster,
        service=service,
        taskDefinition=task_definition
    )

def update_task_definition (client, family, repo):
    client.register_task_definition(
        family=family,
        containerDefinitions=[
            {
                'name': family,
                'image': repo,
                'memory': 128,
                'portMappings': [
                    {
                        'containerPort': 8000,
                        'hostPort': 0,
                        'protocol': 'tcp'
                        
                    },
                ]
            }
        ],
        cpu='128',
        memory='128'
    )

def get_latest_task_definition_revision (client, family):
    return client.list_task_definitions(familyPrefix=family,sort='DESC')["taskDefinitionArns"][0].split("/")[1]