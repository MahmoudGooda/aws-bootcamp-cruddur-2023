# Week 6 — Deploying Containers
## Test RDS Connection

* Create script file named `test` in `backend-flask/bin/db` to check our connection from our container.  
```py
#!/usr/bin/env python3

import psycopg
import os
import sys

connection_url = os.getenv("CONNECTION_URL")

conn = None
try:
  print('attempting connection')
  conn = psycopg.connect(connection_url)
  print("Connection successful!")
except psycopg.Error as e:
  print("Unable to connect to the database:", e)
finally:
  conn.close()
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/839c9e28a18f7a4b7c18a76cc88fde4ca0c3999d)  

---
* Add the following endpoint in  backend app:  
```py
@app.route('/api/health-check')
def health_check():
  return {'success': True}, 200
```

* Create bash script named `health-check` in `backend-flask/bin/flask`  
```py
#!/usr/bin/env python3

import urllib.request

try:
  response = urllib.request.urlopen('http://localhost:4567/api/health-check')
  if response.getcode() == 200:
    print("[OK] Flask server is running")
    exit(0) # success
  else:
    print("[BAD] Flask server is not running")
    exit(1) # false
# This for some reason is not capturing the error....
#except ConnectionRefusedError as e:
# so we'll just catch on all even though this is a bad practice
except Exception as e:
  print(e)
  exit(1) # false
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/671299f029a3f989d42b80c978af51a5ee9d9e3a)  

---
## Provision ECS Cluster
* Create ECS cluster `cruddur` using AWS CLI  
```sh
aws ecs create-cluster \
--cluster-name cruddur \
--service-connect-defaults namespace=cruddur
```
---
## Create ECR repo and push image for backend-flask
* Using the management console I created public repos to push images to.  
  '' Since I'm not 100% sure of service pricing, I tried to avoid any extra costs''  

### First push the python base image used in backend Dockerfile   
* Set URL  
```sh
export ECR_PYTHON_URL="cruddur-python PUBLIC REPO URI"
echo $ECR_PYTHON_URL
```
* Login to ECR  
```sh
aws ecr-public get-login-password $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin public.ecr.aws/$REPO_ALIAS
```
* Pull Image  
```sh
docker pull python:3.10-slim-buster
```
* Tag Image  
```sh
docker tag python:3.10-slim-buster $ECR_PYTHON_URL:3.10-slim-buster
```
* Push Image  
```sh
docker push $ECR_PYTHON_URL:3.10-slim-buster
```

![image](https://user-images.githubusercontent.com/105418424/229289922-a320f2e2-233d-4336-9e63-50e579879268.png)

### Push backend-flask image
* In backend Dockerfile, update the ***FROM*** to use our ECR image instead of using DockerHub's python image  

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b3485ce7e9390e86ec56bcfdfc42219c23613204)  
* Set URL  
```sh
export ECR_BACKEND_FLASK_URL="backend-flask PUBLIC REPO URI"
echo $ECR_BACKEND_FLASK_URL
```
* Build Image  
```sh
cd backend-flask
docker build -t backend-flask .
```
* Tag Image  
```sh
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```
Push Image  
```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```

