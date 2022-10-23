# Specific project settings
APP_NAME?=code2cloud
DOCKER_FILE?=deployment/Dockerfile

# Misc
INPUT?='coco'
TAG_NAME?=latest

REST_PORT=80
HOST=0.0.0.0

NBR_ITER?=1000
SEED?=50
API_CMD=conda run --no-capture-output -n code2cloud python -m uvicorn main.api:app --port $(REST_PORT) --host $(HOST)
JOB_CMD=conda run --no-capture-output -n code2cloud python -m main.job --nbr_iter $(NBR_ITER) --seed $(SEED)

help:
	@cat Makefile

echo:
	# Echoing an input
	echo $(INPUT)

build:
	docker build -t $(APP_NAME) -f $(DOCKER_FILE) .	

run_api: rm
	docker run -p $(REST_PORT):$(REST_PORT) --name $(APP_NAME) $(APP_NAME) $(API_CMD)

run_job: rm
	docker run -p $(REST_PORT):$(REST_PORT) --name $(APP_NAME) $(APP_NAME) $(JOB_CMD)	

rm:
	# Removing docker container
	docker rm $(APP_NAME)

# General AWS settings
AWS_CLI=aws
export AWS_DEFAULT_REGION=us-east-1

# AWS Batch default settings (overridable from cmd line)
AWS_BATCH_ENV?=code2cloud-compute-env
AWS_BATCH_QUEUE?=code2cloud-queue
AWS_BATCH_JOB_STATUS?=RUNNING
# To be fetch from docker repo:
AWS_ECR_REST_IMAGE_ARN=876999595319.dkr.ecr.us-east-1.amazonaws.com/code2cloud:latest
AWS_BATCH_JOB_ROLE_ARN?="arn:aws:iam::876999595319:role/ecsTaskExecutionRole"
AWS_BATCH_JOB_DEF_NAME=$(APP_NAME)-jobdef
AWS_BATCH_JOB_DEF_VCPU?=0.25
AWS_BATCH_JOB_DEF_MEM?=500
AWS_BATCH_CONTAINER_PROPERTIES?='{"image": $(AWS_ECR_REST_IMAGE_ARN),"vcpus": $(AWS_BATCH_JOB_DEF_VCPU),"memory": $(AWS_BATCH_JOB_DEF_MEM),"command":  ["conda", "run", "--no-capture-output", "-n", "code2cloud", "python","-m","main.job","--nbr_iter","Ref::nbr_iter","--seed","Ref::seed"],"jobRoleArn": $(AWS_BATCH_JOB_ROLE_ARN),"volumes": [],"environment": [],"mountPoints": [],"ulimits": []}'


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
	$(AWS_CLI) batch submit-job --job-name $(AWS_JOB_NAME) --job-queue $(AWS_BATCH_QUEUE)  --job-definition $(AWS_BATCH_JOB_DEF_NAME)  --parameters nbr_iter=$(NBR_ITER),seed=$(SEED),s3bucket=code2cloud.dev