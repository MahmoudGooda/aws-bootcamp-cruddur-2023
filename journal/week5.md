# Week 5 — DynamoDB and Serverless Caching

## Restructured backend bash scripts folder
* First I restructured the bash scripts folders `bin` in the backend-flask folder.  
'' in the bleow commit I restructured the scripts folders & un-commented the local DynamoDB section in `docker-compose.yml`.''  

[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/d09d53e84d601142543982fc931902bc08153375)  

----------
## Implement Bash Scripts
* Add `boto3` to `requirements.txt`  

[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/217c05c56f158c2071e35cea93cdc7be6d69f1b1)  

* Install requirements
```sh
cd backend-flask
pip install -r requirements.txt
```
-----
### Schema-Load script
* In the created `schema-load` file under `backend-flask/bin/ddb`:
```py
#!/usr/bin/env python3

import boto3
import sys

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

ddb = boto3.client('dynamodb',**attrs)

table_name = 'cruddur-messages'


response = ddb.create_table(
  TableName=table_name,
  AttributeDefinitions=[
    {
      'AttributeName': 'pk',
      'AttributeType': 'S'
    },
    {
      'AttributeName': 'sk',
      'AttributeType': 'S'
    },
  ],
  KeySchema=[
    {
      'AttributeName': 'pk',
      'KeyType': 'HASH'
    },
    {
      'AttributeName': 'sk',
      'KeyType': 'RANGE'
    },
  ],
  #GlobalSecondaryIndexes=[
  #],
  BillingMode='PROVISIONED',
  ProvisionedThroughput={
      'ReadCapacityUnits': 5,
      'WriteCapacityUnits': 5
  }
)

print(response)
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-9c3b0abbbb6307b61eec63489dfb259f98d45c9f76a69bfdc2f2b4c4c481f383)  

-----
### Seed script
* In the created `seed` file under `backend-flask/bin/ddb`  
'' since the seed information contains too way long conversation lines, please refer to [this commit Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-08b5434d12a6a8aa588589ad1e36ea5733a05836ed2b19effba0b80d4b6a696d) or the file from [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/backend-flask/bin/ddb/seed)''  

-----
### Scan script
* Create `scan` file under `backend-flask/bin/ddb` with the below contents which can be used to perform scan into our `cruddur-messages` DynamoDB table.  
```py
#!/usr/bin/env python3

import boto3

attrs = {
  'endpoint_url': 'http://localhost:8000'
}
ddb = boto3.resource('dynamodb',**attrs)
table_name = 'cruddur-messages'

table = ddb.Table(table_name)
response = table.scan()
items = response['Items']
for item in items:
    print(item)
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-3f6c3d39eee2425c980a2fa8ef6046a7cc33eea62862bd34f7ffa5616f5dedf4)  

-----
### List-tables script
* Create `list-tables` file under `backend-flask/bin/ddb` with the below contents which can be used to list DynamoDB tables.  
```sh
#! /usr/bin/bash

set -e # stop if it fails at any point

if [ "$1" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

aws dynamodb list-tables $ENDPOINT_URL \
--query TableNames \
--output table
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-38313c2bee3b66597dbe617a7dcc0b5f4fc7a1e4b741c91f13dafd5e8512ceae)  

-----
### Table drop script
* Create `drop` file under `backend-flask/bin/ddb` with the below contents which can be used to drop DynamoDB tables.  
```sh
#! /usr/bin/bash

set -e # stop if it fails at any point

if [ -z "$1" ]; then
  echo "No TABLE_NAME argument supplied eg ./bin/ddb/drop cruddur-messages prod "
  exit 1
fi
TABLE_NAME=$1

if [ "$2" = "prod" ]; then
  ENDPOINT_URL=""
else
  ENDPOINT_URL="--endpoint-url=http://localhost:8000"
fi

echo "deleting table: $TABLE_NAME"

aws dynamodb delete-table $ENDPOINT_URL \
--table-name $TABLE_NAME
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-12170b5d1ed5be5d4cacc6c5f14d64599ab72a47a5ad08697412848ca6f2ec6b)  

