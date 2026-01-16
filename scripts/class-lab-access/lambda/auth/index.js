'use strict';
var jwt = require('jsonwebtoken');
var jwkToPem = require('jwk-to-pem');
const querystring = require('querystring');
const AWS = require('aws-sdk');
var ssm = new AWS.SSM({region: 'us-east-1'});
var email='chicago202001@2ndsightlab.com'

/* FYI THIS CODE IS HORRIBLE */
exports.handler = async (event, context, callback) => {

    var region='us-east-1';
    var pems = {};
    var loginuri='https://chicago202001-cloud.2ndsightlab.com/index.html'
    var authuri='https://chicago202001-cloud.2ndsightlab.com/auth.html'
    var userpoolid = 'us-east-1_0EnssOHc8';
    var jwks = '{"keys":[{"alg":"RS256","e":"AQAB","kid":"fYyINcDTO+WcDUOsIUf4EhR6/VfieojmE/T0Z19EoXs=","kty":"RSA","n":"jbJEIl6mSGmP46BJpXRbgk3vgtHY508f6CSNciQegzpfondIGKOhA4au5jl03iFjZpG66y7yEOb8qxoCfdn4LfIBM1WeP2s6alkUFvRFo8gvGE1i9RKV7jPT74o6lDIPv_c4whVLF6Bgmu2d7pzAxORhQOw536vNd0wJ1EFMRrra_WjVE9EwzugEb-80_Fk7A6oSOocbG9HZcPo9mLfTQ-9wvOYptqyE5sD45pVfOPxxvTVQVVi-RepQvan3km-BGwuUFvGAftsR5ywhIlY4H0Z1xp8JItVMA70DIK7B4fobFHDVyjz309YUPxos9HKY4BMsmZNcAwZhbL008q44Xw","use":"sig"},{"alg":"RS256","e":"AQAB","kid":"4Qki6hPW1GPrGTqBW0Dq3S/jouJRRDR2WJuzDnnBEYo=","kty":"RSA","n":"hDTIqSSOQUWbbrlJisofLO1AMqhb36PzN9TPcjzLFaKHkvo9_BoGc4JlUFUJemXjbspMTdyhQAr9_bH-mAX_WicqKoSMQTFmrzmZyOFeq2ubyh18B7q6scSGYMXbSU153fJzXju0lCIQM1R8Z9560Jv4-63Seso9OELIo1_cj_31MvEMePqWjncPpKyrJzXyOyawF4B1gUHJbH3uXaGNepWwx_plkGVSDQp93Royui5pJ3aVpHOSKT9Pyqsv7PfCs3Tk2FRuBxku_ba4cGKKe-PI0ge1HhdDRk8A8Ln8pOCgrk71cTiPABzPE6bs9WLjc2gtWK010EbO1AT2FwceBw","use":"sig"}]}';


    const response401 = {
            status: '302',
            statusDescription: 'Unauthorized: Redirect',
            headers: {
                location: [{
                    key: 'Location',
                    value: loginuri,
                }],
            },
    };

    const response302 = {
        status: '302',
        statusDescription: 'Unauthorized: Redirect',
        headers: {
            location: [{
                key: 'Location',
                value: authuri,
            }],
        },
    };

  /*
    would like to get this stuff out of SSM in the future.

    const data = await ssm.getParameters({
        Names: ['AuthLambdaRegion',
                'AuthLambdaUserPoolId',
                'AuthLambdaJwks',
                'AuthLambdaLoginUrl'],
        WithDecryption: false }).promise();

    console.log(data.Parameters);

   for (const i of data.Parameters) {
        if (i.Name === 'AuthLambdaRegion')
            region=i.Value

        if (i.Name === 'AuthLambdaUserPoolId')
            userpoolid=i.Value

        if (i.Name === 'AuthLambdaJwks')
            jwks=i.Value;
    }

    if (region==null){
        console.log("region is null");
        callback(null, response401);
        return true;
    }

    if (userpoolid==null){
        console.log("userpoolid is null");
        callback(null, response401);
        return true;
    }

    if (jwks==null){
        console.log("jwks is null");
        callback(null, response401);
        return true;
    }

  */
     //first check to see if we even have records
    if (event.Records==null){
        console.log("No records found");
        console.log(response401);
        callback(null, response401);
    }

    //get the request
    const cfrequest = event.Records[0].cf.request;

    //console.log("request: " + JSON.stringify(cfrequest));

    //ignore all this if it's the auth.html page
    if (cfrequest.uri=='/auth.html'){
        console.log("proceed to auth.html");
        callback(null, cfrequest);
        return true;
    }

    const params = querystring.parse(cfrequest.querystring);
    const jwtToken = params.id_token
    const awsacctnum = params.awsacctnum
    const gmail = params.gmail
    const clientid = params.client_id

    if(clientid) {
        console.log("client_id - redirect to auth");
        callback(null, response302);
        return true;
    }

    var contenturi=cfrequest.uri;


    var iss = 'https://cognito-idp.' + region + '.amazonaws.com/' + userpoolid;

    var keys = JSON.parse(jwks).keys;
    for(var i = 0; i < keys.length; i++) {
        //Convert each key to PEM
        var key_id = keys[i].kid;
        var modulus = keys[i].n;
        var exponent = keys[i].e;
        var key_type = keys[i].kty;
        var jwk = { kty: key_type, n: modulus, e: exponent};
        var pem = jwkToPem(jwk);
        pems[key_id] = pem;
    }

    //log only in debug mode
    //console.log("params: " + querystring.stringify(params));
    //console.log('USERPOOLID=' + userpoolid);
    //console.log('region=' + region);
    //console.log('pems=' + pems);
    //console.log('jwt=' + jwtToken)
    //console.log(cfrequest.querystring = querystring.stringify(params));
    //console.log('params ' + querystring.stringify(params));

    if(!jwtToken) {
        console.log("no jwt token");
        callback(null, response401);
        return true;
    }

    var decodedJwt = jwt.decode(jwtToken, {complete: true});
    if (!decodedJwt) {
        console.log("Not a valid JWT token");
        callback(null, response401);
        return true;
    }

    //console.log(decodedJwt.payload);

    //Get the kid from the token and retrieve corresponding PEM
    var kid = decodedJwt.header.kid;
    var pem = pems[kid];
    if (!pem) {
        console.log('Invalid access token');
        callback(null, response401);
        return true;
    }

    if (decodedJwt.payload.iss != iss) {
        console.log("invalid issuer");
        callback(null, response401);
        return true;
    }

    //Verify the signature of the JWT token to ensure it's really coming from your User Pool
    jwt.verify(jwtToken, pem, { issuer: iss }, function(err, payload) {
      if(err) {
        console.log('Token failed verification');
        callback(null, response401);
        return true;

      } else {

        console.log('Successful verification');
        cfrequest.uri=contenturi;

        if (!awsacctnum) {
            console.log('no acctnum')
        }else{

            var message = "ACCOUNT NUMBER: " + awsacctnum + " GMAIL: " + gmail;
            console.log (message);

            console.log('accountnum')
           //SEND EMAIL IF ACCOUNT ID IN REQUEST
            var emailparams = {
              Destination: { /* required */
                ToAddresses: [
                  email,
                ]
              },
              Message: { /* required */
                Body: { /* required */
                  Text: {
                   Charset: "UTF-8",
                   Data: message
                  }
                 },
                 Subject: {
                  Charset: 'UTF-8',
                  Data: 'STUDENT SUBMITTED ACCOUNT ' + gmail
                 }
                },
              Source: email, /* required */
              ReplyToAddresses: [
                 email,
              ],
            };

            // Create the promise and SES service object
            var sendPromise = new AWS.SES({apiVersion: '2010-12-01'}).sendEmail(emailparams).promise();

            // Handle promise's fulfilled/rejected states
            sendPromise.then(
              function(data) {
                console.log(data.MessageId);
              }).catch(
                function(err) {
                console.error(err, err.stack);
              });
        }
      }
    });

    console.log("Completing request: " + cfrequest.uri)
    callback(null, cfrequest);
    return true;

};
