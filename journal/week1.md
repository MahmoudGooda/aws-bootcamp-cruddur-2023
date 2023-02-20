# Week 1 — App Containerization

## Required Homework
### Containerize Application
* I Created a Dockerfile within the *flask-backend* and *frontend-react-js* folders containing the image instructions.  
[Backend Dockerfile](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/backend-flask/Dockerfile "Backend Dockerfile") - [Frontend Dockerfile](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/frontend-react-js/Dockerfile "Frontend Dockerfile")
* To be able to run all containers in a single command, I created the *docker-compose.yml* file then copied the contents from project repo.
[docker-compose file](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/blob/main/docker-compose.yml "docker-compose file")
* while watching *DynamoDB and Postgres vs Docker* video in the official YouTube playlist, I added DynamoDB Local and Postgres to that *Docker-compose.yml* file.
* Now docker compose up to run the containers (building the specific images if needed) and wait until all containers are in *started* state.

![image](https://user-images.githubusercontent.com/105418424/219976984-1a60c1d7-a356-433f-8675-151e48072211.png)

### Document the Notification Endpoint for the OpenAI Document
Following along with the *Create the notification feature* video:
* In the *openapi-3.0.yml* file, I added a new path *"/api/activities/notifications:"*, description, tags, and response details.

![image](https://user-images.githubusercontent.com/105418424/219977309-6fcbee59-7ffd-4af7-91ec-80e97f611620.png)

## Write a Flask Backend Endpoint for Notifications  
* I created notifications endpoint, (created a python file for notifications activities) within backend_flask folder.
I copied the *home activities* contents, then made some edits to be for notifications activites.
![image](https://user-images.githubusercontent.com/105418424/220108596-46937dfd-13ea-4e28-86d8-c40e75d39956.png)
![image](https://user-images.githubusercontent.com/105418424/220108700-31d64654-d281-4ae0-bccc-e065190145c6.png)

