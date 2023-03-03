# Week 2 — Distributed Tracing
## Honeycomb Implementation
### Instrument Honeycomb with OTEL
* Create an environment called "Bootcamp" and export the "API KEY" environment variable in Gitpod.  
```APIKEY
export HONEYCOMB_API_KEY="my api key"
gp env HONEYCOMB_API_KEY="my api key"
```
![image](https://user-images.githubusercontent.com/105418424/222491501-b192a457-5377-4b8f-bc35-75f41ef9a209.png)
---------------
* Add OpenTelemetry to backend enviornment variables in docker-compose.yml  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/a3702999a78310bc39c72e41a1e39d9f9e2765f8 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222496226-8e51b3e3-63ba-4834-b8ea-13734a89ae8b.png)
---------------
* Add opentelemetry modules into `requirements.txt` file  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/31146477ea41f4480e2138505cb6777de74ca965 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222496416-8d4bdb08-98b5-41b4-ae10-6db18f89c490.png)
---------------
* Install requirements 
``` Install reqs
cd backend-flask/
pip install -r requirements.txt
```
---------------
* Add Honeycomb instrumentation to *app.py*  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/75a31b0e9270a23bed793c87cf54326d9765d7dc "Commit Link")  
* By mistake the *app* line is duplicated causing errors, so duplicate line was removed!
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1128f7dfbfa55da9f03d06b26ecd0131cb84f2ea "Commit Link")
---------------
* After running compose up, I couldn't see any results in Honeycomb even after adding the *SimpleSpanProcessor* lines in app.py!
* Found out that the `HONEYCOMB_API_KEY` env. variable was set but not passed to the backend container, after setting it to Gitpod env.vars correctly, I could get results directly on Honeycomb.  
- Here's a summary/sample of *backend-flask* dataset traces

![image](https://user-images.githubusercontent.com/105418424/222673758-7db10e62-b8be-48f6-951d-b2bda0311ffa.png)

A trace showing *notifications* span

![image](https://user-images.githubusercontent.com/105418424/222672150-a3327eb2-2250-4ce6-afa3-bfe594d67d94.png)
---------------
* Add span attributes "app now" and "app results length" as well in `home_activities.py`  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/0b5b417820a6f3f0f7a7a2503757991915a1bf23 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222672939-a9838b89-2bf8-4f1f-a466-81ae70733f18.png)

![image](https://user-images.githubusercontent.com/105418424/222676999-93aa5322-6e91-47cd-b686-1eccbb7a62fb.png)

* Trace after span attributes

![image](https://user-images.githubusercontent.com/105418424/222678206-82ef79c1-d2b0-42e4-9202-3deb4f26cb59.png)
---------------
## Instrument AWS X-Ray for Flask
* add aws-xray-sdk to `requirements.txt`

![image](https://user-images.githubusercontent.com/105418424/222685344-616c23ad-8018-42cf-991d-7d6ea133fde7.png)  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/afba5d788c3e6023e6fd41402e17a6c18b21627a "Commit Link")

---------------
* Install requirements 
``` Install reqs
cd backend-flask/
pip install -r requirements.txt
```
---------------
* Instrumenting X-Ray in flask app.py

``` python
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.ext.flask.middleware import XRayMiddleware

xray_url = os.getenv("AWS_XRAY_URL")
xray_recorder.configure(service='backend-flask', dynamic_naming=xray_url)
XRayMiddleware(app, xray_recorder)
```
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/c29dbaf3a037acc45f64c40a8dcc328b68ade4dc "Commit Link")

---------------
#### Setup AWS X-Ray Resources
* Create json file in `aws/json/xray.json` with sampling rule data
``` json
{
    "SamplingRule": {
        "RuleName": "Cruddur",
        "ResourceARN": "*",
        "Priority": 9000,
        "FixedRate": 0.1,
        "ReservoirSize": 5,
        "ServiceName": "backend-flask",
        "ServiceType": "*",
        "Host": "*",
        "HTTPMethod": "*",
        "URLPath": "*",
        "Version": 1
    }
  }
  ```
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/bf48fd2964424e83b7851fe7a1a4081ce3d2d3b9 "Commit Link")

---------------
* Create group named `Cruddur`
``` CMD
FLASK_ADDRESS="https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}"
aws xray create-group \
   --group-name "Cruddur" \
   --filter-expression "service(\"$FLASK_ADDRESS\")
```

* Create the sampling rule using json file created earlier
``` cmd
aws xray create-sampling-rule --cli-input-json file://aws/json/xray.json
```
---------------
* Add X-RAY Deamon Service to `docker-compose.yml`
``` yaml
  xray-daemon:
    image: "amazon/aws-xray-daemon"
    environment:
      AWS_ACCESS_KEY_ID: "${AWS_ACCESS_KEY_ID}"
      AWS_SECRET_ACCESS_KEY: "${AWS_SECRET_ACCESS_KEY}"
      AWS_REGION: "us-east-1"
    command:
      - "xray -o -b xray-daemon:2000"
    ports:
      - 2000:2000/udp
```
* Add X-RAY env. vars to `docker-compose.yml`
``` yaml
    AWS_XRAY_URL: "*4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}*"
    AWS_XRAY_DAEMON_ADDRESS: "xray-daemon:2000"
```
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/784d986a355f8d7bdb714f482e7f843df4c9bfba "Commit Link")

---------------
* Error `app is not defined` >> moved the `xray middleware` line in the correct section *"under `app = Flask(__name__)`"*  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/7b1f0dbe0128eccb9bbda5e14eeb167980f08d39 "Commit Link")
---------------
* Check traces from AWS X-RAY

