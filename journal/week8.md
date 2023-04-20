# Week 8 — Serverless Image Processing

## Implement CDK Stack

Create a new folder in our main project root folder, the folder will be named `thumbing-serverless-cdk`.  
```sh
cd /workspace/aws-bootcamp-cruddur-2023
mkdir thumbing-serverless-cdk
```
Install `aws-cdk` and `dotenv` packages.  
```sh
cd thumbing-serverless-cdk
npm install aws-cdk -g
npm install dotenv
```
  '' in order to get the package installed automatically with workspace initializations, I added the below instructions to my `.gitpod.yml` ''  
```yml
    before: |
      npm install aws-cdk -g
      cd thumbing-serverless-cdk
      npm i
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/6afc23ce2405164c68046bcb8dfd8dc8c3cbe0e7)  

---
Initialize AWS CDK.  
```sh
cdk init app --language typescript
```
Run cdk bootstrap to provision resources for the AWS CDK before we deploy out AWS CDK Stack ([Refrence](https://docs.aws.amazon.com/cdk/v2/guide/bootstrapping.html)).  
```sh
cdk bootstrap "aws://${AWS_ACCOUNT_ID}/${AWS_DEFAULT_REGION}"
```
![image](https://user-images.githubusercontent.com/105418424/233470823-69fee96e-a976-40ae-878a-41f1e0f4ddd8.png)
Create `.env.example` file for storing variables, then run `cp .env.example .env`.  
  '' the .example file for our reference and the .env file which the vars will retrieved from, and will not be pushed to the repo ''  
Here's my [.env.example file](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/thumbing-serverless-cdk/.env.example).  

Create Lambda function for processing uploaded images into a specific dimension.  
  `/workspace/aws-bootcamp-cruddur-2023/aws/Lambdas/process-images`  

Install `sharp` and `@aws-sdk/client-s3` packages.  
```sh
cd aws/Lambdas/process-images
npm init -y
npm install sharp @aws-sdk/client-s3
```
Create `bin/avatar/build` script for installing packages in the thumbing folder.  
Run the build script. ([Function files & related package commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e7b328e19cc77b9ab00a9ba6e14d3eeeb6865009))  

Create a S3 bucket named `assets.<domain_name>`.  
Create a folder named `banners`, and then upload any banner you want named `banner.jpg` into that folder.

Create bash scripts for uploading & clearing our `uploads` bucket items. ([S3 bash scripts folder](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/tree/main/bin/avatar)).  
Run the upload script & check if the lambda function has created the processed images!  

Don't forget to set the below env vars which will be created by CDK (use your names).  
```sh
export UPLOADS_BUCKET_NAME="<domain_name>-uploaded-avatars"
export ASSETS_BUCKET_NAME="assets.<domain_name>"
export THUMBING_S3_FOLDER_INPUT=""
export THUMBING_S3_FOLDER_OUTPUT="avatars"
export THUMBING_WEBHOOK_URL="https://api.<domain_name>/webhooks/avatar"
export THUMBING_TOPIC_NAME="cruddur-assets"
export THUMBING_FUNCTION_PATH="/workspace/aws-bootcamp-cruddur-2023/aws/Lambdas/process-images"
```

You can find my last updated `thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts` [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/thumbing-serverless-cdk/lib/thumbing-serverless-cdk-stack.ts).  

Create the CDK Stack.  
  - run `cdk synth` and check the `cd.out` json files to check the stack resources before creation.  
  - run `cdk deploy` to deploy the stack.
check the ***cloudformation*** console for the created stack, resources.  

![image](https://user-images.githubusercontent.com/105418424/233229711-b4ac1044-0a56-4999-878e-9cb660ed50de.png)

---
## Serve Avatars via CloudFront

### From the AWS CloudFront console, Create new distribution.  
* Origin domain: `your ASSETS_BUCKET_NAME`.  
* Origin access: `Origin access control settings (recommended)` and choose your assets bucket name from the drop-down menu "If not, create control setting".  
* Viewer protocol policy: `Viewer protocol policy`.  
* Cache policy: ` CachingOptimized` - Origin request policy: `CORS-CustomOrigin`  - Response headers policy: `SimpleCORS`.  
* Alternate domain name (CNAME): `Add item` then enter `assets.<your_domain_name>`.  
* Custom SSL certificate: select the SSL certificate requested from ACM.  
  '' Don't forget to copy the CDN created policy and add it to your assets bucket policy ''  

### Create Route53 record in hostedzone
* Record name: `assets.<domain_name>`.  
* Select ***Alias*** and Route traffic to Alias to CloudFront distribution then choose the created Cloudfront dist. created earlier.

  To ensure that CloudFront will always display the latest avatar uploaded by the user. I created an invalidation as below: 
  (thanks to [beiciliang](https://github.com/beiciliang) for that recommendation!)  

* Go to the distribution we created.  
* Under the Invalidations tab, click create.  
* Add object path /avatars/*.  
---
## Implement Users Profile Page

  Since the profile page has a mocked data, we need to implement this page to show real users data 
  
* Create new db query `show.sql` in `backend-flask/bd/sql/users` to get user data shown in the profile page.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/73d8eacfaf37878d28fda389532ba027015ce3bd)  

* Update `"users_activities.py"` to return the users from db query.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/13c96efac056756c356ebe87702b70f172619cd1)  

* Split the profile heading into a separate file and import it in `UserFeedPage.js`.  
  * Create `ProfileHeading.js` & `ProfileHeading.css` components.  
  * Update `UserFeedPage.js` to set the structure of data shown to be in (user activities) and (profile) and also to show DesktopNaviagtion items correctly when logged     in using checking auth implementation.    
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/737751b52536e1a896b5656eeadef6e839b81836)  
  * Corrected ClassName in `ProfileHeading.js` in [this commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dbf57940555c3a9d421d5f2fab016933c94f1a49)  

* Create `EditProfileButton.js` & `EditProfileButton.css` components.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/6a3cb76059a8d9b4611417528fd777088bce6498)  

* Update activity feed heading in `ActivityFeed.js`, `HomeFeedPage.js`, `NotificationsFeedPage.js`.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/581df1e09e8c182d1b8d897221fcab7cf34d5717)  

* To improve flexibility in reorganizing items in `src` folder:  
  - Create `jsconfig.json` inside `frontend-react-js` folder.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/794673b273e21454ae2b1f11ff1a442754e4114e)  

---
## Implement Users Profile Form
* Create `ProfileForm.js` & `ProfileForm.css` components.  
* Update `Userfeedpage.js` with the ProfileForm.  
* Create `Popup.css` for (Edit profile) popup window.  
* import it into `App.js`.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/400d7892eef5837f0bc67186c98b642828b5eb0f)  
  
* Create `update_profile.py` service in `backend-flask/services`.  
* Create `update.sql` for updating users in DB.  
* Implement ***profile update*** endpoint in `app.py`.  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/bf5d57da45a4751d7fb78bc319b30db39260b8fa)  
Minor fix in `update_profile.py` in this commit [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/d46674db5c0209b0688acfd5d035fda0a5a9c766#diff-c95494c3f1ea729bd29937a915531b6acd5e805188ca662b5a5d7dc59e42698d)  

---

## Implement Backend Migrations
We will implement the DB migrations scripts so users can update their bio and these updates can be saved in DB.  

* Create `backend-flask/db/migrations` folder to keep the script output files there.  
  Inside this folde, create an empty `.keep` file.  
* Create the ***migration*** script in `bin/generate/` folder.  
  check the migration script file [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/bin/generate/migration).  
* Run `./bin/generate/migration add_bio_column` and check the generated `.py` script in `backend-flask/db/migrations/`.  
* Populate the generated file with SQL actions for migrate and rollback.  
* Create the `migrate` & `rollback` scripts to be triggered under `bin/db/` folder.  
  '' the rollback script should select the last successful migration run which is not yet in our schema ''  
* Update the `schema.sql` with the last successfull run  
* Enable verbose option in `backend-flask/lib/db.py` ([Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1f79d76829298983ce2de957f84692b0d3d8f741))  

Migration, migrate, and rollback scripts commit ([Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/e4572bfa5f8bafd57612f9de1e68dc52f8dfa313#diff-192c1336f7b57bb30bc067e6eae8c4c044ec748475ca887564bdc0d14aca62df))  
Generated script & schema.sql update commit ([Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/20fd14f325654de88b60dd825071465012bb946f#diff-bbc12a1f400fea71904f24b48cd2032ec91f812c051c3957b664e36b4fc04887))  

* Connect to database and create that last successfull run table  
```sql
CREATE TABLE IF NOT EXISTS public.schema_information (
  last_successful_run text
);
```
* Run the `migrate` script and check if new column called `bio` is created in the db table of users. 
* Run the `rollback` script, that bio column should be removed.  

![test db-migrate-rollback scripts2](https://user-images.githubusercontent.com/105418424/233407423-c771be2f-8644-40cf-a468-6472d3c90f5c.png)

* Update display name & bio and check if the user is updated in DB!

![image](https://user-images.githubusercontent.com/105418424/233409911-c0a89fb9-34d9-4eba-95e0-f550a87732df.png)  
![image](https://user-images.githubusercontent.com/105418424/233409800-60047f8f-4f8d-4b2d-9390-ed1a24d02406.png)  

---
## Upload Avatar Implementation
We need to Implement the "Upload Avatar" button in edit profile page.  
  First, create Lambda function for creating presignedURL. This presignedURL will give access to upload avatar to our ***Uploaded-avatars*** S3 Bucket.  
  - Create `function.rb` inside `aws/Lambdas/cruddur-upload-avatar/`  
  - While inside that folder, run `bundle init`. (this will generate a Gemfile which contains required packages for the function)  
  - in the Gemfile, input (gem "aws-sdk-s3" & gem "ox")  
  - Run `bundle install` to install the requirements.  
    ([First Commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ef7a7fe123cf78ec11fb7dc7b8b0b3a0081c5244))  
    ([Updated function commit "thanks to beiciliang"](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/6056e7043f014bb2bb32c9d63ea1b6660653a575))  
  You can find the last updated function [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/aws/Lambdas/cruddur-upload-avatar/function.rb)  
  - to test running the function: (this should create the presigned URL.)  
  ```sh
  bundle exec ruby function.rb
  ```
  - Create a PUT request "using **Thunder client** extension" with the `lore.jpg` to the presignedURL and the file should be uploaded to the bucket.

  ![put request return 200 file upload](https://user-images.githubusercontent.com/105418424/233414523-407b9a4a-54d8-4c6b-b531-86462471d1f8.png)  
* From AWS Lambda console, create a new function  
  - name: `CruddurAvatarUpload`.  
  - Code source: copy from `aws/Lambdas/cruddur-upload-avatar/function.rb`. "Use your own Frontend URL for Origin"  
  - Rename Handler to `function.handler`.  
  - Add environment variable `UPLOADS_BUCKET_NAME` with your uploads bucket name.  

This function needs additional permissions to upload files into the upload bucket  
  - Create `aws/policies/s3-upload-avatar-presigned-url-policy.json`. you can find it ([Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/aws/policies/s3-upload-avatar-presigned-url-policy.json))  
  - From IAM console, attach additional inline policy to our `CruddurAvatarUpload` lambda role with our created policy above.  

Second, create the ApiGatewayAuthorizatoin lambda function:
  - Create `aws/Lambdas/lambda-authorizer/index.js`.  
  - While inside lambda-authorizer folder, run `npm install aws-jwt-verify --save`.  
  - Download and ZIP all the folder contents.  
([First Commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5d84561321d572327424682db023e6fec2e79d61))  
([Updated function commit "thanks to beiciliang"](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2c7b26d750e1fd29bc65310464ca52ae69852443))  
You can find the last updated function [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/aws/Lambdas/lambda-authorizer/index.js)  
* From AWS Lambda console, create a new function
  - name: `ApiGatewayLambdaAuthorizer`.  
  - from the ***code*** tab >> upload .zip file.  
  - Add environment variables `USER_POOL_ID` and `CLIENT_ID`. "Use your cognito user pool ID & Client ID"  
---

From AWS API Gateway console  
* Create API Gateway and choose ***HTTP API***.  
* Choose the region & ***authorization*** lambda function.  
* API Name: `api.<domain_name>`  
* stage name is `default`
* Create 2 routes:  
  - `/avatars/key_upload`:  
    - Method: POST  
    - authorizer: `CruddurJWTAuthorizer` Lambda function  
    - integration: `CruddurAvatarUpload` Lambda function  
  - `/{proxy+}`:  
    - Method: OPTIONS  
    - authorizer: no authorizer  
    - integration: `CruddurAvatarUpload` Lambda function  
---
Configure uploaded-avatars bucket CORS policy  

* Create `aws/s3/cors.json`  
  check the file [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/aws/s3/cors.json)  
* From AWS S3 console, Create the s3 bucket CORS policy using the created json file above  

PresignedURL policy & CORS policy commit [Here](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9ca173b33a264ddd582ac2b03ec45816476d6569)  

---
* Add s3upload function & click event to `ProfileForm.js`  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/422c88ce901cbcccfc3f81da2850a26a103ee8d7)  

---
* Add the `frontend` & `api-gateway` URLs into `frontend.erb`  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/7587e9e21f7b274959eccd3ef3936ed7e2bbe5a8)  

---
  Create `ruby-jwt` lambda layer script to create & upload the jwt lambda layer for the `CruddurAvatarUpload` lambda function  
  - Create `bin/lambda-layers/ruby-jwt`  
  '' this script will install the required package into a defined directory, zip it and upload it as lambda layer ''  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b977abe203bed45798ae79e190b0f41a5e6a448d)  

---
Instead of using this lambda layer for the function, I updated the function according to an advice from another bootcamper (thanks [beiciliang](https://github.com/beiciliang)) to pass the JWT sub from `CruddurApiGatewayLambdaAuthorizer` to `CruddurAvatarUpload`.  

Changes in [this Commit](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2c7b26d750e1fd29bc65310464ca52ae69852443)  

* Upload the avatar and check the cloudwatch logs of the function
  '' returning the presignedURL without errors & image updated successfully ''  

![image](https://user-images.githubusercontent.com/105418424/233465588-41abb81e-d43c-48ce-bc7b-367cec7d3fae.png)

---
## Render Avatars in App via CloudFront

* Create a new components `ProfileAvatar.js` & `ProfileAvatar.css`  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/2fd807557ea9f4697fc220b1e2b1ab85fd272af0)  

* Set the user cognito uuid in `CheckAuth.js` to call it  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dc1691aae07587f41b8eb00da47ec497969a5345)  

* Add profile avatar in `profileinfo.js` & `ProfileHeading.js`  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/d37a32743828f68b41cefdb7c4b60f55bcbb101b)  

* In order to grab this id, add the cognito user id in `show.sql`  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/fe395e3b194eda4bc72666d6b6a0cbba992ca8dc)  

* Update `ProfileHeading.css` with avatar styling  
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ba1da4007c7cda40e871b210939932eb5f9e6be5)  

* Refresh the website page and check your avatar is rendered!  

![image](https://user-images.githubusercontent.com/105418424/233470153-22a181e5-f61e-4a5d-beff-8b9f32aac2ad.png)
