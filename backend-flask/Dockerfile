FROM python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
RUN apt-get update && apt-get install curl -y

COPY . .
RUN chmod +x CMD-script.sh
ENV FLASK_ENV=development

EXPOSE ${PORT}
ENTRYPOINT ./CMD-script.sh
