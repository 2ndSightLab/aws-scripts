from boto3 import client as boto3_client
import json
import sys
import traceback
import os
import base64

lambda_client = boto3_client('lambda')

def lambda_handler(event, context):
    
    #https://montreal-cloud.2ndsightlab.com/auth.html#id_token=eyJraWQiOiJLRkJEZzI3N01oMDB2NjhYNFhaY2dhWWtiMDFScnp1NU5UOUloQWxldmhnPSIsImFsZyI6IlJTMjU2In0.eyJhdF9oYXNoIjoiZFRWV3picHI4cUczODRxcG5nSUI4USIsInN1YiI6IjhiYWE2YzQ5LTliMGQtNGU5Yi1hNmQ1LTZiZGIxZWQyYjBmYSIsImF1ZCI6IjdwNTI0b3RlcXVrNG0xc2FzYWdncGpmaTl2IiwiZW1haWxfdmVyaWZpZWQiOnRydWUsImV2ZW50X2lkIjoiZTJkZTczMDUtOGRjZS00Nzc4LWJjMDktZDk0YzJhMzVkOTgyIiwidG9rZW5fdXNlIjoiaWQiLCJhdXRoX3RpbWUiOjE1OTA3MzMyODEsImlzcyI6Imh0dHBzOlwvXC9jb2duaXRvLWlkcC51cy1lYXN0LTEuYW1hem9uYXdzLmNvbVwvdXMtZWFzdC0xX0Z6dnZzQVZ2bCIsImNvZ25pdG86dXNlcm5hbWUiOiI4YmFhNmM0OS05YjBkLTRlOWItYTZkNS02YmRiMWVkMmIwZmEiLCJleHAiOjE1OTA3MzY4ODEsImlhdCI6MTU5MDczMzI4MSwiZW1haWwiOiJ0ckAybmRzaWdodGxhYi5jb20ifQ.W5QqyyskbYl-4vUCuR-tI8wIsSZT8YT_9qhOmxZV1v-nDxuNphIjbuWTFGUUCkjqGlHrnerrwYmO29EHRRbNM_0BBYsM6SA8Jy1u2FZ55itvyf7GeemZrilcJVJ3G_XHwtg9LRpj_NHcgZ1QUQtDQQycRYqkx1FTVbK1kncm5_eV0dfBnbnVGZX6T6MDGPJjN1gHZhorjBYh-QgAv58k8QwbutY_aMaJRMBTcbeW7MdZLfKPcPLu77qHBgl1gDmyZkndrO4hem3z0xW8_EEL8geb2lsp2hJVo0FAIc-OIDjA2T9vMIz-4p5ICvicY65s7c4wD2EsOFqC7R77uvsjnw&access_token=eyJraWQiOiJOcTFCaTFrU0xnaWNxRWFjSFpkZVhlOFlFNHFSS011T2FqQ0lmcEsyMjdjPSIsImFsZyI6IlJTMjU2In0.eyJzdWIiOiI4YmFhNmM0OS05YjBkLTRlOWItYTZkNS02YmRiMWVkMmIwZmEiLCJldmVudF9pZCI6ImUyZGU3MzA1LThkY2UtNDc3OC1iYzA5LWQ5NGMyYTM1ZDk4MiIsInRva2VuX3VzZSI6ImFjY2VzcyIsInNjb3BlIjoib3BlbmlkIiwiYXV0aF90aW1lIjoxNTkwNzMzMjgxLCJpc3MiOiJodHRwczpcL1wvY29nbml0by1pZHAudXMtZWFzdC0xLmFtYXpvbmF3cy5jb21cL3VzLWVhc3QtMV9GenZ2c0FWdmwiLCJleHAiOjE1OTA3MzY4ODEsImlhdCI6MTU5MDczMzI4MSwidmVyc2lvbiI6MiwianRpIjoiOTg5NTNkM2MtYzQ1My00YTljLTg0MWYtOWU0MDkwOTM2YTk0IiwiY2xpZW50X2lkIjoiN3A1MjRvdGVxdWs0bTFzYXNhZ2dwamZpOXYiLCJ1c2VybmFtZSI6IjhiYWE2YzQ5LTliMGQtNGU5Yi1hNmQ1LTZiZGIxZWQyYjBmYSJ9.kdNbE1Z1jefb9fNxvMHKyBy48zg1gyBkK1lP_j13aQWg5H453YT8cxSPrTCMyDgTi-Q_AFXQ8bBFDMa2nbwdV8lu63oVFBiHKYsASxJlx4onVk3adThNdPIYZV6Z4wXwElXlnIafOHRWu4I-5LJT5VGObtgYWh17XLG46ob_l-4gCF5wAFMMS4RT4WotJLklBmUC9y-BfOvNSiZrmt_w2F_lnDL-rBNJydpaZlIa2FZDSxcNJCFvgmOwYSXRjEi6eBk5OoGAw0EHHnfaw-KAhCT2xw-WkigTks3B9U3W2zgZCL7zwoKuWaCsVCzOrRsRXTkv4QCYmD_ew873-U5zwg&expires_in=3600&token_type=Bearer
    #pass to the /auth uri which then redirects (this is SO hokey) and converts the # to querystring param
    
    print('THE EVENT')
    print(event)

    request = event['Records'][0]['cf']['request']
    print('REQUEST')
    print(request)
    
    token=None
    
    try:
        uri = request['uri']
        
        print ('URI:')
        print (uri)
        
        
        if uri=='/auth.html': 
            print('FORWARD REQUEST TO AUTH.HTML')
            return request
        
    except:
        token=None
        print ('Error getting URI: ' +  str(sys.exc_info()[0]))
        traceback.print_exc(file=sys.stdout)
        
    try:
        querystring = event['Records'][0]['cf']['request']['querystring']
    
        ps=querystring.split("&")
        for p in ps:
            kv = p.split('=')
            if kv[0]=='id_token':
                token=kv[1]
                break
        if token != None:        
            print("TOKEN FROM QUERYSTRING: " + token)
        else:
            print("NO TOKEN")

    except:
        token=None
        print ('Error parsing token: ' +  str(sys.exc_info()[0]))
        traceback.print_exc(file=sys.stdout)
    
    #If there's no token, redirect to the login page
    if token!=None:
        try:
            region = os.environ['AWS_REGION']
            
            function='arn:aws:lambda:' + region + ':035577010687:function:CLS-2SL3000-montreal-lambda-RegistrationLambda-1SGBY2U6CM8L'
            invoke_response = lambda_client.invoke(FunctionName=function,
                                           InvocationType='Event',
                                           Payload=json.dumps(event))
            
            print('AUTH LAMBDA RESPONSE:')
            print(invoke_reponse)
            payload=invoke_response['Payload']
            p=base64.decode(payload)
            print('PAYLOAD:')
            print(p)

        except:
            token=None
            print ('Error calling auth lambda: ' +  str(sys.exc_info()[0]))
            traceback.print_exc(file=sys.stdout)
            return request
            
    else:
        
        loginurl='https://montreal-auth.2ndsightlab.com/login?client_id=7p524otequk4m1sasaggpjfi9v&response_type=token&scope=openid&redirect_uri=https://montreal-cloud.2ndsightlab.com/auth.html'
        print('redirect to: ' + loginurl)
        
        response = {
            'status': '302',
            'statusDescription': 'Found',
            'headers': {
                'location': [{
                    'key': 'Location',
                    'value': loginurl
                }]
            }
        } 
        
        return response
        
    #if all else fails...
    response = {
        'status': '500',
        'statusDescription': 'Error',
        'body': 'You have reached the point of no retrun. Something went awry.'
        } 
        
    return response
