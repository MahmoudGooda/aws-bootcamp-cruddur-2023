# Week 4 — Postgres and RDS

## Provision RDS Instance
* Created RDS instance named `cruddur-db-instance` & database named `cruddur` using AWS CLI with the below configurations
```sh
aws rds create-db-instance \
  --db-instance-identifier cruddur-db-instance \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --engine-version  14.6 \
  --master-username {USERNAME} \
  --master-user-password {YOUR PASSWORD} \
  --allocated-storage 20 \
  --availability-zone us-east-1 \
  --backup-retention-period 0 \
  --port 5432 \
  --no-multi-az \
  --db-name cruddur \
  --storage-type gp2 \
  --publicly-accessible \
  --storage-encrypted \
  --enable-performance-insights \
  --performance-insights-retention-period 7 \
  --no-deletion-protection
```

![image](https://user-images.githubusercontent.com/105418424/226103241-625fc702-ec3c-43e2-8b43-762004b70fbc.png)  

All helpful RDS CLI actions from AWS Documentation can be found [Here](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/rds/index.html "AWS RDS CLI docs").

--------------------
## Bash scripting for common database actions
Instead of using manual repeated commands for database actions, Create bash scripts for these actions.  
* Create a folder named `db` inside `backend-flask/` for SQL files & a folder named `bin` for bash scripts.  
```sh
cd backend-flask
```
### Create Database file 
* Create a new SQL file for the schema named `schema.sql` in `backend-flask/db`.
* Add UUID Extension to make Postgres generate out UUIDs.
```sh
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```
* Create tables
```sh
CREATE TABLE public.users (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  display_name text NOT NULL,
  handle text NOT NULL,
  email text NOT NULL,
  cognito_user_id text NOT NULL,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
```sh
CREATE TABLE public.activities (
  uuid UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_uuid UUID NOT NULL,
  message text NOT NULL,
  replies_count integer DEFAULT 0,
  reposts_count integer DEFAULT 0,
  likes_count integer DEFAULT 0,
  reply_to_activity_uuid integer,
  expires_at TIMESTAMP,
  created_at TIMESTAMP default current_timestamp NOT NULL
);
```
* If the table exists, drop it
```sh
DROP TABLE IF EXISTS public.users;
DROP TABLE IF EXISTS public.activities;
```
[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-bbc12a1f400fea71904f24b48cd2032ec91f812c051c3957b664e36b4fc04887)  
[Updated the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b7a821d8234f4cfbdaf3aea96d0886dff0e728e4#diff-bbc12a1f400fea71904f24b48cd2032ec91f812c051c3957b664e36b4fc04887)

--------------------
### Connect to DB script
* Set `CONNECTION_URL` var. for local DB connection
```sh
export CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5433/cruddur"
gp env CONNECTION_URL="postgresql://postgres:pssword@127.0.0.1:5433/cruddur"
```
* Create bash script named `db-connect` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

# Make Colorful label
CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-connect"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

# Check to run in dev or prod
if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL
```
* Make it executable:  
```sh
chmod u+x bin/db-connect
```
* Execute the script:
```sh
./bin/db-connect
```
[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-0479ae0231d0d34113ed0e63eb5a2154e5df03cd4e9273b93bf0007478d5d0e0)  
[Last update for the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b7a821d8234f4cfbdaf3aea96d0886dff0e728e4#diff-0479ae0231d0d34113ed0e63eb5a2154e5df03cd4e9273b93bf0007478d5d0e0)

### Drop DB script
* Create bash script named `db-drop` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-drop"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "drop database cruddur;"
```
[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-60ae6e16cdbfc4b72a373908e90004e629202da0c7f0eb2205fd5a0a58923ecf)  
[Updated the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/03efde31d812c4ccc4f2fb53a85346e3508ce48a#diff-60ae6e16cdbfc4b72a373908e90004e629202da0c7f0eb2205fd5a0a58923ecf)

### See DB connections script
* In order to be able to drop database without error we have to make sure there's no opened sessions, So we can the below script to check all opened sessions
* Create bash script named `db-sessions` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-sessions"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

NO_URL=$(sed 's/\/cruddur//g' <<<"$URL")
psql $NO_URL -c "select pid as process_id, \
       usename as user,  \
       datname as db, \
       client_addr, \
       application_name as app,\
       state \
from pg_stat_activity;"
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/03efde31d812c4ccc4f2fb53a85346e3508ce48a#diff-9944c35f487a5367ad39eaa01702055b1af4aa9ed6680409e72ce4fe779b1ff5)  

### Shell script to create the database
* Create bash script named `db-create` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-create"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

NO_DB_CONNECTION_URL=$(sed 's/\/cruddur//g' <<<"$CONNECTION_URL")
psql $NO_DB_CONNECTION_URL -c "CREATE database cruddur;"
```

[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-3eff3d0efab2b7e67c6a01682312a43dbebabf33f9604b7118cd483d0adb9a1d)  
[Updated the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/03efde31d812c4ccc4f2fb53a85346e3508ce48a#diff-3eff3d0efab2b7e67c6a01682312a43dbebabf33f9604b7118cd483d0adb9a1d)

### Shell script to load the schema
* Create bash script named `db-schema-load` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-schema-load"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

schema_path="$(realpath .)/db/schema.sql"

echo $schema_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $schema_path
```
[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-018ca7bebb764207d620248995762b8afa4e2faf45c8dcee8df677e08358ddbc)  
[Last update for the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b7a821d8234f4cfbdaf3aea96d0886dff0e728e4#diff-018ca7bebb764207d620248995762b8afa4e2faf45c8dcee8df677e08358ddbc)

### Shell script to load the seed data
* Create bash script named `db-seed` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-seed"
printf "${CYAN}== ${LABEL}${NO_COLOR}\n"

seed_path="$(realpath .)/db/seed.sql"

echo $seed_path

if [ "$1" = "prod" ]; then
  echo "Running in production mode"
  URL=$PROD_CONNECTION_URL
else
  URL=$CONNECTION_URL
fi

psql $URL cruddur < $seed_path
```
[Created file commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ae93a18a0a9373693a2d8b1fac20c4ce7f258d56#diff-e54cc7919a9ef0b03e98c0d344f7d4f6f119218b5fe08a8f2b4fa9b41cf0a5fe)  
[Last update for the file in this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1c6d041df9076f715f74a38f431b702b6777ec94)

### Shell script to easily setup (reset) everything for our database
* Create bash script named `db-setup` in `backend-flask/bin`.
```sh
#! /usr/bin/bash

set -e # stop if it fails at any point

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="db-setup"
printf "${CYAN}===== ${LABEL}${NO_COLOR}\n"

bin_path="$(realpath .)/bin"

source "$bin_path/db-drop"
source "$bin_path/db-create"
source "$bin_path/db-schema-load"
source "$bin_path/db-seed"
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/03efde31d812c4ccc4f2fb53a85346e3508ce48a#diff-0e49a177b6424aaaaa8b9d99e8047b26019b9a03b085d212a0eb57d56f953c13)

---------------------
## Install postgres adapter in backend application
  To install the Postgres Adapter:
* Add the following into `requirements.txt`
```sh
psycopg[binary]
psycopg[pool]
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/d1d8918829ed8a522551ae624b22adccafbb10ab)

* Install requirements
```sh
pip install -r requirements.txt
```

### Create DB library for connections pool & db query
* Create a new file named `db.py` in `backend-flask/lib`

```py
from psycopg_pool import ConnectionPool
import os

def query_wrap_object(template):
  sql = f"""
  (SELECT COALESCE(row_to_json(object_row),'{{}}'::json) FROM (
  {template}
  ) object_row);
  """
  return sql
def query_wrap_array(template):
  sql = f"""
  (SELECT COALESCE(array_to_json(array_agg(row_to_json(array_row))),'[]'::json) FROM (
  {template}
  ) array_row);
  """
  return sql
connection_url = os.getenv("CONNECTION_URL")
pool = ConnectionPool(connection_url)
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/315e0d75738bcd021354a20b049650c5026556eb)

* In `home activities.py` Replace our mock endpoint with real api call

```py
sql= query_wrap_array("""
        SELECT
        activities.uuid,
        users.display_name,
        users.handle,
        activities.message,
        activities.replies_count,
        activities.reposts_count,
        activities.likes_count,
        activities.reply_to_activity_uuid,
        activities.expires_at,
        activities.created_at
      FROM public.activities
      LEFT JOIN public.users ON users.uuid = activities.user_uuid
      ORDER BY activities.created_at DESC
      """)
      print(sql)
      with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchone()
        print(json)
        return json[0]
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/687e722af96843630e0b0dfc5ec082274c470bdd)

## Connect GitPod to RDS Instance
In order to connect to the RDS instance we need to provide our GitPod IP and whitelist for inbound traffic on port 5432  
* Get GitPod IP
```sh
curl ifconfig.me
```
* Add SG inbound rule to allow traffic from ***GitPod IP*** address to port ***5432***

![image](https://user-images.githubusercontent.com/105418424/226109401-c2f43502-d256-4d71-8721-8f63e62d6566.png)  

* Set `SG ID` & `SG Rule ID` vars to easily modify them in the future
```sh
export DB_SG_ID="YOUR SG ID"
gp env DB_SG_ID="YOUR SG ID"
export DB_SG_RULE_ID="YOUR SG Rule ID"
gp env DB_SG_RULE_ID="YOUR SG Rule ID"
```
* Set `GITPOD_IP` var
```sh
GITPOD_IP=$(curl ifconfig.me)
```
* To modify the security group with the actuall GitPod IP anytime, Use the below command:
```sh
aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules SecurityGroupRuleId="$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32,Description=GITPOD}"
```
In the above command I set the rule description to ***"GITPOD"***  
AWS documentation for modifying SG with AWS CLI from [Here](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/ec2/modify-security-group-rules.html)

### Create shell script to modify Security Group
* Create a new file named `rds-sg-update` in `backend-flask/bin`
```sh

#! /usr/bin/bash

CYAN='\033[1;36m'
NO_COLOR='\033[0m'
LABEL="rds-sg-update"
printf "${CYAN}===== ${LABEL}${NO_COLOR}\n"

aws ec2 modify-security-group-rules \
    --group-id $DB_SG_ID \
    --security-group-rules SecurityGroupRuleId="$DB_SG_RULE_ID,SecurityGroupRule={IpProtocol=tcp,FromPort=5432,ToPort=5432,CidrIpv4=$GITPOD_IP/32,Description=GITPOD}"
```

### Update `.gitpod.yml` to set GITPOD_IP and modify the SG
  Since GitPod IP keeps changing each time we relaunch the workspace, We can automate this process to make sure to connect to RDS from GitPod properly  
* Insert the below **command** in `.gitpod.yml` to run at every workspace start:  
```yml
command: |
      export GITPOD_IP=$(curl ifconfig.me)
      source "$THEIA_WORKSPACE_ROOT/backend-flask/bin/rds-sg-update"
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/4aa56ea7145469be0aeb64b6725bec5958ee5af6)

--------------------
## Test remote access
* Set `PROD_CONNECTION_URL` var. for RDS DB connection  
'' Master username, password, RDS Endpoint, and db name depends on every user''
```sh
export PROD_CONNECTION_URL="postgresql://root:password@{RDS Instance Endpoint}:5432/cruddur"
gp env PROD_CONNECTION_URL="postgresql://root:password@{RDS Instance Endpoint}:5432/cruddur"
```
* Test connection to RDS DB from GitPod  
''RDS instance should be in ***Available*** state and security group allows traffic from GitPod''
```sh
psql $PROD_CONNECTION_URL
```
--------------------
## Create Congito Trigger to insert user into database

### Create Lambda function
* Create lambda function `cruddur-post-confirmation` in the same VPC as RDS instance.

![image](https://user-images.githubusercontent.com/105418424/226111725-5a76380d-ea2e-4dfb-b7ad-c32754194215.png)

  To import the *psycopg2* module in Lambda, We need to add it as Lambda Layer.  
  Since I'm in `us-east-1` region, I used a precompiled *psycopg* library from [this Repo](https://github.com/jetbridge/psycopg2-lambda-layer) and unfortunately I faced problems in running the function.  
  I created my own develpment layer as below:  
- Download the *psycopg2-binary* source files from this [Link](https://files.pythonhosted.org/packages/20/06/4581d1d6e35f2290319501708658208be0e57549b03ac733926a722d47d1/psycopg2_binary-2.9.5-cp38-cp38-manylinux_2_17_x86_64.manylinux2014_x86_64.whl)  
- Using any archiving tool, Extract to a folder "will output 3 folders".
- Create folder structure (python/lib/python3.8/site-packages/ THE 3 FOLDERS) > Archive it as .zip file.
- Create a new Lambda layer from (https://console.aws.amazon.com/lambda/home#/layers) > then upload the zip file.
- Enter the created layer ARN into the Lambda Layers section.

### Connect the function to VPC
* from the ***Configuration*** tab select ***VPC***  
* Connect the Lambda function to VPC (the default in my case)  
* Choose subnets (at least two subnets for high availability)  
* Choose Security group  
  
  in order to connect to the VPC, Lambda should have some additionl permissions:  
* Go to **IAM** console  
* Will notice that a role has been created with Lambda function's name+alias  
* Open the role, then add permissions  
* Create Policy to attach to the role  
* Choose **JSON** and enter the below policy  
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeNetworkInterfaces",
                "ec2:CreateNetworkInterface",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeInstances",
                "ec2:AttachNetworkInterface"
            ],
            "Resource": "*"
        }
    ]
}
```
* Create the policy with any familiar name  
* Attach the policy to our role  
* Connect the Lambda function to the VPC

### Set Environment Variable
* from the ***Configuration*** tab select ***Environment variables***
* Key: `CONNECTION_URL`   Value: `postgresql://root:password@{RDS Instance Endpoint}:5432/cruddur`  <----- Production connection URL

### The post confirmation function
* Create folder `Lambdas` inside `aws` folder.  
* Create `cruddur-post-confirmationt.py` in `aws/Lambdas`
```py
import json
import psycopg2
import os

def lambda_handler(event, context):
    user = event['request']['userAttributes']
    print('userAttributes')
    print(user)

    user_display_name  = user['name']
    user_email         = user['email']
    user_handle        = user['preferred_username']
    user_cognito_id    = user['sub']
    try:
      print('entered-try')
      sql = f"""
         INSERT INTO public.users (
          display_name, 
          email,
          handle, 
          cognito_user_id
          ) 
        VALUES(
          '{user_display_name}', 
          '{user_email}', 
          '{user_handle}', 
          '{user_cognito_id}'
        )
      """
      print('SQL Statement ----')
      print(sql)

      conn = psycopg2.connect(os.getenv('CONNECTION_URL'))
      cur = conn.cursor()
      cur.execute(sql)
      conn.commit() 

    except (Exception, psycopg2.DatabaseError) as error:
      print(error)
    finally:
      if conn is not None:
          cur.close()
          conn.close()
          print('Database connection closed.')
    return event
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2092bbe9169edb64020d36d785cdb6ea496b6655)

### Update CONNECTION_URL
* Update *CONNECTION_URL* used in the function to PROD in `docker-compose.yml` so the connection is established to RDS not the local DB
```yml
CONNECTION_URL: "${PROD_CONNECTION_URL}"
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ace35d11954c067a3faed109613e03be2e5768fe)

-------------------
## Add the function to Cognito
* Under the ***user pool properties*** add the function as a ***Post Confirmation*** lambda trigger.

![image](https://user-images.githubusercontent.com/105418424/226113174-7f62f55c-babe-4339-a61d-24736864e751.png)

### Test user insertion after sign up
* from the ***Monitor*** tab select ***View cloudWatch logs***

![image](https://user-images.githubusercontent.com/105418424/226114089-39393c26-126e-4383-90a1-1fb3441f0bec.png)

User signUp triggered Lambda without errors!

-------------------
## Create new activities with a database insert
  Following along with Andrew's ***Week 4 - Creating Activities*** video, I made some changes to enhance & tidy up the code.  

### in db.py 
* Updated  `db.py` library to have a `Db` class with the required functions.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-4d4413b1b6b19e2bba84add763693470bf0abf242e3395c156c7b2a3a63b5ba1)  

### in create_activity.py
* Update `create_activity.py` to create & query activities replacing the mock model.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-1e0e0142a9cba2b744624e9ece0b1e4f61074be40f499f4b0257180bc247e243)  

### in home_activities.py
* Moved the ***sql*** query portion as a template function in ***Db*** class of ***db*** library and used it instead.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-e7fc4f0f2b4e4510d81bbc953fe4e4198587359967fc005d49cb23f39e7f3130)  

### Group sql templates
* Inside `db` folder, Create folder `sql/activities` folder containting db templates to be used.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-bde677e0d6c2c0d57cc752a9bd9b943e80a7dbafd5f754ad09d2fa39190e5ac9)  

### in the Lambda function:
*  Replaced values with ***%s*** placeholders and let psycopg perform the conversion to avoid SQL injections. See [Psycopg docs](https://www.psycopg.org/docs/usage.html)  
*  Including parameters for the sql query.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-c4877c88b68c86e8d1cff23b7e5dd7f83dcc2472a1f3e22f2a9606b50338c33a)  

### Updates to return the correct user_uuid values
* Updated the `user_handle` value in `app.py`, `HomeFeedPage.js`, and `ActivityForm.js` component  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/118f1fd18d43ef508084fb498600791abca8a39e#diff-0014cc1f7ffd53e63ff797f0f2925a994fbd6797480d9ca5bbc5dc65f1b56438)  

### Test to post
* Everytime I was facing a different error and each time I intentionaly changed the displayname and post to check the changes, then finally I could post with the correct username and see other users posts without errors.

![crud posts](https://user-images.githubusercontent.com/105418424/226402779-0f3f6f4f-ec96-4954-8dde-1d531f1a0c63.jpg)