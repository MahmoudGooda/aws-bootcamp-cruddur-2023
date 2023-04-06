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

---
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

---
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
---
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

---
## Domain Bought!
* My website domain will be ***cruddur.space***  

## Manage your domain using Route53 via hosted zone
* Create a new Route53 hosted zone ( Public with our domain name)  

## Create an SSL certificate via ACM
* From ***AWS Certificate Manager*** Service, Request a new public certificate.  
* In the name entered domain name `"cruddur.space"` and add another one `"*.cruddur.space"`.  
* From the certificate page, Click **"Create records in Route 53"** and select both Domains you entered perviously.  

### Update ALB Listeners
* From Load Balancer page, Add 2 new listeners  
  - First listener from port *80* > Action > redirects to HTTPS 443  
  - Second Listener from port *443* > Action > forwards to *Frontend-react-js* target group  
  - Choose the certificate we just created previously  
  - Remove other listeners  
  - Update the *443* Listener rules to forward *api.cruddur.space* to *backend-flask* target group  
  
  ![443-LB-rule](https://user-images.githubusercontent.com/105418424/229364052-19244cbc-dddb-47a8-b4ea-b4d56ed0e36e.png)

### Add ALB records in Route53 Hosted zone
* From Route53 Hosted zone page, Create 2 new records  
  - First record for naked domain to point to *frontend-react-js* ( Choose the *Alias* and region and load balancer)  
  - Second record for api subdomain to point to *the backend-flask*

  ![image](https://user-images.githubusercontent.com/105418424/229362996-f88ce9a3-8c7a-4aaa-b8dc-dada9697dbcf.png)

* Hosted zone records should look like this now  

  ![image](https://user-images.githubusercontent.com/105418424/229363084-6d4c7782-0f30-4862-8831-f7b903a7d844.png)

### Test redirection
* Now let's check the backend service traffic redirection from health check endpoint!  

![api-redirection](https://user-images.githubusercontent.com/105418424/229363416-eeb9ec69-1e47-4865-9c10-e945854065c2.png)
![api-redirection2](https://user-images.githubusercontent.com/105418424/229363436-1592314f-3131-4681-86ae-b6889491d5bc.png)

### Configure CORS to only permit traffic from our domain

* Update backend & frontend URLs under *environment* in `service-backend-flask.json`  
```json
{"name": "FRONTEND_URL", "value": "https://cruddur.space"},
{"name": "BACKEND_URL", "value": "https://api.cruddur.space"},
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f8ce275cd723c168e37beb1c77c94f463a0eac64)  

* Re-register the new task definition  
```sh
aws ecs register-task-definition --cli-input-json file://aws/task-definitions/backend-flask.json
```

* Rebuild the *frontend-react-js* image with the new backend URL  
```sh
docker build \
--build-arg REACT_APP_BACKEND_URL="https://api.cruddur.space" \
--build-arg REACT_APP_AWS_PROJECT_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_COGNITO_REGION="$AWS_DEFAULT_REGION" \
--build-arg REACT_APP_AWS_USER_POOLS_ID="${REACT_APP_AWS_USER_POOLS_ID}" \
--build-arg REACT_APP_CLIENT_ID="${REACT_APP_CLIENT_ID}" \
-t frontend-react-js \
-f Dockerfile.prod \
.
```
* Home page with the new domain name!  

![homepage with new domain-ecs](https://user-images.githubusercontent.com/105418424/229363810-77f1cf7e-5363-46f5-973d-292a1651f23c.png)

## 	Secure Flask by not running in debug mode
  ''Enable debugging in development only''  
* Update the backend-flask `Dockerfile` to use `--debug` flag in flask run command  
* To prevent debug mode from production environment:  
  - use `"--no-debugger"` and `"--no-reload` flags in the `Dockerfile.prod` CMD   
```Dockerfile
CMD [ "python3", "-m" , "flask", "run", "--host=0.0.0.0", "--port=4567", "--no-debug","--no-debugger","--no-reload"]
```
* Build the backend-flask docker-prod image  
* Intentionally break anything in the backend code to produce an error, that should result (Internal server error)  

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b0f0ef559c0e7e40191a317512b730c8d2666e7f)  

## Implement Refresh Token for Amazon Cognito

In order to resolve the expiring token problem, we have to use a method to refresh the current user session.  

* Below will create a function to get the access token and update the authentication check to set the access token into local storage  
* Update the `frontend-react-js/src/lib/CheckAuth.js`  
```js
import { Auth } from 'aws-amplify';
import { resolvePath } from 'react-router-dom';

export async function getAccessToken(){
  Auth.currentSession()
  .then((cognito_user_session) => {
    const access_token = cognito_user_session.accessToken.jwtToken
    localStorage.setItem("access_token", access_token)
  })
  .catch((err) => console.log(err));
}

export async function checkAuth(setUser){
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((cognito_user) => {
    console.log('cognito_user',cognito_user);
    setUser({
      display_name: cognito_user.attributes.name,
      handle: cognito_user.attributes.preferred_username
    })
    return Auth.currentSession()
  }).then((cognito_user_session) => {
      console.log('cognito_user_session',cognito_user_session);
      localStorage.setItem("access_token", cognito_user_session.accessToken.jwtToken)
  })
  .catch((err) => console.log(err));
};
```
---
### Apply the update to the authentication required pages
* Update `MessageForm.js`, `HomeFeedPage.js`, `MessageGroupPage.js`, `MessageGroupsPage.js`  
* Import function  
```js
import {getAccessToken} from '../lib/CheckAuth';
```
* Get access token  
```js
await getAccessToken()
      const access_token = localStorage.getItem("access_token")
```
Replace the ***Authorization header*** line  
```js
'Authorization': `Bearer ${access_token}`,
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/4fc590d7b50f9e0e15537fc024687d7a4a35f7cf#diff-716a46d7255bdc7f3c7c1f5f463d4580b0f4dcb288e9027b432ea13e8baebdf9)  

* Same update for `MessageGroupNewPage.js`  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5242a233cc825ae23c25c586e3738d4b8933e792)  

---
## Refactor bin directory to be top level
First I created the required scripts, then restructured the **bin** directory containing all scripts  

* Created scripts for docker build, run, and ecs services connect  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1ad644d9d402477d41516ae290941806d7f70301)  
Then corrected the ***build*** script backend path in the below commit  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2bf18aac27074f2053ab7e33da9e1f2fb776427d)  

* In the below commit located the new scripts folder structure  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e9dda86a64e3a552268ea3f045460b0c5fc3c774)

* Updated the ***RDS SG update*** script path in `.gitpod.yml`  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/a432c9c9905b59f5cccc34c99911acdb4a3fe9f0)  

* Created a script to kill all DB sessions  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/610ae0b013ee6e70d693c2cb5cd61fc0361bc681)  
Noticed a `command not found` for python in the `db/setup` script, so update the command to `python3`  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b50bba311f73820426d7d7250ac36faf6940d572)  

* Updated the ***parent_path*** in the `ddb/patterns/list-conversations` script  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/6bc1a016b18435b21df0a37ec90306e191e7e0e4)  

* Finally here's the ***bin*** file structure so far!  
[bin file](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/tree/main/bin)

---
## Configure task definitions to contain X-RAY
* In backend & frontend task definitions add the follwing defintion for X-RAY  
`aws/task-definitions/backend-flask.json` & `aws/task-definitions/frontend-react-js.json` under ***"containerDefinitions"***  
```json
{
      "name": "xray",
      "image": "public.ecr.aws/xray/aws-xray-daemon" ,
      "essential": true,
      "user": "1337",
      "portMappings": [
        {
          "name": "xray",
          "containerPort": 2000,
          "protocol": "udp"
        }
      ]
    },
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/63434cb4edf3de95fae1fba5ac611232ca815538)  

* Need to register the updated task definition.  
  ''In order to make it easier, Create ***register*** script for registering task definitions''  

  In `bin/backend/register`  
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/backend-flask.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition --cli-input-json "file://$TASK_DEF_PATH"
```
  In `bin/frontend/register`  
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
TASK_DEF_PATH="$PROJECT_PATH/aws/task-definitions/frontend-react-js.json"

echo $TASK_DEF_PATH

aws ecs register-task-definition --cli-input-json "file://$TASK_DEF_PATH"
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/8498136586b2d3973a2f0af4767e2769428045eb)  

* Register the update task definition via script  
---
## Generate .env files using ruby for docker
  ''After storing variables in a `.env` file, the ***docker run*** command didn't pass some variables correctly''  

  Following along with Andrew, Created a ruby script to generate ***.env*** files using ***erb templates***  

* Create a folder `erb` for the erb files in the project root folder  
* Create `.erb` files with the variables to generate from  

`backend-flask.env.erb`   
```ruby
AWS_ENDPOINT_URL=http://dynamodb-local:8000
CONNECTION_URL=postgresql://postgres:password@db:5432/cruddur
FRONTEND_URL=https://3000-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
OTEL_SERVICE_NAME=backend-flask
OTEL_EXPORTER_OTLP_ENDPOINT=https://api.honeycomb.io
OTEL_EXPORTER_OTLP_HEADERS=x-honeycomb-team=<%= ENV['HONEYCOMB_API_KEY'] %>
AWS_XRAY_URL=*4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>*
AWS_XRAY_DAEMON_ADDRESS=xray-daemon:2000
AWS_DEFAULT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
AWS_ACCESS_KEY_ID=<%= ENV['AWS_ACCESS_KEY_ID'] %>
AWS_SECRET_ACCESS_KEY=<%= ENV['AWS_SECRET_ACCESS_KEY'] %>
ROLLBAR_ACCESS_TOKEN=<%= ENV['ROLLBAR_ACCESS_TOKEN'] %>
AWS_COGNITO_USER_POOL_ID=<%= ENV['AWS_COGNITO_USER_POOL_ID'] %>
AWS_COGNITO_USER_POOL_CLIENT_ID=<%= ENV['AWS_COGNITO_USER_POOL_CLIENT_ID'] %>
```

`frontend-react-js.env.erb`  
```ruby
REACT_APP_BACKEND_URL=https://4567-<%= ENV['GITPOD_WORKSPACE_ID'] %>.<%= ENV['GITPOD_WORKSPACE_CLUSTER_HOST'] %>
REACT_APP_AWS_PROJECT_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_COGNITO_REGION=<%= ENV['AWS_DEFAULT_REGION'] %>
REACT_APP_AWS_USER_POOLS_ID=<%= ENV['REACT_APP_AWS_USER_POOLS_ID'] %>
REACT_APP_CLIENT_ID=<%= ENV['REACT_APP_CLIENT_ID'] %>
```
* Create the ruby scripts  

`bin/backend/generate-env`
```ruby
#!/usr/bin/env ruby

require 'erb'

template = File.read 'erb/backend-flask.env.erb'
content = ERB.new(template).result(binding)
filename = "backend-flask.env"
File.write(filename, content)
```

`bin/frontend/generate-env`
```ruby
#!/usr/bin/env ruby

require 'erb'

template = File.read 'erb/frontend-react-js.env.erb'
content = ERB.new(template).result(binding)
filename = "frontend-react-js.env"
File.write(filename, content)
```

* To generate the env files anytime, just run the `generate-env` scripts  

  ''Now after generating the .env files, we don't want to push these secrets into our github repo''  
* Add `*.env` into `.gitignore` file  

* add the below 2 commands in `.gitpod.yml` to run ***"generate-env"*** scripts at workspace launch  
```yml
source "$THEIA_WORKSPACE_ROOT/bin/backend/generate-env"
source "$THEIA_WORKSPACE_ROOT/bin/frontend/generate-env"
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b895c1079b13b540590c2a4f3e4168227e7c4a66)  

---
### Create ***docker run*** scripts
`bin/backend/run`  
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
BACKEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $BACKEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/backend-flask.env"

docker run --rm \
  --env-file $ENVFILE_PATH \
  --network cruddur-net \
  --publish 4567:4567 \
  -it backend-flask-prod
```

`bin/frontend/run`  
```sh
#! /usr/bin/bash

ABS_PATH=$(readlink -f "$0")
FRONTEND_PATH=$(dirname $ABS_PATH)
BIN_PATH=$(dirname $FRONTEND_PATH)
PROJECT_PATH=$(dirname $BIN_PATH)
ENVFILE_PATH="$PROJECT_PATH/frontend-react-js.env"

docker run --rm \
  --env-file $ENVFILE_PATH \
  --network cruddur-net \
  --publish 3000:3000 \
  -it frontend-react-js
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ff04b9e91883ff9e1574a58559c6c0821656e3bf)  

---
## Change Docker Compose to explicitly use env files and user-defined network
### To use the variables from our generated .env files  
* In `docker-compose.yml` file, replace the ***environment*** definition and it's contents in frontend/backend services with the below:  
```yml
env_file:
      - backend-flask.env
```
```yml
env_file:
      - frontend-react-js.env
```
### To use our defined network  
* Replace the ***networks*** section with the below:  
```yml
networks:
  cruddur-net:
    driver: bridge
    name: cruddur-net
```
* Add the below network definition under every service  
```yml
networks:
      - cruddur-net
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/53d5126961d1de26ab798fcaa77ae1ca8a8841e6)  

---
## 	Create Dockerfile specfically for production use case
* Check all `Dockerfile.prod` files to make sure there's no unwanted tools exist