-----
## 	Implement Pattern Scripts for Read and List Conversations
* Create `patterns` folder under `backend-flask/bin/ddb` which will contain 2 bash scripts: 1 to list conversations and other to get conversation.  
* Create `get-conversation` file under `backend-flask/bin/ddb/patterns` with the below contents  
```py
#!/usr/bin/env python3

import boto3
import sys
import json
import datetime

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

message_group_uuid = "5ae290ed-55d1-47a0-bc6d-fe2bc2700399"

# define the query parameters
current_year = datetime.datetime.now().year
query_params = {
  'TableName': table_name,
  'ScanIndexForward': False,
  'Limit': 20,
  'ReturnConsumedCapacity': 'TOTAL',
  'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
#   'KeyConditionExpression': 'pk = :pk AND sk BETWEEN :start_date AND :end_date',
  'ExpressionAttributeValues': {
    ':year': {'S': str(current_year)},
    # ":start_date": { "S": "2023-03-01T00:00:00.000000+00:00" },
    # ":end_date": { "S": "2023-03-23T23:59:59.999999+00:00" },
    ':pk': {'S': f"MSG#{message_group_uuid}"}
  }
}


# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))

# print the consumed capacity
print(json.dumps(response['ConsumedCapacity'], sort_keys=True, indent=2))

items = response['Items']
items.reverse()

for item in items:
  sender_handle = item['user_handle']['S']
  message       = item['message']['S']
  timestamp     = item['sk']['S']
  dt_object = datetime.datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%S.%f%z')
  formatted_datetime = dt_object.strftime('%Y-%m-%d %I:%M %p')
  print(f'{sender_handle: <12}{formatted_datetime: <22}{message[:40]}...')
```
  '' In the above code we used ***items.reverse()*** in order to show the last messages down in the correct order.''  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-d5cfe27df373231cdeca7622a4b8cc178dce4e9a9103250805d87242c6fa07a3)  

-----
* Create `list-conversations` file under `backend-flask/bin/ddb/patterns` with the below contents  
```py
#!/usr/bin/env python3

import boto3
import sys
import json
import os
import datetime

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..', '..'))
sys.path.append(parent_path)
from lib.db import db

attrs = {
  'endpoint_url': 'http://localhost:8000'
}

if len(sys.argv) == 2:
  if "prod" in sys.argv[1]:
    attrs = {}

dynamodb = boto3.client('dynamodb',**attrs)
table_name = 'cruddur-messages'

def get_my_user_uuid():
  sql = """
    SELECT 
      users.uuid
    FROM users
    WHERE
      users.handle =%(handle)s
  """
  uuid = db.query_value(sql,{
    'handle':  'MGOODA'
  })
  return uuid

my_user_uuid = get_my_user_uuid()
print(f"my-uuid: {my_user_uuid}")

current_year = datetime.datetime.now().year
# define the query parameters
query_params = {
  'TableName': table_name,
      'KeyConditionExpression': 'pk = :pk AND begins_with(sk,:year)',
  'ScanIndexForward': False,
  'ExpressionAttributeValues': {
    ':year': {'S': str(current_year) },
    ':pk': {'S': f"GRP#{my_user_uuid}"}
  },
  'ReturnConsumedCapacity': 'TOTAL'
}

# query the table
response = dynamodb.query(**query_params)

# print the items returned by the query
print(json.dumps(response, sort_keys=True, indent=2))
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-fe895d5944b40b05c8251b77cccec5a465f26e10f137d93edb00255a4524b75a)  

----------------
* Added `query_value` function in the `db.py` which will be called to list conversations.  
* Added `params` to be printed with the sql query.  

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7f299af88798b47574a955744f719d9b7e66bf0#diff-4d4413b1b6b19e2bba84add763693470bf0abf242e3395c156c7b2a3a63b5ba1)  

----------------
### Getting error when running the drop & setup script
* In the below commit I updated `bin/db/drop` file so it only drops the databse if exists to avoid getting "database doesn't exist" error.  

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/10f01477ba107588db13bf929fd77753918e8ba9)

----------------
### Scripts for list cognito users and update cognito user ids
* Create `cognito` folder under `backend-flask/bin/`  
* Create file named `list-users` with the below contents  
```py
#!/usr/bin/env python3

import boto3
import os
import json

userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
client = boto3.client('cognito-idp')
params = {
  'UserPoolId': userpool_id,
  'AttributesToGet': [
      'preferred_username',
      'sub'
  ]
}
response = client.list_users(**params)
users = response['Users']

print(json.dumps(users, sort_keys=True, indent=2, default=str))

dict_users = {}
for user in users:
  attrs = user['Attributes']
  sub    = next((a for a in attrs if a["Name"] == 'sub'), None)
  handle = next((a for a in attrs if a["Name"] == 'preferred_username'), None)
  dict_users[handle['Value']] = sub['Value']

print(dict_users)
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ccce5eb6763a11b6fb2a0ccf390b260f06de3afa#diff-99cd53bc29fd0c0e117d32c9f2e0337619274bc6aa7727c288f46693d72d79a5)  

