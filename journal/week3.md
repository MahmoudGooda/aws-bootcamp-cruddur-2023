# Week 3 — Decentralized Authentication

### Install AWS Amplify
* `--save` to save the *aws-amplify* in `package.json`
```sh
npm i aws-amplify --save
```
-------------
### Setup Cognito User Pool
- From AWS management console, I created a user pool name "cruddur-user-pool".
#### Sign-in experience
- choose Sign in option to ***Email only*** (our configuration so far!).
#### security requirements
- I was satisfied with cognito default password complexity policy and set with ***NO MFA*** require.
- To reduce costs I picked the ***Email only*** method for user confiramtion and recovery.
#### Sign-up experience
- Enable ***self registration***, so users can create accounts.
- Required attribute (email) .. optional attributes (*name, preferred_username*).
#### Message delivery
- Set Cognito as Email provider so far! till configuring AWS SES.
#### App Integration
- Set user pool name `cruddur-user-pool`, App client name `cruddur`.
- App type is ***Public client***.

![image](https://user-images.githubusercontent.com/105418424/223822886-a61c0bd7-6a90-4259-8255-7a27a7cdbd12.png)
-------------
### Configure Amplify
* Add cognito user pool env. vars into `App.js` and configure Amplify for authentication.
```js
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_identity_pool_id": process.env.REACT_APP_AWS_COGNITO_IDENTITY_POOL_ID,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```
* Add AWS cognito env. vars into docker compose.  
[Commit link for above steps (install Amplify, App.js, docker-compose)](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/3addd2fa8bc8a58507bfb3619ab2fb2c96fca7e8 "Commit Link")

* Corrected cognito vars in `App.js` in this commit  
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/9023ac8038ffdb239bf98a7eb22f2b24b0ecd61a "correct commit")
-------------
### Configure Amplify
Update Homepage view based on authentication check
 
In `HomeFeedPage.js` file:
```js
import { Auth } from 'aws-amplify';

// set a state
const [user, setUser] = React.useState(null);

// check if we are authenicated
const checkAuth = async () => {
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

// check when the page loads if we are authenicated
React.useEffect(()=>{
  loadData();
  checkAuth();
}, [])
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/5d69f67d22692a25978b488e6f235db5b567121a)

-------------
### Update Profileinfo for signout action
in `Profileinfo.js`

```js
import { Auth } from 'aws-amplify';

const signOut = async () => {
  try {
      await Auth.signOut({ global: true });
      window.location.href = "/"
  } catch (error) {
      console.log('error signing out: ', error);
  }
}
```
-------------
### Update Sign-in Page
Now we need to configure app to authenticate with cognito in sign-in page:
  
in `SigninPage.js` file

"We had to update the *error catch* part to be able to see the correct error message."
```js
import { Auth } from 'aws-amplify';

const onsubmit = async (event) => {
  setErrors('')
  event.preventDefault();
    Auth.signIn(email, password)
      .then(user => {
        console.log ('user', user)
        localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken)
        window.location.href = "/"
      })
      .catch(error => { 
        if (error.code == 'UserNotConfirmedException') {
          window.location.href = "/confirm"
        }
      setErrors(error.message)
    });
  return false
}

// just before submit component
{errors}
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/c4d5f2ef3531ddde4d319550421f5b968a016584)

-------------
### Configure SignUp with Auth
As we configured cognito with self registration for users, we'll need to configure the app sign-up page:  

In `SignupPage.js` file
```js
import { Auth } from 'aws-amplify';

const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
        const { user } = await Auth.signUp({
          username: email,
          password: password,
          attributes: {
              name: name,
              email: email,
              preferred_username: username,
          },
          autoSignIn: { // optional - enables auto sign in after user is confirmed
              enabled: true,
          }
        });
        console.log(user);
        window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setErrors(error.message)
    }
    return false
  }
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/eb2bef70b9e70c98ef17f62f6a9aadb92f844973)

-------------
### Update send code & submit for confirmation
We will configure sending sign-up verification code and account sign-up confirmation page: 

in `ConfirmationPage.js`
```js
import { Auth } from 'aws-amplify';

const resend_code = async (event) => {
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      console.log('email', email)
      setCodeSent('email', email);
      // setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
  }
 
 const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }
  ```
  [Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/cbc5258a7a748edb8296bbce8e3da22f8d0d5a6c)
  
  -------------
  ### Configure Recovery Page
  For ***Forgot Password*** scenario we need to configure the password recovery page:
  
  in `RecoverPage.js` file
  ```js
  import { Auth } from 'aws-amplify';
  
  const onsubmit_send_code = async (event) => {
    event.preventDefault();
    setErrors('')
    Auth.forgotPassword(username)
    .then((data) => setFormState('confirm_code') )
    .catch((err) => setErrors(err.message) );
    return false
  }
  const onsubmit_confirm_code = async (event) => {
    event.preventDefault();
    setErrors('')
    if (password == passwordAgain){
      Auth.forgotPasswordSubmit(username, code, password)
      .then((data) => setFormState('success'))
      .catch((err) => setErrors(err.message) );
    } else {
      setErrors('Passwords do not match')
    }
    return false
  }
  ```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/8636f1d6e47d381ffbb76832c284d068ab69f072)

-------------
### Added myself as a suggested user!
In the `DesktopSidebar.js` file, I added myself as a suggested user.
```js
{"display_name": "Mahmoud Gooda", "handle": "mgooda"}
```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/c504ef10e22557aaab19df76091eb564ddd03cde)

-------------
### Updated Notifications page Sidebar view while logged in
I found that even when the user is logged in, the Sidebar view shows as default "with **Sign up** and **Sign in**" buttons when clicking on the **"Notifications"** tab.
So I updated the `NotificationsFeedPage.js` file to view based on user is signed in.
```js
import { Auth } from 'aws-amplify';

// check if we are authenicated
  const checkAuth = async () => {
    Auth.currentAuthenticatedUser({
      // Optional, By default is false. 
      // If set to true, this call will send a 
      // request to Cognito to get the latest user data
      bypassCache: false 
    })
    .then((user) => {
      console.log('user',user);
      return Auth.currentAuthenticatedUser()
    }).then((cognito_user) => {
        setUser({
          display_name: cognito_user.attributes.name,
          handle: cognito_user.attributes.preferred_username
        })
    })
    .catch((err) => console.log(err));
  };
  
  // check when the page loads if we are authenicated
  React.useEffect(()=>{
    loadData();
    checkAuth();
  }, [])
  ```
[Commit link](https://github.com/MahmoudGooda/aws-bootcamp-cruddur-2023/commit/b7f706dca22963b714f4226dc85d4f78fd2bd6e1)