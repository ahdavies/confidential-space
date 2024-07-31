#!/bin/bash
#
# Creates artifact repository and workload image. It also publishes the workload image to artifact repository.

source config_env.sh
source common.sh

PARENT_DIR=$(dirname ${PWD})

# UWEAR Set up
UWEAR_PROJECT_NUMBER=$(gcloud projects describe ${UWEAR_PROJECT_ID} --format="value(projectNumber)")

UWEAR_IMAGE_REFERENCE=${UWEAR_PROJECT_REPOSITORY_REGION}-docker.pkg.dev/${UWEAR_PROJECT_ID}/${UWEAR_ARTIFACT_REPOSITORY}/${UWEAR_WORKLOAD_IMAGE_NAME}:${UWEAR_WORKLOAD_IMAGE_TAG}

set_gcp_project ${UWEAR_PROJECT_ID}

create_artifact_repository ${UWEAR_ARTIFACT_REPOSITORY} ${UWEAR_PROJECT_REPOSITORY_REGION}

gcloud auth configure-docker ${UWEAR_PROJECT_REPOSITORY_REGION}-docker.pkg.dev

echo "Updating workload code with required resource names ..."
cd ${PARENT_DIR}/scripts
./generate_uwear_workload_code.sh
sed -i'' "s/UWEAR_PROJECT_ID/${UWEAR_PROJECT_ID}/" ${PARENT_DIR}/src/uwear/workload.go
sed -i'' "s/UWEAR_PROJECT_NUMBER/${UWEAR_PROJECT_NUMBER}/" ${PARENT_DIR}/src/uwear/workload.go

echo "Building the workload go binary ..."
cd ${PARENT_DIR}/src/uwear
go mod init workload && go mod tidy
CGO_ENABLED=0 go build workload.go

echo "Building the workload docker image ..."
docker build . -t ${UWEAR_IMAGE_REFERENCE}
cd ${PARENT_DIR}/scripts

echo "Pushing the workload docker image to artifact registry ${UWEAR_ARTIFACT_REPOSITORY} ..."
docker push ${UWEAR_IMAGE_REFERENCE}

echo "Granting roles/artifactregistry.reader role to workload service account ${UWEAR_WORKLOAD_SERVICE_ACCOUNT} ..."
gcloud artifacts repositories add-iam-policy-binding ${UWEAR_ARTIFACT_REPOSITORY} \
  --project=${UWEAR_PROJECT_ID} \
  --role=roles/artifactregistry.reader \
  --location=${UWEAR_PROJECT_REPOSITORY_REGION} \
  --member="serviceAccount:${UWEAR_WORKLOAD_SERVICE_ACCOUNT}@${UWEAR_PROJECT_ID}.iam.gserviceaccount.com"

# USLEEP Set up
USLEEP_PROJECT_NUMBER=$(gcloud projects describe ${USLEEP_PROJECT_ID} --format="value(projectNumber)")

USLEEP_IMAGE_REFERENCE=${USLEEP_PROJECT_REPOSITORY_REGION}-docker.pkg.dev/${USLEEP_PROJECT_ID}/${USLEEP_ARTIFACT_REPOSITORY}/${USLEEP_WORKLOAD_IMAGE_NAME}:${USLEEP_WORKLOAD_IMAGE_TAG}

set_gcp_project ${USLEEP_PROJECT_ID}

create_artifact_repository ${USLEEP_ARTIFACT_REPOSITORY} ${USLEEP_PROJECT_REPOSITORY_REGION}

gcloud auth configure-docker ${USLEEP_PROJECT_REPOSITORY_REGION}-docker.pkg.dev

echo "Updating workload code with required resource names ..."

./generate_usleep_workload_code.sh
sed -i'' "s/USLEEP_PROJECT_ID/${USLEEP_PROJECT_ID}/" ${PARENT_DIR}/src/usleep/workload.go
sed -i'' "s/USLEEP_PROJECT_NUMBER/${USLEEP_PROJECT_NUMBER}/" ${PARENT_DIR}/src/usleep/workload.go

echo "Building the workload go binary ..."
cd ${PARENT_DIR}/src/usleep
go mod init workload && go mod tidy
CGO_ENABLED=0 go build workload.go

echo "Building the workload docker image ..."
docker build . -t ${USLEEP_IMAGE_REFERENCE}
cd ${PARENT_DIR}/scripts

echo "Pushing the workload docker image to artifact registry ${USLEEP_ARTIFACT_REPOSITORY} ..."
docker push ${USLEEP_IMAGE_REFERENCE}

echo "Granting roles/artifactregistry.reader role to workload service account ${USLEEP_WORKLOAD_SERVICE_ACCOUNT} ..."
gcloud artifacts repositories add-iam-policy-binding ${USLEEP_ARTIFACT_REPOSITORY} \
  --project=${USLEEP_PROJECT_ID} \
  --role=roles/artifactregistry.reader \
  --location=${USLEEP_PROJECT_REPOSITORY_REGION} \
  --member="serviceAccount:${USLEEP_WORKLOAD_SERVICE_ACCOUNT}@${USLEEP_PROJECT_ID}.iam.gserviceaccount.com"