-----
* Inside `backend-flask/bin/db` folder, Create file named `update_cognito_user_ids` with the below contents  
```py
#!/usr/bin/env python3

import boto3
import os
import sys

current_path = os.path.dirname(os.path.abspath(__file__))
parent_path = os.path.abspath(os.path.join(current_path, '..', '..'))
sys.path.append(parent_path)
from lib.db import db

def update_users_with_cognito_user_id(handle,sub):
  sql = """
    UPDATE public.users
    SET cognito_user_id = %(sub)s
    WHERE
      users.handle = %(handle)s;
  """
  db.query_commit(sql,{
    'handle' : handle,
    'sub' : sub
  })

print("-------------------")
def get_cognito_user_ids():
  userpool_id = os.getenv("AWS_COGNITO_USER_POOL_ID")
  client = boto3.client('cognito-idp')
  params = {
    'UserPoolId': userpool_id,
    'AttributesToGet': [
        'preferred_username',
        'sub'
    ]
  }
  response = client.list_users(**params)
  users = response['Users']
  dict_users = {}
  for user in users:
    attrs = user['Attributes']
    sub    = next((a for a in attrs if a["Name"] == 'sub'), None)
    handle = next((a for a in attrs if a["Name"] == 'preferred_username'), None)
    dict_users[handle['Value']] = sub['Value']
  return dict_users


users = get_cognito_user_ids()

for handle, sub in users.items():
  print('----',handle,sub)
  update_users_with_cognito_user_id(
    handle=handle,
    sub=sub
  )
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ccce5eb6763a11b6fb2a0ccf390b260f06de3afa#diff-b9cea46d48ccc436a251430db1c779e2d42cc47fa379bf1739cc4dea84fed914)  

-----
* Add the script file name into the `db/setup` file, so it runs with every setup  
```sh
source "$bin_path/db/update_cognito_user_ids"
```
------------------
### Implement the conversation with my username instead
* I added myself into the `seed.sql` file  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/3a347d306e584abcf1951a64f6a66c39908d42b7#diff-9f6e4d3465090086912e142a9525b5bce316c4ae0c80d2d572d2f0784409341f)  

* I also updated the conversation in DynamoDB with my username  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/73fd31fa00e59a144fabe913fde3455b2b5451e9)  

* Add `AWS_ENDPOINT_URL` variable into `docker-compose.yml` file  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/6229a0ff618c37235b5914e113ee84d87f6281a2)

-------------------
## Implement (Pattern B) Listing Messages Group into Application
### Create the library
* Inside `backend-flask/lib` Create `ddb.py`  
'' This library with the class "DDb" & functions to be called to get the message groups & messages ''  
[Created file commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-7317e2c6e08a5529dddb7a84d93204446223c7863e791499fc14ea4d4c5b7c60)  

* In `backend-flask/services/message_groups.py`, Replace the mocked data with the below code to get actual user info from cognito  
  ''Here the created scripts earlier **"coginto list users, update cognito user ids"** comes into play!''  
```py

from lib.ddb import Ddb
from lib.db import db

class MessageGroups:
  def run(cognito_user_id):
    model = {
      'errors': None,
      'data': None
    }

    sql = db.template('users','uuid_from_cognito_user_id')
    my_user_uuid = db.query_value(sql,{'cognito_user_id': cognito_user_id})

    print("UUID",my_user_uuid)


    ddb = Ddb.client()
    data = Ddb.list_message_groups(ddb, my_user_uuid)
    print("list_message_groups:",data)
    model['data'] = data
    return model
```
  In order to query the user uuid from cognito user id in the above **"MessageGroups"** Class,  
* Create a sql folder named `users` inside `backend-flask/db/sql`  
* In that `users` folder create `uuid_from_cognito_user_id.sql` with the below  
```sql
SELECT 
  users.uuid
FROM public.users
WHERE 
  users.cognito_user_id = %(cognito_user_id)s
LIMIT 1
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/3a347d306e584abcf1951a64f6a66c39908d42b7#diff-4d24b9af7fc6bdbed01ba2ee2175d13dc45953bd80070ca43efa72009d9d2b58)  

-----
* In `app.py`, Replace the user handle which was hardcoded and call the ***MessageGroup*** class to use the message group uuid instead.  
```py
@app.route("/api/message_groups", methods=['GET'])
def data_message_groups():
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    cognito_user_id = claims['sub']
    model = MessageGroups.run(cognito_user_id=cognito_user_id)
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200

  except TokenVerifyError as e:
    app.logger.debug(e)
    return {}, 401
```
-----
We need to pass the authorization header to be used in these authenticated pages. (Only can be accessed if token is verified)  
Instead of used cookies, We will create authentication checking function to be used.  
* Create a folder named `lib` inside `frontend-react-js/src/`  
* Inside that folder, create `CheckAuth.js` 
```js
import { Auth } from 'aws-amplify';

const checkAuth = async (setUser) => {
    Auth.currentAuthenticatedUser({
      // Optional, By default is false. 
      // If set to true, this call will send a 
      // request to Cognito to get the latest user data
      bypassCache: false 
    })
    .then((user) => {
      console.log('user',user);
      return Auth.currentAuthenticatedUser()
    }).then((cognito_user) => {
        setUser({
          display_name: cognito_user.attributes.name,
          handle: cognito_user.attributes.preferred_username
        })
    })
    .catch((err) => console.log(err));
  };

export default checkAuth
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/759082474b19f959973d0269ae059d50952a7263#diff-716a46d7255bdc7f3c7c1f5f463d4580b0f4dcb288e9027b432ea13e8baebdf9)  

* In `HomeFeedPage.js`, Import that function and pass the `setUser` into `checkAuth`  

* Do the same and pass the authorization header into `MessageGroupPage.js` & `MessageGroupsPage.js`

```js
headers: {
          Authorization: `Bearer ${localStorage.getItem("access_token")}`
        },
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/759082474b19f959973d0269ae059d50952a7263)  

