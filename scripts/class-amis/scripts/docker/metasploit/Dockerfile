FROM debian:sid

#installing metasploit from source due to platform conflicts
#https://github.com/rapid7/metasploit-framework/wiki/Setting-Up-a-Metasploit-Development-Environment

RUN useradd -rm -d /tools -s /bin/bash -g root -G sudo -u 1001 hacker
RUN echo "hacker:pass1234" | chpasswd

#change working directory and make hacker the owner
WORKDIR /tools
RUN chown hacker /tools

#run all this as root
RUN apt-get update -y
RUN apt-get install -y sudo
RUN apt-get install -y software-properties-common

#metasploit dependencies
RUN apt install -y git autoconf build-essential libpcap-dev libpq-dev zlib1g-dev libsqlite3-dev

#Ruby make dependencies
RUN apt-get install -y git-core curl libssl-dev libreadline-dev libyaml-dev sqlite3 \
libxml2-dev libxslt1-dev libcurl4-openssl-dev libffi-dev gcc g++ make automake autoconf

#postres for metasploit
RUN apt update && sudo apt-get install -y postgresql postgresql-client
RUN service postgresql start && sudo update-rc.d postgresql enable

#get metasploit code
RUN git clone https://github.com/rapid7/metasploit-framework.git

#if needed, check ruby version and install correct version in container
RUN cat /tools/metasploit-framework/.ruby-version

#Download Ruby
RUN curl -O https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.2.tar.bz2

#unpack ruby tar
RUN tar xvf ruby-2.7.2.tar.bz2
WORKDIR /tools/ruby-2.7.2

#install ruby
RUN ./configure
RUN make
RUN make install

#install metasploit
WORKDIR /tools/metasploit-framework
RUN gem install bundler
RUN bundle install
RUN mkdir /tools/.msf4
RUN chown -R hacker /tools/.msf4

#setup metasploit db
USER hacker

#this command is weird - it has a continuation onto the next line but there is
#a carriage return in here to make this work - do not change it!!
RUN echo -e '\r \
\r' /msfdb init
RUN ./msfdb init --help

#create an alias to msfconsole
RUN echo 'alias msfconsole="pushd /tools/metasploit-framework && ./msfconsole && popd"' >> ~/.bash_aliases

ENTRYPOINT /tools/metasploit-framework/msfconsole
