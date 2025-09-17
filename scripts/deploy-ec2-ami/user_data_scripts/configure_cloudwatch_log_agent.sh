#!/bin/bash

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

# Install CloudWatch agent based on OS
case $OS in
    "ubuntu")
        apt-get update
        wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
        dpkg -i amazon-cloudwatch-agent.deb
        ;;
    "amzn"|"rhel"|"centos")
        yum update -y
        wget https://s3.amazonaws.com/amazoncloudwatch-agent/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm
        rpm -U amazon-cloudwatch-agent.rpm
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << EOF
{
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "{{prompt: log_file_path}}",
                        "log_group_name": "{{prompt: cloud_watch_log_group}}",
                        "log_stream_name": "{{prompt: log_stream_name}}",
                        "timezone": "{{prompt: timezone}}"
                    }
                ]
            }
        }
    },
    "metrics": {
        "namespace": "{{prompt: metrics_namespace}}",
        "metrics_collected": {
            "mem": {
                "measurement": ["mem_used_percent"]
            },
            "disk": {
                "measurement": ["used_percent"],
                "metrics_collection_interval": 60,
                "resources": ["*"]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