* Pass the header into `MessageForm.js` component as well.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/94548f58d961eaf9a12bd1e948e3e0231385a0f9)  

-----
### Make sure that table already exists  
  We need to make sure that table is created and contains the conversations data in order to view in the messages page.  
  We can check by listing tables  
```sh
./ddb/list-tables
```
If the table doesn't exist, Then create it with the below

* Setup the postgres DB  
```sh
cd backend-flask/bin
./db/setup
```

* Create `cruddur-messages` DynamoDB table and load the schema  
```sh
./ddb/schema-load
```

* Seed the conversation to the table    
```sh
./ddb/seed
```
-----
### Check the conversation in the messages page
![image](https://user-images.githubusercontent.com/105418424/227747568-bd322405-829f-4709-aa48-9a2d25538d4a.png)

Now when we click on the conversation, We could see the other user's handle in the address bar.  
In order to display the **message group uuid** when we hover/click on the conversation:  
* in `frontend-react-js/src/App.js`, Replace the **MessageGroupPage** path as below:  
```js
{
    path: "/messages/:message_group_uuid",
    element: <MessageGroupPage />
  },
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-d95064ed8d1ffc32d8b4ed5cd5a797264a6089d239527f9fa67e60e868600cef)  

-----
* In the `MessageGroupPage.js`, Update the backend url as below:  
```js
const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/messages/${params.message_group_uuid}`
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-7932be144100c97223bc212a13afa0b412f89e80ec7d3691a5901066a2765325)  

-----
* In the `MessageGroupItem.js`, Update the link to use message group uuid instead of message group handle.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-6bec63d52c2e376a0310a30646efb11c194c7f1b39e725d8ed22aa7e04c0ce5a)  

-----
## Implement (Pattern A) Listing Messages in Message Group into Application
### Now to see the conversation messages:  

* In the `backend-flask/app.py` update the **"messages"** part as below:  

```py
@app.route("/api/messages/<string:message_group_uuid>", methods=['GET'])
def data_messages(message_group_uuid):
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    cognito_user_id = claims['sub']
    model = Messages.run(
        cognito_user_id=cognito_user_id,
        message_group_uuid=message_group_uuid
      )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
```
  '' This will update the messages route with the required message group uuid and check for authentication as well ''  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-0014cc1f7ffd53e63ff797f0f2925a994fbd6797480d9ca5bbc5dc65f1b56438)  

-----
* In `backend-flask/services/Messages.py`, Replace the mocked data with the below:
  
```py
from datetime import datetime, timedelta, timezone
from lib.ddb import Ddb
from lib.db import db
class Messages:
  def run(message_group_uuid, cognito_user_id):
    model = {
      'errors': None,
      'data': None
    }
    sql = db.template('users','uuid_from_cognito_user_id')
    my_user_uuid = db.query_value(sql,{'cognito_user_id': cognito_user_id})

    print("UUID",my_user_uuid)
    
    ddb = Ddb.client()
    data = Ddb.list_messages(ddb, message_group_uuid)
    print("list_messages")
    print(data)

    model['data'] = data
    return model
```
  '' To query the user uuid using the cognito user id & list the messages using the message group uuid ''  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f1e710ca783fa085b830143cad537bcf439ce25e#diff-0b927f7a12e56071b3dce9217e14e3a9b612c0a9d7b85f059fe269416cca0bcb)  

-----
### Check the conversation messages

![image](https://user-images.githubusercontent.com/105418424/227748873-d2dd68e0-0b65-4ee0-ad95-f1005b81c8fb.png)

-----
## Implement (Pattern C) Creating a Message for an existing Message Group into Application

  In the `MessageForm.js`, we are using a logic to check the user handle if it's existing so it updates the message group.  
And if the user handle doesn't exist, It will create a new conversation.  

* In `MessageForm.js` update with the below  
```js
import { json, useParams } from 'react-router-dom';
```
  If that handle does exist, we'll use that handle to create the new conversation.  
  If we have the message group uuid, we'll update the message group "technically 2 message groups".  
```js
let json = { 'message': message }
      if (params.handle) {
        json.handle = params.handle
      } else {
        json.message_group_uuid = params.message_group_uuid
      }
```
  Pass this json into the body.  
```js
body: JSON.stringify(json)
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-7cf22502ee0acb0e53dcb9131f62f9074c7232526249db46d5d2d32c11af1633)  

