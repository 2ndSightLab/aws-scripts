FROM golang:1.11.5

RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -

RUN apt-get update && \
    apt-get -y install nodejs git 

RUN npm install -g serverless
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh

WORKDIR /go/src/github.com/2ndSightLab

ADD 2SL-Class-Publisher /go/src/github.com/2ndSightLab/2SL-Class-Publisher/

WORKDIR /go/src/github.com/2ndSightLab/2SL-Class-Publisher

COPY entrypoint.sh .
RUN chmod +x /go/src/github.com/2ndSightLab/2SL-Class-Publisher/entrypoint.sh

ENTRYPOINT [ "/go/src/github.com/2ndSightLab/2SL-Class-Publisher/entrypoint.sh" ]

