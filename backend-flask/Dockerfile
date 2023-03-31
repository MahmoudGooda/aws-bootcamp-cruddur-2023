FROM public.ecr.aws/x7c0v0k6/cruddur-python:3.10-slim-buster

WORKDIR /backend-flask

COPY requirements.txt requirements.txt
RUN pip3 install -r requirements.txt
RUN apt-get update && apt-get install -y \
    curl

COPY . .
RUN chmod +x CMD-script.sh
ENV FLASK_DEBUG=1

EXPOSE ${PORT}
CMD ["/bin/bash", "./CMD-script.sh"] 