-----
* In `app.py` update the ***messages*** post method as below  
```py
@app.route("/api/messages", methods=['POST','OPTIONS'])
@cross_origin()
def data_create_message():
  message_group_uuid   = request.json.get('message_group_uuid',None)
  user_receiver_handle = request.json.get('handle',None)
  message = request.json['message']
  access_token = extract_access_token(request.headers)
  try:
    claims = cognito_jwt_token.verify(access_token)
    # authenicatied request
    app.logger.debug("authenicated")
    app.logger.debug(claims)
    cognito_user_id = claims['sub']
    if message_group_uuid == None:
      # Create for the first time
      model = CreateMessage.run(
        mode="create",
        message=message,
        cognito_user_id=cognito_user_id,
        user_receiver_handle=user_receiver_handle
      )
    else:
      # Push onto existing Message Group
      model = CreateMessage.run(
        mode="update",
        message=message,
        message_group_uuid=message_group_uuid,
        cognito_user_id=cognito_user_id
      )
    if model['errors'] is not None:
      return model['errors'], 422
    else:
      return model['data'], 200
  except TokenVerifyError as e:
    # unauthenicatied request
    app.logger.debug(e)
    return {}, 401
```
-----
* In the `create_message.py`, Replace the code with the below  
```py
from datetime import datetime, timedelta, timezone

from lib.db import db
from lib.ddb import Ddb

class CreateMessage:
  # mode indicates if we want to create a new message_group or using an existing one
  def run(mode, message, cognito_user_id, message_group_uuid=None, user_receiver_handle=None):
    model = {
      'errors': None,
      'data': None
    }

    if (mode == "update"):
      if message_group_uuid == None or len(message_group_uuid) < 1:
        model['errors'] = ['message_group_uuid_blank']


    if cognito_user_id == None or len(cognito_user_id) < 1:
      model['errors'] = ['cognito_user_id_blank']

    if (mode == "create"):
      if user_receiver_handle == None or len(user_receiver_handle) < 1:
        model['errors'] = ['user_reciever_handle_blank']

    if message == None or len(message) < 1:
      model['errors'] = ['message_blank'] 
    elif len(message) > 1024:
      model['errors'] = ['message_exceed_max_chars'] 

    if model['errors']:
      # return what we provided
      model['data'] = {
        'display_name': 'Andrew Brown',
        'handle':  user_sender_handle,
        'message': message
      }
    else:
      sql = db.template('users','create_message_users')

      if user_receiver_handle == None:
        rev_handle = ''
      else:
        rev_handle = user_receiver_handle
      users = db.query_array_json(sql,{
        'cognito_user_id': cognito_user_id,
        'user_receiver_handle': rev_handle
      })
      print("USERS =-=-=-=-==")
      print(users)

      my_user    = next((item for item in users if item["kind"] == 'sender'), None)
      other_user = next((item for item in users if item["kind"] == 'recv')  , None)

      print("USERS=[my-user]==")
      print(my_user)
      print("USERS=[other-user]==")
      print(other_user)

      ddb = Ddb.client()

      if (mode == "update"):
        data = Ddb.create_message(
          client=ddb,
          message_group_uuid=message_group_uuid,
          message=message,
          my_user_uuid=my_user['uuid'],
          my_user_display_name=my_user['display_name'],
          my_user_handle=my_user['handle']
        )
      elif (mode == "create"):
        data = Ddb.create_message_group(
          client=ddb,
          message=message,
          my_user_uuid=my_user['uuid'],
          my_user_display_name=my_user['display_name'],
          my_user_handle=my_user['handle'],
          other_user_uuid=other_user['uuid'],
          other_user_display_name=other_user['display_name'],
          other_user_handle=other_user['handle']
        )
      model['data'] = data
    return model
```
'' In this file we will check the mode if its *update* or *create* message groups, also using *sql template* to get conversation usres and *Ddb* class functions for creating messages''  

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-373640fe5e16546a1a5366784e1b68515e757157d250910f0c5319bfe628adc0)  

-----
  Create sql template to get the conversation users  
