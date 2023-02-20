# Week 1 — App Containerization

## Required Homework
### Containerize Application
* I Created a Dockerfile within the *flask-backend* and *frontend-react-js* folders containing the image instructions.  
[Backend Dockerfile](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/backend-flask/Dockerfile "Backend Dockerfile") - [Frontend Dockerfile](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile "Frontend Dockerfile")
* To be able to run all containers in a single command, I created the *docker-compose.yml* file in the root folder then copied the contents from project repo.
[docker-compose file](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/docker-compose.yml "docker-compose file")
* Now compose up to run the containers (building the specific images if needed) and wait until all containers are in *started* state.

![image](https://user-images.githubusercontent.com/105418424/219976984-1a60c1d7-a356-433f-8675-151e48072211.png)

### Document the Notification Endpoint for the OpenAI Document
Following along with the *Create the notification feature* video:
* In the *openapi-3.0.yml* file, I added a new path *"/api/activities/notifications:"*, description, tags, and response details.

![image](https://user-images.githubusercontent.com/105418424/219977309-6fcbee59-7ffd-4af7-91ec-80e97f611620.png)

### Write a Flask Backend Endpoint for Notifications  
* I created notifications endpoint, created a python file for notifications activities within *backend_flask* folder.
I copied the *home activities* contents, then made some edits to be for notifications activites.

![image](https://user-images.githubusercontent.com/105418424/220108596-46937dfd-13ea-4e28-86d8-c40e75d39956.png)
![image](https://user-images.githubusercontent.com/105418424/220108700-31d64654-d281-4ae0-bccc-e065190145c6.png)

### Write a React Page for Notifications
* I created a js file for the notifications page (same as homefeed page with some modifications) and a .css file for styling if needed.  

![image](https://user-images.githubusercontent.com/105418424/220121238-e4529ea5-b91e-4370-8fb4-06dc759fd85b.png)

Finally we can get the notifications page same as expected!

![image](https://user-images.githubusercontent.com/105418424/220122204-020c0ba1-f584-416d-8164-6e89694ee934.png)

### Run DynamoDB Local Container and ensure it works
* After adding DynamoDB Local and Postgres to that *Docker-compose.yml* file.
I ran some commands to ensure it works ( same from *100DaysOfCloud* repo).

![image](https://user-images.githubusercontent.com/105418424/220126566-ec3ad66b-1b78-4a5c-bee1-b6853ff91d21.png)

### Run Postgres Container and ensure it works
* Following along with the video I ran a command to ensure postgres is working

![image](https://user-images.githubusercontent.com/105418424/220127064-16751e87-33ff-4070-8f2a-1d3cc8598ed7.png)

