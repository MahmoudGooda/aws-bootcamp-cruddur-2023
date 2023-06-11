# Week X

### In this week we are finishing our app configurations and functionality

## Building the static frontend app  
* Create **"static-build"** script  ***"bin/frontend/static-build"***  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/f049df764f7c623e56fad3a80f0c119caaea5c91) )  

  '' After running the **"static-build"** script, I found multiple reported warnings, and started debugging for the frontend components ''  
     [Commit link for debugging the frontend problems](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/082928fc55b103ef821983afb43d6b5fe426e9e4).   
      [and this commit as well](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/0c69ee29e069517faac74a4d8ac25d697dde874b).  
 
* Run the build command (including the variables) locally, Then a **"build"** folder should be generated in the ***frontend-react-js*** folder.  
* Zip the **build** folder.  
```sh
zip -r build.zip build/
```
* Upload the folder contents into <your_domain> S3 bucket.  
  
  ![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/a475fcec-8d0d-4366-abd1-990d3f80e23c)

---
### Create sync tool  
* Install dependencies  
```sh
cd /workspace
gem install aws_s3_website_sync dotenv
```
* Create ***"bin/frontend/sync"*** script file  
* Update ***"bin/frontend/generate-env"*** with ***sync*** to generate sync.env file as well  
  ( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1bb94c439b3adc9ee5edcaafb2ab7d9646c2db7b) )  
* Create ***"/erb/sync.env.erb"*** --> '' This file will be used to generate environment variables from ''  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2503df7f60a3a913f51c28c37beac766707dc9c7) )  

* Now let's update anything in the code (the About button), then use sync tool to sync this change and check.  

  ![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/154f97a5-97b4-4687-9499-7b18b091ed64)

---
## Automate sync process
  Following along with Andrew, we will use Github Actions to automate the frontend sync process  
  but unfortunately we didn't have time to completely finish it  
* Create ***"workspace/Rakefile"*** & ***"workspace/Gemfile"***  
* Create the workflow file ***"github/workflows/sync.yaml.example"***  
  ( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/51e31eeeeac38907cad280707fa54e25af629260) )  
* Create sync role CFN template and deploy script  
  - Create ***"aws/cfn/sync/template.yaml"***  
  - Create ***"aws/cfn/sync/config.toml"***  
  - Create ***"bin/cfn/sync"***  
  ( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/54ef0a9dea06e2893d5f5179b931a17833d3afab) )  
* Deploy the CFN stack, then from AWS console, update the role permissions with (get-object, list bucket, put object, delete object) on <your_domain> bucket for all objects  
You can find the policy [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e5359e684104ab8fd8b9808c8bbabf3a93c4fd9d)  

---
### Update the app to work as SPA (Single Page Application)
  We will update CloudFront resource with ***Custom Error Response*** to allow CloudFront to redirect requests to the main page regardless of error code.  

