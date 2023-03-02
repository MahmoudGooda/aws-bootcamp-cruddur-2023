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
* Added Honecomb to backend enviornment variables in docker-compose.yml  
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
* Add Honeycomb instrumentation to *app.py*  
[Commit Link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/75a31b0e9270a23bed793c87cf54326d9765d7dc "Commit Link")
---------------
* After running compose up, I couldn't see any results in Honeycomb even after adding the *SimpleSpanProcessor* lines in app.py!
* Found out that the API KEY env.var wasn't assigned to Gitpod env.vars correctly, corrected it and got results directly on Honeycomb.

![image](https://user-images.githubusercontent.com/105418424/222501125-49c7868f-d215-4b61-92ba-b6a72ffef051.png)