![image](https://user-images.githubusercontent.com/105418424/229291023-f6379599-5a25-48ad-9a4c-519fd81d1076.png)  

## Deploy Backend Flask app as a service to Fargate

* To deploy the backend service we'll need to create a task definition which will require an excution & task roles and some parameters defined  

### Create Parameters in Parameter Store
 
```sh
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_ACCESS_KEY_ID" --value $AWS_ACCESS_KEY_ID
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY" --value $AWS_SECRET_ACCESS_KEY
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/CONNECTION_URL" --value $PROD_CONNECTION_URL
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" --value $ROLLBAR_ACCESS_TOKEN
aws ssm put-parameter --type "SecureString" --name "/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" --value "x-honeycomb-team=$HONEYCOMB_API_KEY"
```
  To check the parameters:  

* Search for **Systems Manager** service also called `ssm`  
* Click ***Parameters Store*** in the left hand side 
* Click each parameter and reveal it's value to check  

![image](https://user-images.githubusercontent.com/105418424/229295448-5ce03ecf-09f8-4c90-b746-df8974aaa707.png)
---
### Create Task and Execution Roles for Task Defintion

### Service Execution role
* Create `service-assume-role-execution-policy.json` inside `aws/policies`
```json
{
  "Version":"2012-10-17",
  "Statement":[{
      "Action":["sts:AssumeRole"],
      "Effect":"Allow",
      "Principal":{
        "Service":["ecs-tasks.amazonaws.com"]
    }}]
}

```
* Create `service-execution-policy.json` inside `aws/policies`  
```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
              "ssm:GetParameters",
              "ssm:GetParameter",
              "ecr:GetAuthorizationToken",
              "ecr:BatchCheckLayerAvailability",
              "ecr:GetDownloadUrlForLayer",
              "ecr:BatchGetImage",
              "logs:CreateLogStream",
              "logs:PutLogEvents"
          ],
          "Resource": "*"
      }
  ]
}
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/c01c7c0609f65551525beeacc0c014c9ce8b260b)  

* Create *CruddurServiceExecutionRole* from terminal cli
```sh
aws iam create-role \
--role-name CruddurServiceExecutionRole \
--assume-role-policy-document file://aws/policies/service-assume-role-execution-policy.json
```
* Create *CruddurServiceExecutionPolicy* from terminal cli
```sh
aws iam put-role-policy \
--policy-name CruddurServiceExecutionPolicy \
--role-name CruddurServiceExecutionRole \
--policy-document file://aws/policies/service-execution-policy.json`
```
* attach policy from terminal cli
```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::${AWS_ACCOUNT_ID}:policy/CruddurServiceExecutionPolicy --role-name CruddurServiceExecutionRole
```
### Task role
* Create task role from terminal cli
```sh
aws iam create-role \
    --role-name CruddurTaskRole \
    --assume-role-policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[\"sts:AssumeRole\"],
    \"Effect\":\"Allow\",
    \"Principal\":{
      \"Service\":[\"ecs-tasks.amazonaws.com\"]
    }
  }]
}"
```
* Put the policy to the role
```sh
aws iam put-role-policy \
  --policy-name SSMAccessPolicy \
  --role-name CruddurTaskRole \
  --policy-document "{
  \"Version\":\"2012-10-17\",
  \"Statement\":[{
    \"Action\":[
      \"ssmmessages:CreateControlChannel\",
      \"ssmmessages:CreateDataChannel\",
      \"ssmmessages:OpenControlChannel\",
      \"ssmmessages:OpenDataChannel\"
    ],
    \"Effect\":\"Allow\",
    \"Resource\":\"*\"
  }]
}
"
```
* Attach policies to the role
```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess --role-name CruddurTaskRole
```
```sh
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess --role-name CruddurTaskRole
```

![image](https://user-images.githubusercontent.com/105418424/229295522-904b90b4-ef5b-4823-9a3a-c9fd850cf334.png)

---
### Create task definition
* Create folder named `task-definitions` inside `aws/`  
* In this folder, Create a new file `backend-flask.json`  
```json
{
  "family": "backend-flask",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "requiresCompatibilities": [ 
    "FARGATE" 
  ],
  "containerDefinitions": [
    {
      "name": "backend-flask",
      "image": "BACKEND_FLASK_IMAGE_URL",
      "essential": true,
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "python /backend-flask/bin/flask/health-check"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "portMappings": [
        {
          "name": "backend-flask",
          "containerPort": 4567,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "$AWS_DEFAULT_REGION",
            "awslogs-stream-prefix": "backend-flask"
        }
      },
      "environment": [
        {"name": "OTEL_SERVICE_NAME", "value": "backend-flask"},
        {"name": "OTEL_EXPORTER_OTLP_ENDPOINT", "value": "https://api.honeycomb.io"},
        {"name": "AWS_COGNITO_USER_POOL_ID", "value": "${AWS_COGNITO_USER_POOL_ID}"},
        {"name": "AWS_COGNITO_USER_POOL_CLIENT_ID", "value": "${AWS_COGNITO_USER_POOL_CLIENT_ID}"},
        {"name": "FRONTEND_URL", "value": "*"},
        {"name": "BACKEND_URL", "value": "*"},
        {"name": "AWS_DEFAULT_REGION", "value": "us-east-1"}
      ],
      "secrets": [
        {"name": "AWS_ACCESS_KEY_ID"    , "valueFrom": "arn:aws:ssm:us-east-1:${AWS_ACCOUNT_ID}:parameter/cruddur/backend-flask/AWS_ACCESS_KEY_ID"},
        {"name": "AWS_SECRET_ACCESS_KEY", "valueFrom": "arn:aws:ssm:us-east-1:${AWS_ACCOUNT_ID}:parameter/cruddur/backend-flask/AWS_SECRET_ACCESS_KEY"},
        {"name": "CONNECTION_URL"       , "valueFrom": "arn:aws:ssm:us-east-1:${AWS_ACCOUNT_ID}:parameter/cruddur/backend-flask/CONNECTION_URL" },
        {"name": "ROLLBAR_ACCESS_TOKEN" , "valueFrom": "arn:aws:ssm:us-east-1:${AWS_ACCOUNT_ID}:parameter/cruddur/backend-flask/ROLLBAR_ACCESS_TOKEN" },
        {"name": "OTEL_EXPORTER_OTLP_HEADERS" , "valueFrom": "arn:aws:ssm:us-east-1:${AWS_ACCOUNT_ID}:parameter/cruddur/backend-flask/OTEL_EXPORTER_OTLP_HEADERS" }
      ]
    }
  ]
}
```

### Register Task Defintion
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```

