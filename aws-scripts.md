# Use this context when writing AWS scripts

* All variables should be upper case with each word separated with _
* When propmting for variables, use a while loop to prompt until a valid value is set.
* Use functions for repetetitve code wherever possible. Name the functions with all lowercase and a dash (-) between each word. Put each function in a file in the functions/ directory and name the file with the name of the function and extension .sh. 
* Before creating a new function check to see if a function already exists that can perform the neccessary task.
* Functions should only do one thing. Break functions that do more than one thing into multiple functions.
* Check all variables to make sure they are set.
* Check all variable values to make sure they are set with proper values according to the AWS documentation.
* When creating a resource, first check to see if the resource exists, and ask the user if they want to update the existing resource instead of creating a new one. If the user responds with y then proceed.
* When updating a resource check if you need to alter dependent resources in order to udpate it and ask the user if they want to do that. If they respond y then update the related resource also and proceed.
* When writing policies ensure all values and constucts are valid.
* When asking for a CLI profile, check to see that it is valid after setting the variable using aws sts get-caller-identity
* When creating a list of AWS services use this command:  grep "AVAILABLE SERVI" -A1900 | grep o | cut -d " " -f9- | grep -v 'aws help topics'
  
  
