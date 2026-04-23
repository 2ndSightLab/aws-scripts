# validate API Gateway

## Validate API Gateway Configuration

## API Gateway Configuration

- Use a REST API (not HTTP API) — REST APIs give you more control over authorizer enforcement and resource policies
- Attach the Lambda Authorizer to every route — no route without it, including OPTIONS if you handle CORS yourself
- **Disable authorizer caching** (TTL=0) — every request must be verified because assertions are single-use
- Set the authorizer's token source to the Authorization header (where the client sends the signed assertion)
- API Gateway resource policy: restrict to your org or specific VPC if needed

## Backend Lambdas (job-list, job-invoke)

Each backend Lambda needs a resource policy that allows only API Gateway to invoke it:

json
{
  "Effect": "Allow",
  "Principal": {"Service": "apigateway.amazonaws.com"},
  "Action": "lambda:InvokeFunction",
  "Resource": "arn:aws:lambda:REGION:ACCOUNT:function:FUNCTION_NAME",
  "Condition": {
    "ArnLike": {
      "AWS:SourceArn": "arn:aws:execute-api:REGION:ACCOUNT:API_ID/*"
    }
  }
}


Then remove all other lambda:InvokeFunction grants:
- No IAM user or role should have lambda:InvokeFunction for these Lambdas
- No other resource policies allowing invocation
- The Lambdas' own execution roles must NOT have lambda:InvokeFunction on themselves or each other

## IAM Lockdown

- No IAM principal (user, role, group) should have lambda:InvokeFunction for the backend Lambdas — audit all 
policies
- SCP at the OU level to deny lambda:InvokeFunction on the backend Lambdas for everyone except 
apigateway.amazonaws.com:

json
{
  "Effect": "Deny",
  "Action": "lambda:InvokeFunction",
  "Resource": [
    "arn:aws:lambda:REGION:ACCOUNT:function:botz-job-list",
    "arn:aws:lambda:REGION:ACCOUNT:function:botz-job-invoke"
  ],
  "Condition": {
    "StringNotEquals": {
      "aws:PrincipalServiceName": "apigateway.amazonaws.com"
    }
  }
}


The SCP is the critical piece — even if someone with IAM admin in the account adds a permissive policy, the SCP (
managed at the org level) blocks it. Without the SCP, an IAM admin in the account could grant themselves 
lambda:InvokeFunction and bypass everything.

## Auth Lambda

- Becomes the Lambda Authorizer — invoked by API Gateway, not directly
- Resource policy allows only apigateway.amazonaws.com (same pattern as above)
- Response format changes to return IAM policy documents instead of {verified: true/false}
- Challenge endpoint becomes a separate unauthenticated route on the API Gateway (the client needs to get a 
challenge before it can authenticate)

## What to verify

1. No route on the API Gateway is missing the authorizer
2. No backend Lambda has any lambda:InvokeFunction grant outside of API Gateway
3. The SCP is in place at the OU level
4. The authorizer cache TTL is 0
5. The challenge route is the only unauthenticated route, and it only returns a random challenge (no sensitive data,
no actions)
6. lambda:UpdateFunctionConfiguration and lambda:PutFunctionPolicy are restricted — someone who can change the 
resource policy can remove the lockdown

That gives you: every request goes through API Gateway → authorizer verifies Yubikey assertion → backend Lambda 
executes. No bypass path exists unless someone has org-level admin access to modify the SCP.
 