### Set default VPC, Subnets, and Service SG
* Default VPC ID
```sh
export DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
--filters "Name=isDefault, Values=true" \
--query "Vpcs[0].VpcId" \
--output text)
echo $DEFAULT_VPC_ID
```
* Default Subnet IDs
```sh
export DEFAULT_SUBNET_IDS=$(aws ec2 describe-subnets  \
 --filters Name=vpc-id,Values=$DEFAULT_VPC_ID \
 --query 'Subnets[*].SubnetId' \
 --output json | jq -r 'join(",")')
echo $DEFAULT_SUBNET_IDS
```
* Create service SG
```sh
export CRUD_SERVICE_SG=$(aws ec2 create-security-group \
  --group-name "crud-srv-sg" \
  --description "Security group for Cruddur services on ECS" \
  --vpc-id $DEFAULT_VPC_ID \
  --query "GroupId" --output text)
echo $CRUD_SERVICE_SG
```

'' Edit the SG inbound rules to allow traffic on port *3000* and *4567* from anywhere *0.0.0.0/0* ''

![image](https://user-images.githubusercontent.com/105418424/229295289-132dc169-5881-4ff6-91d4-cf60839c19eb.png)

* Update RDS SG to allow access for the service security group
```sh
aws ec2 authorize-security-group-ingress \
  --group-id $DB_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $CRUD_SERVICE_SG \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=BACKENDFLASK}]'`
```

![image](https://user-images.githubusercontent.com/105418424/229295408-b12408a2-5e7c-4067-9952-e1f1f1cd2973.png)

### Create the backend service 
* Create `service-backend-flask.json` inside `aws/json`
```json
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "$CRUD_SERVICE_SG"
      ],
      "subnets": [
        "$DEFAULT_SUBNET_IDS"
      ]
    }
  },
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "backend-flask",
        "discoveryName": "backend-flask",
        "clientAliases": [{"port": 4567}]
      }
    ]
  },
  "propagateTags": "SERVICE",
  "serviceName": "backend-flask",
  "taskDefinition": "backend-flask"
}
```
* Deploy the service
```sh
aws ecs create-service --cli-input-json file://aws/json/service-backend-flask.json
```

![image](https://user-images.githubusercontent.com/105418424/229296036-eb35e385-24d3-4d28-9f52-3ec14c7c4291.png)

### Test RDS Connection
* To test the RDS connection from the service container, attach to the container and run the *test* script we created earlier.  
```sh
aws ecs execute-command  \
--region $AWS_DEFAULT_REGION \
--cluster cruddur \
--task TASK ID \
--container backend-flask \
--command "/bin/bash" \
--interactive
```

Got ``SessionManagerPlugin is not found`` error while trying to attach to the container  

* Install SSM plugin  
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-debian
* Verify the installation  
https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-verify

* Try connecting again and now could attach to the container  
![image](https://user-images.githubusercontent.com/105418424/229296966-ade8b183-e1b4-4707-b1f4-45e3ab086f84.png)

* Connection successful to the RDS!  
![image](https://user-images.githubusercontent.com/105418424/229297021-2a528221-1209-444a-8f85-24414f880eeb.png)

* Test Flask app health check  
![image](https://user-images.githubusercontent.com/105418424/229297066-145b3d7d-d1c4-43ea-b0ed-2d927cb9fc13.png)


## Provision and configure Application Load Balancer along with target groups

### Create Target groups for ALB  
* Create Backend-flask target group.
  - Choose *IP addresses*.  
  - Enter TG name.  
  - Enter 4567 for port number.  
  - Enter */api/health-check* for the health check path.  
  - Next and create without registering targets for now.  

* Create Frontend-react-js target group.
  - Choose *IP addresses*.  
  - Enter TG name.  
  - Enter 3000 for port number.  
  - Leave */* for the health check path.  
  - Next and create without registering targets for now.  

### Create the Application load balancer

* Enter the ALB name  
* choose the VPC (default in my case) and subnets  
* For security group, Create a new SG (cruddur-alb-sg)  
  - Allow inbound rules on ports (3000,4567,80,443) from Anywhere *"Temporarily"*  
* Choose the created SG
* For listener:
  - Enter *4567* for port number and forward to the backend target group
  - Create a new listener and enter *3000* for port number and forward to the frontend target group

* Update the *Service security group* to allow traffic on port 4567 from the load balancer  

![image](https://user-images.githubusercontent.com/105418424/229299565-14dd8989-08ff-487d-be94-50fc1e7ff314.png)

---
### Add the load balancer into the backend service.json
* Add the below ALB definition into the `aws/json/service-backend-flask.json`  
```json
"loadBalancers": [
    {
        "targetGroupArn": "${ALB TG ARN}",
        "containerName": "backend-flask",
        "containerPort": 4567
    }
  ],