![image](https://user-images.githubusercontent.com/105418424/222764548-209e1ed3-9604-4977-b5af-fd98c02b2dee.png)
---------------
## CloudWatch Logs
* Add ***watchtower*** to `requirements.txt`
---------------
* Install requirements 
``` Install reqs
cd backend-flask/
pip install -r requirements.txt
```
---------------
#### CloudWatch configurations (I implemented it all, then commented all realted line to avoid unwanted extra costs)
* *Unfortunately I forgot and committed all changes in single commit* (CloudWatch instrumentation in `app.py`, set env. vars in `docker-compose.yml`, Add ***watchtower*** to `requirements.txt`, and add logger in `home_activities.py` )

[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/dc39d3444e851d80ccaddb980a5ed9e1af47e127 "Commit Link")

* Logs from our log group *"cruddur"*

![image](https://user-images.githubusercontent.com/105418424/222796691-5c9f3f7a-6813-43f6-9169-25567960f2af.png)

## Rollbar
* Created a new project "FirstProject" name by default and selected Flask.

* Add ***blinker*** and ***rollbar*** to `requirements.txt`  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/ef60d2e1ce42e556e244f0e6dbc8a0ae7650b4a1 "Commit Link")  
* Install requirements 
``` Install reqs
cd backend-flask/
pip install -r requirements.txt
```
---------------
* Set Access token env. variable
``` cmd
export ROLLBAR_ACCESS_TOKEN=""
gp env ROLLBAR_ACCESS_TOKEN=""
```
---------------
* Add Rollbar access token to backend env. vars in `docker-compose.yml`

[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/12e13ef891f48f7e29becdd6988a4b1c3a5d5821 "Commit Link")

---------------
* Add Rollbar to `app.py`  

``` python
import rollbar
import rollbar.contrib.flask
from flask import got_request_exception
```

```python
rollbar_access_token = os.getenv('ROLLBAR_ACCESS_TOKEN')
@app.before_first_request
def init_rollbar():
    """init rollbar module"""
    rollbar.init(
        # access token
        rollbar_access_token,
        # environment name
        'production',
        # server root directory, makes tracebacks prettier
        root=os.path.dirname(os.path.realpath(__file__)),
        # flask already sets up logging
        allow_logging_basic_config=False)

    # send exceptions from `app` to rollbar, using flask's signal system.
    got_request_exception.connect(rollbar.contrib.flask.report_exception, app)
```
* Add endpoint for testing
```python
@app.route('/rollbar/test')
def rollbar_test():
    rollbar.report_message('Hello World!', 'warning')
    return "Hello World!"
```

[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/c43b0258dbd35b7d3043f454a501d03083d36ebf "Commit Link")

---------------
* Test endpoint URL `https://4567-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}/rollbar/test`  
returns `Hello World!` and shows result as ***Warning*** so , I have to select all filters!
* Make sure to select the correct project and select proper filters.

![image](https://user-images.githubusercontent.com/105418424/222837108-75852ce1-b3e5-41e7-bd0b-caeaf63536a7.png)
![image](https://user-images.githubusercontent.com/105418424/222837625-a3c0d71d-254f-4447-9bb8-feb0bbe8bc56.png)

---------------

#### Test errors:
* Remove `return` from last line in `home_activities.py`  
* Now let's check Rollbar (I tried the new UI!)

![image](https://user-images.githubusercontent.com/105418424/222838650-21c3ea39-20f2-4ce1-b948-3eb04aa8d806.png)