* Create new sql file named `create_message_users.sql` inside `backend-flask/db/sql/users`  
```sql
SELECT 
  users.uuid,
  users.display_name,
  users.handle,
  CASE users.cognito_user_id = %(cognito_user_id)s
  WHEN TRUE THEN
    'sender'
  WHEN FALSE THEN
    'recv'
  ELSE
    'other'
  END as kind
FROM public.users
WHERE
  users.cognito_user_id = %(cognito_user_id)s
  OR 
  users.handle = %(user_receiver_handle)s
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/501ddcd6b8b76f6c2307a125646da937252db97d#diff-14f77ecb016f389d519df46e330c7881e1f69337e8f5685b3cbde93a297a4872)  

-----
* In `lib/ddb.py` insert the below code for creating messages and message groups functions  
```py
def create_message(client,message_group_uuid, message, my_user_uuid, my_user_display_name, my_user_handle):
      now = datetime.now(timezone.utc).astimezone().isoformat()
      created_at = now
      message_uuid = str(uuid.uuid4())

      record = {
        'pk':   {'S': f"MSG#{message_group_uuid}"},
        'sk':   {'S': created_at },
        'message': {'S': message},
        'message_uuid': {'S': message_uuid},
        'user_uuid': {'S': my_user_uuid},
        'user_display_name': {'S': my_user_display_name},
        'user_handle': {'S': my_user_handle}
      }
      # insert the record into the table
      table_name = 'cruddur-messages'
      response = client.put_item(
        TableName=table_name,
        Item=record
      )
      # print the response
      print(response)
      return {
        'message_group_uuid': message_group_uuid,
        'uuid': my_user_uuid,
        'display_name': my_user_display_name,
        'handle':  my_user_handle,
        'message': message,
        'created_at': created_at
      }
  
def create_message_group(client, message,my_user_uuid, my_user_display_name, my_user_handle, other_user_uuid, other_user_display_name, other_user_handle):
    print('== create_message_group.1')
    table_name = 'cruddur-messages'

    message_group_uuid = str(uuid.uuid4())
    message_uuid = str(uuid.uuid4())
    now = datetime.now(timezone.utc).astimezone().isoformat()
    last_message_at = now
    created_at = now
    print('== create_message_group.2')

    my_message_group = {
      'pk': {'S': f"GRP#{my_user_uuid}"},
      'sk': {'S': last_message_at},
      'message_group_uuid': {'S': message_group_uuid},
      'message': {'S': message},
      'user_uuid': {'S': other_user_uuid},
      'user_display_name': {'S': other_user_display_name},
      'user_handle':  {'S': other_user_handle}
    }

    print('== create_message_group.3')
    other_message_group = {
      'pk': {'S': f"GRP#{other_user_uuid}"},
      'sk': {'S': last_message_at},
      'message_group_uuid': {'S': message_group_uuid},
      'message': {'S': message},
      'user_uuid': {'S': my_user_uuid},
      'user_display_name': {'S': my_user_display_name},
      'user_handle':  {'S': my_user_handle}
    }

    print('== create_message_group.4')
    message = {
      'pk':   {'S': f"MSG#{message_group_uuid}"},
      'sk':   {'S': created_at },
      'message': {'S': message},
      'message_uuid': {'S': message_uuid},
      'user_uuid': {'S': my_user_uuid},
      'user_display_name': {'S': my_user_display_name},
      'user_handle': {'S': my_user_handle}
    }

    items = {
      table_name: [
        {'PutRequest': {'Item': my_message_group}},
        {'PutRequest': {'Item': other_message_group}},
        {'PutRequest': {'Item': message}}
      ]
    }

    try:
      print('== create_message_group.try')
      # Begin the transaction
      response = client.batch_write_item(RequestItems=items)
      return {
        'message_group_uuid': message_group_uuid
      }
    except botocore.exceptions.ClientError as e:
      print('== create_message_group.error')
      print(e)
```

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-7317e2c6e08a5529dddb7a84d93204446223c7863e791499fc14ea4d4c5b7c60)  

-----
### Test create message in existing conversation
![image](https://user-images.githubusercontent.com/105418424/227779787-01896608-c591-47d4-8ed2-8e64517ceed7.png)

## Implement (Pattern D) Creating a Message for a new Message Group into Application

  To create new conversation, we will need a new conversation URL (eg. /messages/new/handle)  

* In `frontend-react-js/src/App.js` add this new element  
```js
import MessageGroupNewPage from './pages/MessageGroupNewPage';
```
```js
{
    path: "/messages/new/:handle",
    element: <MessageGroupNewPage />
  },
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-d95064ed8d1ffc32d8b4ed5cd5a797264a6089d239527f9fa67e60e868600cef)  

-----
* Create this new page file inside `frontend-react-js/src/pages`  

File link
[MessageGroupNewPage.js](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/src/pages/MessageGroupNewPage.js)

[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-19e1c41053ae4fc921364047da3f3c2e049950392fd522cbd1605a57ded7312b)  

-----
  In order to load the an example conversation data we created a new user  
  Andrew chose Londo Mollari, so I created the user with the same name!  

* In `backend-flask/db/seed` add the new user into public users  
```sql
('Londo Mollari', 'lmollari', 'lmollari@centri.com', 'MOCK');
```

