# Week 9 — CI/CD with CodePipeline, CodeBuild and CodeDeploy

### Prerequisites

* First we need to create a new branch from main called **"prod"**  
* Create a `buildspec.yml` file which will be needed to use in creating the ***Build project***  
  * Create `backend-flask/buildspec.yml`  
  Find the file [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/backend-flask/buildspec.yml)  (Use your own values) 
  * Create a **Pull Request** from **"main"** to **"prod"** branch with the pushed updates after creating the file  
## Configuring CodeBuild
### Create a Build Project

  '' First we need to create a build project which will be needed to use in the ***Build*** stage in our pipeline ''

* **Name**: `cruddur-backend-flask-bake-image`  
* **Enable build badge**  
* **Source**:  
    - **Source provider**: GitHub (Connect to GitHub if asked)  
    - **Repository URL**: `https://github.com/<Your Github account>/aws-bootcamp-cruddur-2023`  
* **Environment**: (Managed image)  
    - **Operating system**: `Amazon Linux2`
    - **Runtime(s)**: `Standard`  
    - **Image**: choose the latest image  
    - Check the **"Privileged"** option  
    - Choose to Create a new service Role (Role name will be auto generated)  
    - Set the timeout to `20 minutes`  
    - Don't choose a certificate or VPC  
* Choose buildspec > **Buildspec name**: `backend-flask/buildspec.yml`  
* **CloudWatch logs**:
    - **Group name**: `/cruddur/build/backend-flask`  
    - **Stream name**: `backend-flask`  

* Test by clicking **Start build**  

I got a ***permissions error*** to login to ECR, So I added the required permissions into the created IAM Role for the codebuild project.  

You can find the added permissions [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/aws/policies/CodeBuildBasePolicy-cruddur-backend.json)  
  " Note that I added the required permissions for ***public ECR*** repo because I am using a public one "  

After applying the permissions, Build stage succeeded!  
![codebuild-succeeded](https://user-images.githubusercontent.com/105418424/233863204-c6cec17a-8e94-46b1-8df1-7ce29b30ed0f.JPG)  

---
## Configuring CodePipeline
### From AWS console, Create new codepipeline:
* **name**: `cruddur-bakend-fargate`  
* An IAM Role will be created with an auto generated name, and leave the rest as defaults  
* **Source**: Github version 2 (If asked to connect to GitHub account)  
  - Connect to GitHub >> **Connection name**: `cruddur` >> connect  
  - Install new app >> choose the bootcamp repo >> a random number will be shown in the Apps field  
  - Click **connect**  
* Choose the repo name  
* **Branch name**: `prod`  
* Skip the build stage  
* **Deploy stage**:
  - **Provider**: `Amazon ECS`  
  - **Clustername**: `cruddur`  
  - **Service name**: `backend-flask`  
* Review and create the pipeline  

The pipeline deploy stage will fail because it has Invalid action configuration!  
Now let's add the build stage to our Pipeline  

* Edit the pipeline >> Add a stage after **Source**:  
  - **Stage name**: `bake-image`  
  - add **Action Group**:  
    + **Action name**: `build`  
    + **Provider**: `AWS CodeBuild ` 
    + **Input artifacts**: `SourceArtifact`  
    + **Project name**: `cruddur-backend-flask-bake-image`  
    + **Output artifacts**: `ImageDefinition`  

* Update the ***Deploy*** stage input artifact to be: `ImageDefinition`  
* Click **Release change** and check if the service is deployed to ECS  
![image](https://user-images.githubusercontent.com/105418424/233866588-4e8c31da-e2ea-408e-87e8-b4612c4f74bf.png)

  " We need to test with any code change to check if the pipeline is triggered "  
* Update health-check endpoint like in [this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/654054208e8008c4b0a19e025beb83807af4e375)  
* Merge this update with **"prod"** branch, The pipeline should be triggered with this change to the **"prod"** branch  

**Below is the events of Provisioning new task, deregistering old target & registering the new one**  
![10](https://user-images.githubusercontent.com/105418424/233865811-f2a3acfa-693b-47a7-b6bf-43ddb7f0cdd6.JPG)

**Pipeline Stages are succeeded**  
![13](https://user-images.githubusercontent.com/105418424/233865893-4130d3b1-349b-441a-8f5c-037fce77912c.JPG)

**new health check endpoint**  
![11](https://user-images.githubusercontent.com/105418424/233865906-888239a6-0a41-4857-9563-af37d82c1673.JPG)