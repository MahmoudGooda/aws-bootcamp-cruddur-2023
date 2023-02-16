# Week 0 — Billing and Architecture

## Conceptual Diagram
I recreated the Conceptual Diagram following along in live stream  
[Diagram Link](https://lucid.app/lucidchart/855757f9-fe2b-4d9d-b972-76a23e056899/edit?viewport_loc=-1742%2C575%2C2447%2C1144%2C0_0&invitationId=inv_5c0a4c05-1362-4356-a97a-702745b70e46)
## Logical Diagram
I recreated the Logical Diagram  
[Diagram Link](https://lucid.app/lucidchart/3678172a-c132-4b85-9b43-c7d1a0d87168/edit?viewport_loc=-464%2C-24%2C3330%2C1557%2C0_0&invitationId=inv_40621fa3-a2f5-47e3-9b1e-537ab51c487b)
## AWS
Following screenshots from my AWS root account showing my created IAM user with administrator and billing full access  
I created a group named "admins", attached administrator access policy to that group, then included the user in it so policy will be inherited.

![IAM Users](https://user-images.githubusercontent.com/105418424/219474591-c9874276-b528-472f-b780-5fe476c05e2b.png)
![IAM User](https://user-images.githubusercontent.com/105418424/219475175-3ec55563-f16b-4aad-a1ab-ab56fadd6a09.png)

I used us-east-1 region and opened cloudshell in:  
![Cloudshell](https://user-images.githubusercontent.com/105418424/219478337-af5eaa5f-1ba7-4eaf-bd67-d4df863854a4.png)

Created Access Keys for IAM user:  
![Access Keys1](https://user-images.githubusercontent.com/105418424/219480694-42d9bb06-eeee-4f6a-967d-576d4e8e8500.png)
![Access Keys2](https://user-images.githubusercontent.com/105418424/219480839-c969f024-8522-45c9-b343-d3795b3b662a.png)

Enabled Billing Alerts from Billing prefrences page.

## SNS Notifications  
Created SNS Topic named "Billing-alarm"  
![SNS-Topic](https://user-images.githubusercontent.com/105418424/219485802-7d64272f-556a-45c0-a3c1-311e01012e74.png)  
Created subscription with Email protocol and my email address for the Endpoint  
![subscription](https://user-images.githubusercontent.com/105418424/219486309-3bbb2adb-bfc3-4d4e-8dd9-473aa69cd959.png)  
Confirmed the subscription  
![Confirmation](https://user-images.githubusercontent.com/105418424/219487067-a6b7705f-6b59-48e6-bab5-17d3b68b8a5d.png)

## Billing Alarm  
Created Billing Alarm that will send SNS notification to my email address when estimated charges is equal to or greater that 10$  
![Alarm1](https://user-images.githubusercontent.com/105418424/219491854-a124c0b3-4081-4967-a869-3e8e28438727.png)  
![Alarm2](https://user-images.githubusercontent.com/105418424/219492470-5c5e3f5d-4260-41f6-bdf8-e52b132d58aa.png)

## Budget  
Created 2 budgets (Zero spend-budget & Monthly cost budget) with notification to my email address.  
![Budgets](https://user-images.githubusercontent.com/105418424/219495558-bbf956d2-2bcd-49c8-aa3d-aaecabf50324.png)