```

## Create ECR repo and push image for fronted-react-js

### To push frontend-react image

* Set URL  
```sh
export ECR_FRONTEND_REACT_URL="frontend-react PUBLIC REPO URI"
echo $ECR_FRONTEND_REACT_URL
```

* Create a new `Dockerfile.prod` inside `frontend-react-js` folder  
'' we will use the below Dockerfile to build our image using the multistage build  ''
```Dockerfile
# Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM node:16.18 AS build

ARG REACT_APP_BACKEND_URL
ARG REACT_APP_AWS_PROJECT_REGION
ARG REACT_APP_AWS_COGNITO_REGION
ARG REACT_APP_AWS_USER_POOLS_ID
ARG REACT_APP_CLIENT_ID

ENV REACT_APP_BACKEND_URL=$REACT_APP_BACKEND_URL
ENV REACT_APP_AWS_PROJECT_REGION=$REACT_APP_AWS_PROJECT_REGION
ENV REACT_APP_AWS_COGNITO_REGION=$REACT_APP_AWS_COGNITO_REGION
ENV REACT_APP_AWS_USER_POOLS_ID=$REACT_APP_AWS_USER_POOLS_ID
ENV REACT_APP_CLIENT_ID=$REACT_APP_CLIENT_ID

COPY . ./frontend-react-js
WORKDIR /frontend-react-js
RUN npm install
RUN npm run build

# New Base Image ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
FROM nginx:1.23.3-alpine

# --from build is coming from the Base Image
COPY --from=build /frontend-react-js/build /usr/share/nginx/html
COPY --from=build /frontend-react-js/nginx.conf /etc/nginx/nginx.conf

EXPOSE 3000
```
'' we will use the below configuration file for the nginx server  ''

* Create `nginx.conf` inside `frontend-react-js` folder  
```sh
# Set the worker processes
worker_processes 1;

# Set the events module
events {
  worker_connections 1024;
}

# Set the http module
http {
  # Set the MIME types
  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  # Set the log format
  log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

  # Set the access log
  access_log  /var/log/nginx/access.log main;

  # Set the error log
  error_log /var/log/nginx/error.log;

  # Set the server section
  server {
    # Set the listen port
    listen 3000;

    # Set the root directory for the app
    root /usr/share/nginx/html;

    # Set the default file to serve
    index index.html;

    location / {
        # First attempt to serve request as file, then
        # as directory, then fall back to redirecting to index.html
        try_files $uri $uri/ $uri.html /index.html;
    }

    # Set the error page
    error_page  404 /404.html;
    location = /404.html {
      internal;
    }

    # Set the error page for 500 errors
    error_page  500 502 503 504  /50x.html;
    location = /50x.html {
      internal;
    }
  }
}
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b7295dfe5f679fbe4a5afbd58ed3e6caeb3b7342)  