* Add the user into the database  
```sh
./backend-flask/bin/db/connect
INSERT INTO public.users (display_name, handle, email, cognito_user_id) VALUES ('Londo Mollari', 'lmollari', 'lmollari@centri.com', 'MOCK');
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/501ddcd6b8b76f6c2307a125646da937252db97d#diff-9f6e4d3465090086912e142a9525b5bce316c4ae0c80d2d572d2f0784409341f)  

-----
  To create a new endpoint with user's handle, Create new service named `short`  

* In `backend-flask/services`, Create new file `users_short.py`  
```py
from lib.db import db

class UsersShort:
  def run(handle):
    sql = db.template('users','short')
    results = db.query_object_json(sql,{
      'handle': handle
    })
    return results
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-e1179c4e25e965f23a5be83169acf2f974ba9b96d7642f092939f8e5e0ced049)  

-----
* In `backend-flask/db/sql/users`, Create `short.sql`
```sql
SELECT
  users.uuid,
  users.handle,
  users.display_name
FROM public.users
WHERE 
  users.handle = %(handle)s
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/501ddcd6b8b76f6c2307a125646da937252db97d#diff-1d1b7abf89f7eb5485f8890c449e5ed533cbeaf98c745d4060a8098a667c53e4)  

-----
* In `app.py`, Add the below  
```py
from services.users_short import *
```
```py
@app.route("/api/users/@<string:handle>/short", methods=['GET'])
def data_users_short(handle):
  data = UsersShort.run(handle)
  return data, 200
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-0014cc1f7ffd53e63ff797f0f2925a994fbd6797480d9ca5bbc5dc65f1b56438)  

-----
* In `frontend-react-js/src/components`, Create `MessageGroupNewItem.js`  
```js
import './MessageGroupItem.css';
import { Link } from "react-router-dom";

export default function MessageGroupNewItem(props) {
  return (

    <Link className='message_group_item active' to={`/messages/new/`+props.user.handle}>
      <div className='message_group_avatar'></div>
      <div className='message_content'>
        <div className='message_group_meta'>
          <div className='message_group_identity'>
            <div className='display_name'>{props.user.display_name}</div>
            <div className="handle">@{props.user.handle}</div>
          </div>{/* activity_identity */}
        </div>{/* message_meta */}
      </div>{/* message_content */}
    </Link>
  );
}
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-d39016ce3b17b463ed36bf8d10e4ba9c6fb4734f860e4a5a2835940b0be410a6)  

-----
* In `MessageGroupFeed.js` add the below:  
```js
import MessageGroupNewItem from './MessageGroupNewItem';
```
```js
let message_group_new_item;
  if (props.otherUser) {
    message_group_new_item = <MessageGroupNewItem user={props.otherUser} />
  }
```
```js
{message_group_new_item}
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-ba948fa304b10339e030774135fd2c160b613d8d91e9309ea16aec9012246170)  

-----
* Update `MessageForm.js` with the below if the status == 200  
```js
console.log('data:',data)
        if (data.message_group_uuid) {
          console.log('redirect to message group')
          window.location.href = `/messages/${data.message_group_uuid}`
        } else {
          props.setMessages(current => [...current,data]);
        }
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9d90784ced87a15eae0c2008401f4691b06a00aa#diff-7cf22502ee0acb0e53dcb9131f62f9074c7232526249db46d5d2d32c11af1633)  

-----
### Test create message for new message group

![new message](https://user-images.githubusercontent.com/105418424/227783819-b13f039c-9c39-4524-bc0e-9d507cd66ec1.JPG)

## Implement (Pattern E) Updating a Message Group using DynamoDB Streams

### Update ddb schema-load script
  Before creating our prod DynamoDB table, Update `backend-flask/bin/ddb/schema-load` to add GSI.  
* In the *AttributeDefinitions*:
```sh
{
      'AttributeName': 'message_group_uuid',
      'AttributeType': 'S'
    },
```
```sh
GlobalSecondaryIndexes=[{
    'IndexName':'message-group-sk-index',
    'KeySchema':[{
      'AttributeName': 'message_group_uuid',
      'KeyType': 'HASH'
    },{
      'AttributeName': 'sk',
      'KeyType': 'RANGE'
    }],
    'Projection': {
      'ProjectionType': 'ALL'
    },
    'ProvisionedThroughput': {
      'ReadCapacityUnits': 5,
      'WriteCapacityUnits': 5
    },
  }],
```
* Create DynamoDB prod table  
```sh
cd backend-flask
./bin/ddb/schema-load prod
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/7545bfb6ad5acdb8eaab8ef7aab3c5b04896de45)  

---
### Turn on stream
* In the DynamoDb management console page:
* Click ***"Exports and streams"*** tab and turn on streams on the table with 'new image' attributes included.

