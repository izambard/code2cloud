
# Specific project settings
BASE_IMAGE_NAME?=code2cloud
BASE_DOCKER_FILE?=deployment/Dockerfile

ENV_FILE?=.env

# Misc
INPUT?='coco'
TAG_NAME?=latest

PORTDB?=5432
WEB_CONCURRENCY?=1

REST_PORT=5000
REST_GET_API_INST_ARG=service.rest.rest_api:get_api_inst
HOST=0.0.0.0

# General AWS settings
AWS_CLI=aws
export AWS_DEFAULT_REGION=us-east-1

# AWS connection settings - better being in env
AWS_ECR_SCOPE?=gisgame/
AWS_ECR_ROOT?=876999595319.dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com/$(AWS_ECR_SCOPE)
AWS_ECR_PATH?=https://876999595319.dkr.ecr.$(AWS_DEFAULT_REGION).amazonaws.com
AWS_ECR_REST_IMAGE_ARN?="$(AWS_ECR_ROOT)$(REST_APP_NAME):$(TAG_NAME)"
AWS_ECR_WS_IMAGE_ARN?="$(AWS_ECR_ROOT)$(WS_APP_NAME):$(TAG_NAME)"
AWS_ECR_WORKER_IMAGE_ARN?="$(AWS_ECR_ROOT)$(WORKER_APP_NAME):$(TAG_NAME)"

# AWS Batch default settings (overridable from cmd line)
AWS_BATCH_ENV?=gisgame-alpha-env
AWS_BATCH_QUEUE?=gisgame-alpha-queue
AWS_BATCH_JOB_STATUS?=RUNNING
# To be fetch from docker repo:
AWS_BATCH_JOB_ROLE_ARN?="arn:aws:iam::077056946545:role/batchJob"
AWS_BATCH_JOB_DEF_NAME=$(REST_APP_NAME)
AWS_BATCH_JOB_DEF_VCPU?=1
AWS_BATCH_JOB_DEF_MEM?=500
AWS_BATCH_CONTAINER_PROPERTIES?='{"image": $(AWS_ECR_REST_IMAGE_ARN),"vcpus": $(AWS_BATCH_JOB_DEF_VCPU),"memory": $(AWS_BATCH_JOB_DEF_MEM),"command": [],"jobRoleArn": $(AWS_BATCH_JOB_ROLE_ARN),"volumes": [],"environment": [],"mountPoints": [],"ulimits": []}'

help:
	@cat Makefile

echo:
	# Echoing an input
	echo $(INPUT)

build:
	docker build -t $(BASE_IMAGE_NAME) -f $(BASE_DOCKER_FILE) .	

run:
	docker run -p $(REST_PORT):$(REST_PORT) -e GET_API_INST=$(REST_GET_API_INST_ARG) -e APP_PORT=$(REST_PORT) -e APP_HOST=$(HOST) -e ENV_FILE=$(ENV_FILE) --name $(REST_APP_NAME) $(BASE_IMAGE_NAME)

start:
	docker start $(REST_APP_NAME) 

stop:
	# Stoping docker container
	docker stop $(REST_APP_NAME)

rm:
	# Removing docker container
	docker rm $(REST_APP_NAME)

ecr_tag:
	# Tagging docker image before push to AWS ECR
	docker tag $(BASE_IMAGE_NAME):$(TAG_NAME) $(AWS_ECR_ROOT)$(BASE_IMAGE_NAME):$(TAG_NAME)

rerun: stop rm run

ecr_login:
	# Logging to AWS ECR
	$(AWS_CLI) ecr get-login --no-include-email --region us-east-1 | tr -d '\r' | bash

ecr_create_repo:
	$(AWS_CLI) ecr create-repository --repository-name $(AWS_ECR_SCOPE)$(REST_APP_NAME)

ecr_push_rest: ecr_tag_rest ecr_login
	# Pushing docker image to AWS ECR
	docker push $(AWS_ECR_ROOT)$(REST_APP_NAME):$(TAG_NAME)

ecr_push_ws: ecr_tag_ws ecr_login
	# Pushing docker image to AWS ECR
	docker push $(AWS_ECR_ROOT)$(WS_APP_NAME):$(TAG_NAME)

ecr_push_worker: ecr_tag_worker ecr_login
	# Pushing docker image to AWS ECR
	docker push $(AWS_ECR_ROOT)$(WORKER_APP_NAME):$(TAG_NAME)

ecr_push: ecr_tag ecr_login ecr_push_rest ecr_push_ws ecr_push_worker
	# Pushing docker image to AWS ECR

deploy_aws: build ecr_tag ecr_push

batch_queue:
	# Listing AWS Batch exiting jobs in queue
	$(AWS_CLI) batch list-jobs --job-queue $(AWS_BATCH_QUEUE) --job-status $(AWS_BATCH_JOB_STATUS)

AWS_BATCH_JOB_DEF_STATUS?=ACTIVE
batch_job_def:
	# Listing existing AWS batch job definitions
	$(AWS_CLI) batch describe-job-definitions --status $(AWS_BATCH_JOB_DEF_STATUS)

batch_create_job_def:
	# Creating AWS batch job definition
	$(AWS_CLI) batch register-job-definition --job-definition-name $(AWS_BATCH_JOB_DEF_NAME) --type container --container-properties $(AWS_BATCH_CONTAINER_PROPERTIES)

batch_submit:
	# Submitting AWS batch job
	$(AWS_CLI) batch submit-job --job-name $(AWS_JOB_NAME) --job-queue $(AWS_BATCH_QUEUE)  --job-definition $(AWS_BATCH_JOB_DEF_NAME)  --container-overrides  '{"command": ["python","-u","./app/run.py","$(REST_APP_NAME)"]}'