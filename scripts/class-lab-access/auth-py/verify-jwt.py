import json
import time
import jwt
from jwt.algorithms import RSAAlgorithm
import sys
import traceback

#Using info from this page mainly:
#https://pyjwt.readthedocs.io/en/latest/usage.html

region = 'us-east-1'
userpool_id = 'us-east-1_FzvvsAVvl'
app_client_id = '7p524otequk4m1sasaggpjfi9v'

#keys_url = 'https://cognito-idp.{}.amazonaws.com/{}/.well-known/jwks.json'.format(region, userpool_id)
#print(keys_url)

def lambda_handler(event, context):

    print('EVENT2')
    print(event)

    querystring = event['Records'][0]['cf']['request']['querystring']
    
    ps=querystring.split("&")
    for p in ps:
        kv = p.split('=')
        if kv[0]=='id_token':
            token=kv[1]
            break
    print("TOKEN")
    print(token)

    #todo: get this from parameter store
    #get the public key matching the kid in the token
    jwks = '{"keys":[{"alg":"RS256","e":"AQAB","kid":"y1CqoRx1LCKn6PC8yjYabTAcEcfmF+Uk1+yhLxwlLjI=","kty":"RSA","n":"r_2P18zXkzm5UnoNcfP44WC8dROJRdjYZsvWLhP_5husthI0s_YwLb5MepVOeOExWQ8yPDMlsqWegbUWDWBIKHIyqDy5MdXkMsQJuQ53ZGS3iRi6opIVqt3_PW30UQbqg_LwO4znnYBM8rxdgQKzhYvTfk0VesHtctRHh3CL9b-RMiH3BcExGDEsX6DvPtUA_Hk4IiaQo-egZAtKLw1BU19SwHKi5Qtw-91PMmM_BIxP_NkjAOe0uLPyG0lzXOYozngvG4BqWJYdeb9PWks0byfzEMUjSeAIgCHpY9YO_ZRLORo6AMcHkLMjo5-41XvPo43M_zYSNgD-hO9u8jhmdQ","use":"sig"},{"alg":"RS256","e":"AQAB","kid":"oQ9rYTBxmFYe75b7togcJORtfyYt7A83siY7cna7c08=","kty":"RSA","n":"z9Cmr4KxXmU1Bp9wlss13fIms6UpGLsgvzqAf5Cb0mte1i-XZb6d49WUpMWSSuCTgHLq5bMZwR23EoYHgHaqFAOYjQbGLhKC5nXLDD2G8N5cNR990g_t8qfYs1a9W0p3r0GklbkEamA4ByneIZUi6gb1BfAWKYjj-IJFmCrT2sk4sbhoAxBtCDtMT97RL1yI8ZyT9d95zUdGE5zVOEZllItwB73wrQ4n0USvu9gYB6qvNMwlDytfr7cJcoHQRcv_zGAZpObxqrLpr1bUtd1yun2PqKd7UXgWvAq75i2ZsRf09iGrtHaUeTldBnmTGHZsU7J2TmRo82d0DmIv073XtQ","use":"sig"}]}'
    
    jwks = '{"keys":[{"alg":"RS256","e":"AQAB","kid":"KFBDg277Mh00v68X4XZcgaYkb01Rrzu5NT9IhAlevhg=","kty":"RSA","n":"vgjsYHFQDmbml-Aq5iKZU1eCi6MMvoh1lL8aohyS1eX09uRyfGHEXeQbqweKq_oWTCEWodRn4VeELCakqg8OjgVmwmTDLRuAwVckC9Y_Q-CGW0XpeB3ohHmE5irNU1oaaI2uz8ZXcbD1xF3nVkTeXfIublCn7uaRGzqNZAgsF9kWI_sdFAqUpI13aLlmZb_dlUZ80hqxiQ5s5xL3AymKV3o6SmbMZyuCMBTlbDDxyePYfbvv1qc4VLu_lUA9TL5Ecs97Tw0-RVwxGrp6zvF-q9GjN2wbdVxRwSNiRgVw_4XqqYyHcdf2cYcS_4sDkVjbydb5Ig_GErxQt9nzFIziQw","use":"sig"},{"alg":"RS256","e":"AQAB","kid":"Nq1Bi1kSLgicqEacHZdeXe8YE4qRKMuOajCIfpK227c=","kty":"RSA","n":"t123SEijmFH2T4jWqMmIRbwRV4Cw8UVJTnBt5ikJ6s-e86aaIL41FP4ONaWCsiPeKWVZDFnEt6PaDXhBYoiGMB_AVVMmjAwLEnc92EQmtitRVbKKabI73iAJVhgItHFbLr__kGo1rT9tkhgd-SrFC8n67JUqN0azz2X1O9oHLw3cZlAROQfEo6Sjw22cH24aHRosOWVe6rA2vxKm1lYa18QSxzJWjH9iTenSBvrIS7WvLETMUAI90j0QEIHEapWg7E8Z3Nkay3qnSNJ27yCjKVlg2daGL9Y_VVcD-7erUr536gzrVVcofcuPIuz2eZV84zJ23bylvb-IG6vn2l1v0w","use":"sig"}]}'

    j=json.loads(jwks)
    public_key=j['keys'][0]
    print("PUBLIC KEY")
    print(public_key)

    public_key=json.dumps(public_key)
    public_key = RSAAlgorithm.from_jwk(public_key)
    
    print("audience: " + app_client_id)
    try:
        decoded = jwt.decode(token, public_key, algorithms='RS256', audience=app_client_id)
    except:
        print ('Error validating token: ' +  str(sys.exc_info()[0]))
        traceback.print_exc(file=sys.stdout)
        return False

    print("DECODED:")
    print(decoded)

    # since we passed the verification, we can now safely
    # use the unverified claims
    claims=jwt.decode(token, verify=False)
    print("CLAIMS")
    print(claims)

    # additionally we can verify the token expiration
    if time.time() > claims['exp']:
        print('Token is expired')
        return False
    
    # and the Audience  (use claims['client_id'] if verifying an access token)
    aud=claims['aud'] 
    if aud != app_client_id:
        if aud==None: print('aud is None')
        else: print('Token was not issued for this audience' + aud)
        return False
    
    return claims
        
# the following is useful to make this script executable in both
# AWS Lambda and any other local environments
if __name__ == '__main__':
    # for testing locally you can enter the JWT ID Token here
    event = {'token': ''}
    lambda_handler(event, None)
