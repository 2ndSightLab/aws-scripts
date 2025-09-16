# AWS Scripts

__Summary__

This repository contains bash scripts to do whatever is required on AWS.

__Global Context__

* All scripts adhere to the requirements in this README.md.
* If a script-specifc README.md in the script folder for that script conflicts, this file takes precedence.
* If there is a conflict, the user is notified when generating the script.

__Scripts folder__

* Each script is in the /scripts folder in a sub folder with a README.md that explains how to implement the script.
* Source existing scripts when possible instead of writing new scripts.

__Functions__

* The functions folder contains bash functions.
* File names match function names plus a .sh extension.
* Before writing new code check to see if a function exists that can be used insted.
* Any duplicated code is moved to a function and scripts are adjsuted to call the function.
* Before creating a new function check to see if a function already exists that can perform the neccessary task.
* A function only performs one task. If it contains multiple tasks it is split into multiple functions.
* All variables in functions are declared with local scope.

__Color__

* Turn color off on every AWS command with output using:  --color off

__Recursion__

* Use recursion when possible to limit the amount of code required to solve a problem.
* Any recursively called functions have an argument passed in that can be set to exit recursion if a threshold is met.
* The default number of recursive calls is 15 before failing but this can be overriden in the instructions for a script.
  
__Bash scripts__

* All file and function names are lowercase with a _ between words and scripts end with .sh
* All bash scripts have a shebang and a -e to fail on error.

__Variables__

* All variables should be upper case with each word separated with _.
* When propmting for variable avlues, use a while loop to prompt until a valid value is set.
* Check all variables to make sure they are set.
* Check all variable values used as AWS CLI command arguments to make sure they are set with proper values according to the AWS documentation.
* Check any variables that are used in code that requires a specific data type to make sure the variable is the correct data type.

__Error messages__

* All error messages clearly state the problem and how to fix the error.

__AWS Resources__

* When creating an AWS resource, first check to see if the resource exists, and ask the user if they want to update the existing resource instead of creating a new one. If the user responds with y then proceed.
* When updating a resource check if you need to alter dependent resources in order to udpate it and ask the user if they want to make those changes. If they respond y then update the related resource also and proceed.

__AWS Policies__

* When writing policies ensure all values and constucts are valid.
* When asking for a CLI profile, check to see that it is valid after setting the variable using aws sts get-caller-identity
* When creating trust policies associated with roles always require an IP address or MFA in the conditions or both.
  
__AWS Services__

* When creating a list of AWS services use this command: grep "AVAILABLE SERVI" -A1900 | grep o | cut -d " " -f9- | grep -v 'aws help topics'

__Security__

* Check for an alert on any security vulnerabilities when generating code including generated or requested code or vulnerabilities in the AWS tools or console.