* Build Image  
'' Make sure to be inside the `frontend-react-js` folder ''  
```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="http://${LOADBALANCER-DNS-NAME}:4567" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="${REACT_APP_AWS_USER_POOLS_ID}" \
--build-arg REACT_APP_CLIENT_ID="${REACT_APP_CLIENT_ID}" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
* Tag Image  
```sh
docker tag backend-flask:latest $ECR_BACKEND_FLASK_URL:latest
```
Push Image  
```sh
docker push $ECR_BACKEND_FLASK_URL:latest
```
![image](https://user-images.githubusercontent.com/105418424/229299825-54e33236-3640-44d6-8796-8da692c799b3.png)
---

* While inside the `frontend-react-js` folder, run the `npm run build` command to build for production  
```sh
cd frontend-react-js
npm run build
```
* Add the below line to exclude it in `.gitignore` file  
```sh
frontend-react-js/build/*
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5da0156f90fe43c02da4bbe2f68e6ba9deac083b)  

### Create Frontend task definition
* In the `aws/task-definitions` folder, Create a new file `frontend-react-js.json`
```json
{
  "family": "frontend-react-js",
  "executionRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/CruddurServiceExecutionRole",
  "taskRoleArn": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/CruddurTaskRole",
  "networkMode": "awsvpc",
  "cpu": "256",
  "memory": "512",
  "requiresCompatibilities": [ 
    "FARGATE" 
  ],
  "containerDefinitions": [
    {
      "name": "frontend-react-js",
      "image": "FRONTEND_IMAGE_URL",
      "essential": true,
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000 || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3
      },
      "portMappings": [
        {
          "name": "frontend-react-js",
          "containerPort": 3000,
          "protocol": "tcp", 
          "appProtocol": "http"
        }
      ],

      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "cruddur",
            "awslogs-region": "$AWS_DEFAULT_REGION",
            "awslogs-stream-prefix": "frontend-react-js"
        }
      }
    }
  ]
}
```
### Register Task Defintion
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/frontend-react-js.json
```

### Create the frontend service
* Create `service-frontend-react-js.json` inside `aws/json`
```json
{
  "cluster": "cruddur",
  "launchType": "FARGATE",
  "desiredCount": 1,
  "enableECSManagedTags": true,
  "enableExecuteCommand": true,
  "loadBalancers": [
    {
        "targetGroupArn": "${ALB TG ARN}",
        "containerName": "frontend-react-js",
        "containerPort": 3000
    }
  ],
  "networkConfiguration": {
    "awsvpcConfiguration": {
      "assignPublicIp": "ENABLED",
      "securityGroups": [
        "$CRUD_SERVICE_SG"
      ],
      "subnets": [
        "$DEFAULT_SUBNET_IDS"
      ]
    }
  },
  "propagateTags": "SERVICE",
  "serviceName": "frontend-react-js",
  "taskDefinition": "frontend-react-js",
  "serviceConnectConfiguration": {
    "enabled": true,
    "namespace": "cruddur",
    "services": [
      {
        "portName": "frontend-react-js",
        "discoveryName": "frontend-react-js",
        "clientAliases": [{"port": 3000}]
      }
    ]
  }
}
```

[Commit link for creating json files](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1c1b4456c23b026f3d86a36789376ac3615478de)  

* Deploy the service
```sh
aws ecs create-service --cli-input-json file://aws/json/service-frontend-react-js.json
```

* Frontend target healthy!  

![FE-tg-health](https://user-images.githubusercontent.com/105418424/229341584-507f60fa-d5f2-4e75-9681-57a1b76ef990.png)

* Test homepage with ALB URL  
  '' Backend, Frontend fargate containers are up and getting posts stored in RDS same as in PSQL week [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/journal/week4.md#test-to-post) ''  
  
  ![from-ecs](https://user-images.githubusercontent.com/105418424/229341603-decb528d-6722-4ad2-b234-163d11223981.png)

