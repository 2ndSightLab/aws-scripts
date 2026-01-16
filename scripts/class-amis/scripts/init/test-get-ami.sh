#get latest linux arm ami
param='ami.linux.arm.base.baseami.arm64'
arch='arm64'
aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=amzn2-ami-hvm*" \
       "Name=root-device-type,Values=ebs" \
       "Name=architecture,Values=$arch" \
    --query 'Images[*].[ImageId,CreationDate,Name]' \
    --output text \
		| sort -r -k2 | head -1 | cut -f1


