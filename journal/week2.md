# Week 2 — Distributed Tracing
## Honeycomb Implementation
### Instrument Honeycomb with OTEL
* Created an environment called "Bootcamp" and exported the "API KEY" environment variable in Gitpod.  
```APIKEY
export HONEYCOMB_API_KEY="my api key"
gp env HONEYCOMB_API_KEY="my api key"
```
![image](https://user-images.githubusercontent.com/105418424/222491501-b192a457-5377-4b8f-bc35-75f41ef9a209.png)
---------------
* Added OpenTelemetry to backend enviornment variables in docker-compose.yml  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/a3702999a78310bc39c72e41a1e39d9f9e2765f8 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222496226-8e51b3e3-63ba-4834-b8ea-13734a89ae8b.png)
---------------
* Added opentelemetry modules into requirements.txt file  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/31146477ea41f4480e2138505cb6777de74ca965 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222496416-8d4bdb08-98b5-41b4-ae10-6db18f89c490.png)
---------------

* Install requirements 
``` Install reqs
cd backend-flask/
pip install -r requirements.txt
```
---------------
* Added Honeycomb instrumentation to *app.py*  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/75a31b0e9270a23bed793c87cf54326d9765d7dc "Commit Link")
By mistake the *app* line is duplicated causing errors, so duplicate line was removed!
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/1128f7dfbfa55da9f03d06b26ecd0131cb84f2ea "Commit Link")

---------------
* After running compose up, I couldn't see any results in Honeycomb even after adding the *SimpleSpanProcessor* lines in app.py!
* Found out that the API KEY env.var was set but not passed to the backend container, after setting it to Gitpod env.vars correctly, I could get results directly on Honeycomb.  
Here's a summary/sample of *backend-flask* dataset traces

![image](https://user-images.githubusercontent.com/105418424/222673758-7db10e62-b8be-48f6-951d-b2bda0311ffa.png)

A trace showing *notifications* span

![image](https://user-images.githubusercontent.com/105418424/222672150-a3327eb2-2250-4ce6-afa3-bfe594d67d94.png)

---------------
* Added span attributes "app now" and "app results length" as well in *home_activities.py*  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/0b5b417820a6f3f0f7a7a2503757991915a1bf23 "Commit Link")

![image](https://user-images.githubusercontent.com/105418424/222672939-a9838b89-2bf8-4f1f-a466-81ae70733f18.png)

* Adding span "home-activities-mock-data"

![image](https://user-images.githubusercontent.com/105418424/222676999-93aa5322-6e91-47cd-b686-1eccbb7a62fb.png)

* Trace after span attributes

![image](https://user-images.githubusercontent.com/105418424/222678206-82ef79c1-d2b0-42e4-9202-3deb4f26cb59.png)