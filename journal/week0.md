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

Created Access Keys:

![Access Keys1](https://user-images.githubusercontent.com/105418424/219480694-42d9bb06-eeee-4f6a-967d-576d4e8e8500.png)
![Access Keys2](https://user-images.githubusercontent.com/105418424/219480839-c969f024-8522-45c9-b343-d3795b3b662a.png)
