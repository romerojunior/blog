---
layout: post
title: "AWS: API Gateway Cognito Authorizer"
author: "Romero Galiza"
comments: true
---

## Scenario

Imagine you want to **build** and **expose** a REST API on AWS. At this moment your API's only requirement is to support a single resource (`domain.com/default/greetings`), and whenever this resource is called with a GET request, it should return "Hello".

## Constraints

What if you would like to **protect** your API resource from unauthorized users? What if instead of greetings you would like to expose specific data fetched from third-party backends or storage solutions. We can achieve this using a AWS Cognito **authorizer**.

## Solution


For testing purporses, let's create a user (`butters@southpark.com`) in your Cognito User Pool, followed by a administrator triggered "sign up" confirmation:

```bash
# Create user (sign up):
aws cognito-idp sign-up \
--client-id a11b22c33d44e55f66g77h88i99j \
--username butters@southpark.com \
--password S3cr3tP4ssw0rd \
--region eu-central-1 \
--user-attributes '[
    {"Name":"given_name","Value":"Butters"},
    {"Name":"family_name","Value":"Scotch"},
    {"Name":"email","Value":"butters@southpark.com"},
    {"Name":"gender","Value":"Male"}
]'

# Confirm sign up:
aws cognito-idp admin-confirm-sign-up --user-pool-id eu-central-x_xxxyyyzzz --username 58ccaeb4-0668-4361-97f2-b782f4dc00c1
```


You could rely directly on your application in order to authenticate, for this example, let's simply use `curl`. To keep things simple and repetable, create a .json file (`aws-auth-data.json`) with the following structure, replacing values when needed:

```json
{
   "AuthParameters" : {
      "USERNAME" : "butters@southpark.com",
      "PASSWORD" : "S3cr3tP4ssw0rd"
   },
   "AuthFlow" : "USER_PASSWORD_AUTH",
   "ClientId" : "a11b22c33d44e55f66g77h88i99j"
}
```

More information about different `AuthFlow` can be found on this [page](https://docs.aws.amazon.com/cognito-user-identity-pools/latest/APIReference/API_InitiateAuth.html).

Putting it all together, we end up with the following authentication script (`fetch_id_token.sh`):
```bash
#!/bin/bash
curl -s -X POST \
    --data @aws-auth-data.json \
        -H 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
        -H 'Content-Type: application/x-amz-json-1.1' \
        https://cognito-idp.eu-central-1.amazonaws.com | jq .AuthenticationResult.IdToken | sed 's/\"//g'
```

The above command will call `AWSCognitoIdentityProviderService` API on the `InitiateAuth` resouce, this expects a request content type `x-amz-json-1.1` (provided with `aws-auth-data.json`). A successful authentication will return:

```json
{
    "AuthenticationResult": {
        "AccessToken": "FVytONjAyMnpvVmtYaFR...FVytONjAyMnpvVmtYaFR",
        "IdToken": "NhaTY0Z0FjMFNhaTY00F...NhaTY0Z0FjMFNhaTY00F",
        "RefreshToken": "eyJjdHkiOiJKV1QiLCJb...eyJjdHkiOiJKV1QiLCJb",
        "TokenType": "Bearer",
        "ExpiresIn": 3600
    },
    "ChallengeParameters": {}
}
```

Each of these tokens follows the JWT standard and can be validated [here](https://jwt.io/). You should also verify the claim on your beckend before further processing, like discussed [here](https://docs.aws.amazon.com/cognito/latest/developerguide/amazon-cognito-user-pools-using-tokens-verifying-a-jwt.html).

Our script job is to parse the blob above, retrieving the only value we care about for the sake of this example. That would be the `IdToken`. We could use it as such:

```bash
curl -i -s -X GET https://example.execute-api.eu-central-1.amazonaws.com/default/greetings -H "Authorization: $(./fetch_id_token.sh)"
```
