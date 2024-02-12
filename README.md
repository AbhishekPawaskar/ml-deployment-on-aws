# CI/CD pipeline for building Deployable Deep Learning Models in AWS

Detailed Documentation to Setup CI/CD pipeline using AWS for Deep Learning Models in Kubernetes.

## OverView

![image](https://github.com/AbhishekPawaskar/ml-deployment-on-aws/assets/46342691/afa62611-f145-406f-9caa-4777315d4ea3)

## Contents

1. Requirements
2. Setup
3. Triggering Deployments
4. FAQ
## 1. Requirements

1. AWS Account
2. GitHub Repository
3. Deep Learning Model (TensorFlow Compatible)
## 2. Setup

#### A. GitHub Repository: 
Make Sure you have following files in the root of the repository:
    
    > Dockerfile
    
    > buildspec.yml
    
    > deployments.yml


##### Dockerfile:

Standard `Dockerfile` for Building Images of Servable Deep Learning Models using Tensorflow is as follows:


```bash
FROM tensorflow/serving:latest

ENV MODEL_NAME=${MODEL_NAME}

ENV MODEL_BASE_PATH=/models

COPY /${MODEL_NAME}/1 /models/${MODEL_NAME}/1

CMD ["/usr/bin/tensorflow_model_server"]
```


##### buildspec.yml:

Standard `buildspec.yml` for getting the models form `AWS S3` and  Building Containers and inserting the container in `AWS ECR` is as follows (You may add image tags if you want to):


```bash
version: 0.2

phases:
  pre_build:
    commands:
      - aws s3 cp $S3_BUCKET_LINK ./$MODEL_NAME --recursive
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
  
  build:
    commands:
      - docker build -t $IMAGE_REPO_NAME .
      - docker tag $IMAGE_REPO_NAME $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
  
  post_build:
    commands:
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
```

#### B. AWS S3: 

a. Create a bucket in S3 with name of your choice.
b. Rearrange the file structure (specific to tenserflow serving) as follows. (Note: If you want more than one version of model to be a part of the same container add folders from next number after 1 like 2,3,4 etc )

```bash
MODEL_NAME
    |__1
       |--assets (folder)
       |   
       |--variables(folder)
       |   |__variables.index
       |
       |__saved_model.pb(file)
```
c. Upload the complete folder as above in S3 bucket. You may refer the [Documentation](https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html)

#### C. AWS ECR:

a. Navigate to `AWS Elastic Container Registry` using the Search option in the `AWS Console`

b. Under `Private Repository`, Click `Create Repository` option.

c. Give the name of choice and create. (Rest of the Settings are not complusory and you may choose defaults unless you need something to be specific.)


#### D. AWS CodeBuild:

a. Navigate to AWS CodeBuild using the Search option in the AWS Console

b. Under `build projects`, look for `Create Build Project` option.

c. Enter Project Name of choice and under `Source` choose `GitHub` as the source.

d. After choosing `GitHub` as the option you'll observe an option to connect AWS account with your GitHub's account. (One time thing, not necessary if already done.) You can either use `Personal Access Tokens` or `oAuth` to connect AWS & GitHub.

e. Choose the Repository consisting of corresponding Dockerfile & buildspec.yml files.

f.  Rest of the Settings are not complusory and you may choose defaults unless you need something to be specific.

g. click on `create build project`.

h. Revisit this Build Project and add Environment Variables required/mentioned in the `buildspec.yml` file. It is not a good idea to have sensitive information like account id in and `.env` file in the GitHub Repository. 


#### E. AWS CodePipeline:

a. Navigate to AWS CodePipeline using the Search option in the AWS Console

b. Under `pipelines`, look for `Create new pipeline` option.

c. Enter Pipeline Name of choice and under `Pipeline type` choose `V2` as the type. Click on `Next`. (unless you may choose defaults unless you need something to be specific.)

d. Under Source, Choose `GitHub Version 2` and then click on connect to GitHub. Here you may choose existing connection or Create a new on the spot.

e. Choose the Repository and choose how do you want to trigger the pipeline. If you want to trigger the pipeline when there is A `PUSH` to the `MAIN/MASTER` branch, then choose `PUSH` and choose branch name as `main`. Clicke `Next`.

f. Under Build Stage Choose the CodeBuild Project you created in previous step. and click `Next` and then another `Next`. (Ignore Stage option for now).

g. Once the pipeline is created it will start running and as default it will Fail, which is the intended result. 


#### F. AWS IAM:

a. Navigate to AWS IAM using the Search option in the AWS Console.

b. Under Policies, choose the Policies automatically created by codebuild & CodePipeline for their usage respectively. check for the necessary permission in the policies.

c. The policy for CodeBuild must have access to read the S3 bucktes and have read & right access to AWS ECR anf read access to get Read GitHub repo contents as well. Use the Visual Editor to enable the permissions in the Policies.

## 3. Triggering Deployments

There are two major Parts to this.

1. Creating the Container.
2. Deploying the Container in Kubernetes.

1. Creating the Container: This pipeline can be triggered using a git push/commit in the `main` branch or can be manually triggered by using `Run Build` or `Run pipeline` Options in `AWS CodeBuild` & `AWS CodePipeline` respectively.

2. Deploying the Container in Kubernetes: You can achive this by having Deployments pipeline similar to that of Backend Deployments and also using External tools like ArgoCD etc. But if would like to manually deploy in Kubernetes, then you may use the `Deployments.yaml` to deploy the same. 

```bash
#1. Navigate to location where Deployments.yaml file exists
#2. Authenticate and connect to your cluster
#3. deploy using the command

$ kubectl create -f Deployment.yaml

```
