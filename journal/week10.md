# Week 10 — CloudFormation

### In this week we are using CloudFormation templates to create our project resources & components  

## Prerequisites
* Install **"cfn-lint"** for cloudformation templates validation.  
```sh
pip install cfn-lint
```
* Install **"cfn-guard"** using cargo for evaluating our templates with best practices.  
```sh
cargo install cfn-guard
```
* Install **"cfn-toml"** to use it for configuration (eg. used parameters) using TOML format.  
```sh
gem install cfn-toml
```
* Create the artifacts S3 bucket and add it to the deploy scripts. In my case "cfn-artifacts-space"  

Set it as environment variable  
```sh
export CFN_BUCKET="cfn-artifacts-space"
gp env CFN_BUCKET="cfn-artifacts-space"
```
* Add these commands to `.gitpod.yml` to be included in workspace initialization.  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/4cc1e8721d9c4c30fc77f695463b3e258e4bfcb6)  

---
## Implement CFN Networking Layer
* Create networking CFN template **"aws/cfn/networking/template.yaml"**  
* Create configuration TOML file **"aws/cfn/networking/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/networking"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7c86f639e9f969f37240973018d3e49dbebf34b)  

---
## Implement CFN Cluster Layer
* First, Delete the manually created services from AWS console (ECS cluster, services, tasks, namespaces, ALB + listeners, target groups, etc...)  
* Create cluster CFN template **"aws/cfn/cluster/template.yaml"**  
* Create configuration TOML file **"aws/cfn/cluster/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/cluster"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f0700478100efcb8cd25b44b7d22fbe1b75e4211)  
* Update Route53 hosted zone frontend & backend records with the new ALB  

  '' Since the `config.toml` file contains the **"CertificateArn"**, I excluded the file in the `.gitignore` file not to be pushed ''  
  '' I disabled the **"container insights"** to reduce costs as possible! ''  

---
## Implement CFN Database Layer (RDS)
* Create RDS CFN template **"aws/cfn/db/template.yaml"**  
* Create configuration TOML file **"aws/cfn/db/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/db"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/4ff80320b89a41439f89e38b7364ba7f08ef5a51)  
'' I disabled the **"Performance insights"** to reduce costs as possible! ''  

  In order not to expose Database master password, script command will call it's variable.  
* Set password environment variable:  
```sh
export DB_PASSWORD= <Database password>
gp env DB_PASSWORD= <Database password>
```
* Update the **"CONNECTION_URL"** parameter value in the parameter store with the one created by CloudFormation.  

---
## Implement CFN Service Layer for Backend
* Delete the manually created services from AWS console (IAM excution & task roles, etc...)  
* Create Service CFN template **"aws/cfn/service/template.yaml"**  
* Create configuration TOML file **"aws/cfn/service/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/service"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5ca348067e1eab2db84f6fb25753b77f648fcdeb)  
### Check backend health check after deployment  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/81f41b90-93d1-4cba-932c-10c405bb7fdb)  

---
## Implement DynamoDB using SAM
### Using SAM CLI, we will deploy our DynamoDB  
  '' The AWS Serverless Application Model Command Line Interface (AWS SAM CLI) is a command line tool that you can use with AWS SAM templates and supported third-party integrations to build and run serverless applications '' See AWS Docs [Here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-reference.html)  
* Install SAM CLI (See installation Docs [Here](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html))  
```sh
cd /workspace
wget https://github.com/aws/aws-sam-cli/releases/latest/download/aws-sam-cli-linux-x86_64.zip
unzip aws-sam-cli-linux-x86_64.zip -d sam-installation
sudo ./sam-installation/install
cd $THEIA_WORKSPACE_ROOT
```
* Add the installation to `.gitpod.yml` file  
  [Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e02e8c248ed0d6ef767a7802bc8fececefe403b7)  
    
* Create DDB CFN template **"ddb/template.yaml"**  
* Create configuration TOML file **"ddb/config.toml"**  
* Create the lambda function will be deployed 
  **"/ddb/cruddur-messaging-stream/lambda_function.py"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f0c1918884c39a89f3c0ccfc4d4f76ab3c39234f)  

* Create /ddb/build & package & deploy scripts
    - **"ddb/build"**  
    - **"ddb/package"**  
    - **"ddb/deploy"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/210fda106078ba730b79cc6696fed79be8b486e3)  

---
## Implement CI/CD CFN
* Create CICD CFN template **"aws/cfn/cicd/template.yaml"**  
* Create configuration TOML file **"aws/cfn/cicd/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/cicd"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f41ed41c10b5e816e257776172ef89c62fc9e3eb)  

* Create Codebuild nested stack **"aws/cfn/cicd/nested/codebuild.yaml"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f87b3bc4c688c3f1b2a2a0907457a17ac8ef198d)  

* Create S3 bucket manually to be the artifacts store. In my case "codepipeline-cruddur-artifacts-space"  
* Check the created stack status  
![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/613d5417-03a0-40ba-a198-750218b8d855)
* Make sure to update the pending connection state  

---
## Implement CFN Static Website Hosting for Frontend
* Create Frontend CFN template **"aws/cfn/frontend/template.yaml"**  
* Create configuration TOML file **"aws/cfn/frontend/config.toml"**  
* Create CFN deploy bash script 	**"bin/cfn/frontend"**  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/596201403f766c9e85087ee021ab7315919bb71c)  

  '' I add the `config.toml` file in the `.gitignore` to be excluded as well since it contains CertificateARN ''  
* Remove the root naked domain A record from Route53 hosted zone records to avoid conflicts  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/daa8c75f-53ca-47c7-b553-2313d0526fe3)