![dynamodb-table](https://user-images.githubusercontent.com/105418424/227801815-6dbe5046-f229-497f-9200-b5ad2f6e6280.png)

---
### Create VPC Gateway Endpoint
* From VPC Page in management console, Click ***"Endpoints"*** then create a VPC endpoint named `ddb-cruddur1`  
* From services choose ***"dynamodb"*** (com.amazonaws.us-east-1.dynamodb)  
* Then choose the VPC (the default one in my case)  

![VPC-endpoint](https://user-images.githubusercontent.com/105418424/227800774-4179903f-f543-4b5c-976e-31b7a8630e2b.png)

---
### Create Lambda function
* Create a new Lambda function named `cruddur-messaging-stream`  
* Choose runtime "Python 3.9"  
* By default a new IAM Role will be created with the same name of Lambda function "Will add permissions later"  
* In ***"Advanced Settings"*** choose ***"Enable VPC"*** choose the VPC, subnets and the security group  
* From ***"Configuration"*** tab choose ***"Permissions"*** then click on the IAM Role  
* Click ***"Add permissions"*** then ***"Attach policy"*** and choose the ***"AWSLambdaInvocation-DynamoDB"***
* We will need additional permissions, so again click ***"Add permissions"*** then ***"Create inline policy"***
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "dynamodb:PutItem",
                "dynamodb:DeleteItem",
                "dynamodb:Query"
            ],
            "Resource": [
                "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT_ID}:table/cruddur-messages",
                "arn:aws:dynamodb:us-east-1:${AWS_ACCOUNT_ID}:table/cruddur-messages/index/message-group-sk-index"
            ]
        }
    ]
  }
```
  '' The Resource name differs from one to another depending on **Region** and **AWS Accound ID** ''  
Following along with Andrew, I created a new folder `aws/policies` and created the policy file `cruddur-message-stream-policy.json`  
Also created a new file `cruddur-messaging-stream.py` in `aws/Lambdas` for the new Lambda function   

Now the function has the appropriate permissions for DynamoDB

* The function
```py
import json
import boto3
from boto3.dynamodb.conditions import Key, Attr

dynamodb = boto3.resource(
 'dynamodb',
 region_name='us-east-1',
 endpoint_url="http://dynamodb.us-east-1.amazonaws.com"
)

def lambda_handler(event, context):
  print('event-data',event)

  eventName = event['Records'][0]['eventName']
  if (eventName == 'REMOVE'):
    print("skip REMOVE event")
    return
  pk = event['Records'][0]['dynamodb']['Keys']['pk']['S']
  sk = event['Records'][0]['dynamodb']['Keys']['sk']['S']
  if pk.startswith('MSG#'):
    group_uuid = pk.replace("MSG#","")
    message = event['Records'][0]['dynamodb']['NewImage']['message']['S']
    print("GRUP ===>",group_uuid,message)
    
    table_name = 'cruddur-messages'
    index_name = 'message-group-sk-index'
    table = dynamodb.Table(table_name)
    data = table.query(
      IndexName=index_name,
      KeyConditionExpression=Key('message_group_uuid').eq(group_uuid)
    )
    print("RESP ===>",data['Items'])
    
    # recreate the message group rows with new SK value
    for i in data['Items']:
      delete_item = table.delete_item(Key={'pk': i['pk'], 'sk': i['sk']})
      print("DELETE ===>",delete_item)
      
      response = table.put_item(
        Item={
          'pk': i['pk'],
          'sk': sk,
          'message_group_uuid':i['message_group_uuid'],
          'message':message,
          'user_display_name': i['user_display_name'],
          'user_handle': i['user_handle'],
          'user_uuid': i['user_uuid']
        }
      )
      print("CREATE ===>",response)
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9f2989647412a453ff18b8aef4066087af73f655)  

---
### Create a trigger in DynamoDB
* In the DynamoDb management console page:  
* Click ***"Exports and streams"*** tab and create a trigger  
* Choose the **cruddur-messaging-stream** function  

---
### Create a new message and check
* Create a new message and check if Lambda was triggered and items into the DynamoDB ***"cruddur-messages"*** table.  
  '' To create a new message: After clicking the **messages** tab, Append `new/{the other user handle}` in the address bar '' 

![new-message-prod](https://user-images.githubusercontent.com/105418424/227801910-71aff888-bd25-4f84-b6fc-a0acdeb1ec44.png)

  CloudWatch logs shows no errors!
![image](https://user-images.githubusercontent.com/105418424/227802878-2d93134a-3c20-421b-9e8d-3a600b4b640f.png)

DynamoDB Table items
![image](https://user-images.githubusercontent.com/105418424/227802155-b779e5fe-df05-44a1-8ea5-48ce05fec14f.png)