* update the Distribution ***"aws/cfn/frontend/template.yaml"***  
 ```yml
    CustomErrorResponses:
  - ErrorCode: 403
    ResponseCode: 200
    ResponsePagePath: /index.html
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/69cecda87f2429f874338fdf60bd8844768c9544)  

* Make sure that **post-confirmation** lambda function has the correct ***DB CONNECTION_URL*** for RDS  
* Create ***CognitoLambdaSG*** for post-confirmation lambda to access RDS & Update ***RDSSG*** inbound rules to accept traffic from it  
* Update the lambda configuration with correct VPC (***CRDNET***), subnets(***PUB***), and security group (***CognitoLambdaSG***)  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/fc371074-f1e9-473a-8da5-f1efb8a28ed5)

* SignUp a new user to test  
* Update activities creation app components not to use hardcoded values  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/8b24d3499d35f29216153f344a15d68f4442d7a9) )  
* Post a new Crud with the other user & check

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/e1416e6f-b2bf-41eb-83d1-24d4bd017700)

---
## Testing CodePipeline
### Pull request to prod and check if pipeline triggered successfully

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/bed105d8-b549-4fa7-a3c0-a5d986cc9722)

---
## Refactor the reply popup window  
* Update for ***ReplyForm.js*** to be able to close reply popup  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/31776bfb23d55ddc0f0882f51faef6884c4a43ae) )  

---
## Setup decorator to handle JWT verification
* Add the function to `cognito_jwt_token.py`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e4ce167e04c5e1e2003d55b50ce091e4ee608c12) )  

* Update the endpoints in `app.py` with the decorator  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/8f5e54b1e5e0f26fddabd1ff8273f376852cd78d) )  

---
## Authentication in ***NotificationsFeed.js***  
* Refactor Authentication in `NotificationsFeed.js` page  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/0323f417043865b43c976e58cb277d4128c61dd0) )  

---
## Refactor Backend ***app.py***

* To make the code more simpler, Created functions libraries and imported them into `app.py`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/fbcdd73e30481d3f3ec2dad22d05399f26f9e4de) )  

* Create model function in file ***"backend-flask/lib/helpers.py"***, then import it in `app.py`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/517dc318189f853807ba477fbbfd209b8454c2ed) )  
* Create routes for endpoints  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dbd33d86d42701b3c20481d743b67d67255416fc) )  

* The `app.py` file after refactor after defining routes [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/75bde4a005b9cff9b36273a2683852ba7a011645)  

---
## Refactor Reply Form
### Instead of hardcoded data, this will query & use the cognito user id in replies
* Update `ReplyForm.js` with Authorization token  
* Update `create_reply.py` to replace user handle with cognito user id & with create reply function  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/56358a8345fa8f94dafe9847fda10030f77b5bf5) )  
  
### Create Reply SQL command and add the replies into activities
* Create ***"backend-flask/db/sql/activities/reply.sql"***  
* Add ***"reply_to_activity_uuid"*** to `object.sql` & `home.sql`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1fe5acc114f6102be45c77fc431cea8a0350f2b8) )  

* Generate the migration (reply_to_activity_uuid):  
  - updated migration scripts in [this commit here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/3d283aad5c06d8623bda3680fd520b6a01f750db)  
  - and fixed the ***migrate*** script in [this commit here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ca5df6b0fa668ebf7afaf30de284ec039f5fda05)  
* Update it to convert the table column from integer to UUID:  
  - The generated migration file link [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/backend-flask/db/migrations/16851097583405812_reply_to_activity_uuid.py)  
* Run the ***"migrate"*** script and the table type should be changed to "uuid"  
  - I faced an error & I had to update the ***"last_successful_run"*** with the generated migration value manually in order to get the migration work.  
  
  ![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/7fbb8595-b3de-450a-956a-c6f33765ef0a)

* Update `activityitem.js` & `activityitem.css` for better reply styles  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1b87b18b9c925f6e251711645ed2d37355ee5510) )  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/39e3f7ff-7d05-4684-b579-e42cbf212d01)

---
## Home activities page updates
* Update `ActivityFeed.js` & `ActivityFeed.css` to show **"Nothing"** message if there's no posts.  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/cf16f1fad986dcbe409e0ef5a4e1d39e4666a401) )  
* Create ***"backend-flask/db/sql/activities/show.sql"*** query  
* Update `home.sql` query  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/19a3b3999386df5f79ff5155f7447a15870ac236) )  

---
## Implement Error Handling
Inside ***"frontend-react-js/src/components"***  
  - Create `FormErrors.js` / `FormErrorsItem.js` / `FormErrors.css`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dcc30db400b9a14aa7ed2ba493b3a40fe8e5a4b0) )  

Inside ***"frontend-react-js/src/lib"***  
* Create `Requests.js` to contain the requests & then import it in the forms   
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2f10d7032b24c1983267f732c3d06b8b20fb0ac7) )  

Now update the frontend pages & components with the imported requests from our created library to get them more cleaner  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9e1e5e22fb294b770ebed36a73068957dced5a8d) )  

---
## Refining Activities and Replies
* Update `ActivityContent.js` & `ActivityContent.css` to convert displayname, username, and avatar into clickable links when we hover on them  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/516f018f849e63a47d687bee2c6e0b3b6339d61f) )  

* Update `ActivityItem.js` make the post clickable   & `ActivityItem.css` to change opacity when hovering on it  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/638f9d449d58c7f425345c851aa493307beab2c7) )  

* Update Activity actions (Like, Reply, Repost, Share) to exclude them from redirection when clicking on post  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/38f1dea3a3bd128724582e8f7999bd5e09a51796) )  

* Create `Replies.js` & `Replies.css` components  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dbd54dbc98952d23fe7bce1b875c30733e68ad47) )  

* Create `ActivityShowPage.js` Page & `ActivityShowPage.css`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/862348f156e6c16cd80ed129f63aeda02ddf9965) )  
  Then updated `ActivityShowPage.js` with the following  
  - Update the clicked crud title ( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/fea5f6d973c306dc3db9b2a260bd5718bd47be8f) )  
  - Add back button in the crud ( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/8ed096aeb65667f2f879f86bb6c3b75ff9531341) )  

* Update `App.js` with **activity_uuid** route  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/a4b832c779eebc14774ac8977557b6df8dbc5ad0) )  

* Update ***"/backend-flask/routes/users.py"*** with this **activity show**  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/216e1080c279f01ec66b71b40ea8bbb7000d282f) )  

* Update ***"/backend-flask/services/show_activity.py"*** with **activity_uuid instead** of hardcoded values  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ac24aa394dbf7da74ae85c843590b2c80c21e499) )  

* Update activity structure in ***"backend-flask/db/sql/activities/show.sql"***  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/7b7c8018ebd92342d7c75572dcbd69a95e2003fc) )  


* Update `seed.sql` with a post by the other user  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ac7482ab05fb39fae33a4c59fa4852a15b39057f) )  

* Apply the default undefined avatar picture  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ca93501828006b0fafc9d678c7806a7c277f6866) )  

* Fix the replies to show correctly under posts  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e6cd7a7ca81f7a6fa79070c755f83499cad4c84a) )  

---
## Updating with production databases
* Run the migration on prod DB to convert the table column "reply to activity" from integer to UUID  

* Update `ddb.py` with the prod table name  
* Add ***DDB_MESSAGE_TABLE*** value into `backend-flask.env.erb`  
* Add the table name created by CFN from AWS console into `backend-flask.env`  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5232b411d7948ccef1f73007a751e93df1428b7c#diff-b39ff238ff5330c9754edc914ff0f1c99a02f7c72b09fd8b7db1d788bb3ef16d) )  

---
### Now let's test the messaging system between our two users!
* Send a message to the other user and check if it’s inserted into DDB?  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/ea7263e3-69b5-4403-837f-63987060480d)  

---
* Update the DDB Table name variable for production fargate service ***"service/template.yaml & config.toml"***  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/4b215ddabdb16a685553d2f9c58c6be98e6ef796) )  

### Let's re-deploy the service stack and check the new DDB variable in task definition  

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/8bfff44e-077d-483b-afd5-373ffa985590)

---
### Create machine-user with appropriate permissions on DynamoDB
  We will use this user for actions on DynamoDB, "This is also good from security perspective to use it instead of our development IAM user who has admin rights"  

* Create ***"aws/cfn/machine-user/template.yaml"***  
* Create ***"aws/cfn/machine-user/config.toml"***  
* Create ***"bin/cfn/machineuser"***  
( [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/209984d0b8bca0a1b9e974feb765f13fbd5a6c3c) )  

* Manually create Access keys for the created machine user then update ***"/cruddur/backend-flask/AWS_ACCESS_KEY_ID"*** value in parameter store with it  

### Messages are now rendered successfully!

![image](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/assets/105418424/220e8c92-0718-4b49-ad6a-653336ba2585)

