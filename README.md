# OroCRM Docker builder on Vagrant 
## !> Automated docker builds [available here](https://github.com/djocker) <!

### Vagrant box for build and run a [BAP Application](http://www.orocrm.com/oro-platform) in [Docker](https://www.docker.com/) Container

## Prepare Vagrant Environment

Install VirtualBox https://www.virtualbox.org/wiki/Downloads

Install Vagrant from http://www.vagrantup.com/downloads

Install Vagrant plugins:

    vagrant plugin install vagrant-vbguest
    vagrant plugin install vagrant-hostmanager

## Usage

#### Start vagrant and login via ssh

    vagrant up && vagrant ssh
    
### Generate SSH keys

For checkout sources you need to generate ssh keys. Run command below and follow instructions:

    ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa
    
When the key will be generated, you need to add public key into your github account. To get a key run the command:

    cat /home/vagrant/.ssh/id_rsa.pub

### Build docker images from your source code
    
For building a docker image, you can use your own source code of [Application](https://github.com/orocrm/platform-application), or any BAP based application ([OroCRM](https://github.com/orocrm/crm-application), [OroCommerce](https://github.com/orocommerce/orocommerce-application), etc).

    /vagrant/build.sh <git repository uri> <branchname or tags/tagname> <image name prefix> <image tag> [base-image-name]

Example: build a docker image of OroCRM Community Edition from official repository:

    /vagrant/build.sh git@github.com:orocrm/crm-application.git tags/1.8.0 orocrm 1.8.0
    
Build with already assembled base image
    
    docker pull scherepanov/bap-base-system
    /vagrant/build.sh git@github.com:orocrm/crm-application.git tags/1.8.0 orocrm 1.8.0 scherepanov/bap-base-system

### Generate a docker-compose.yml for your images

    /vagrant/make-compose-config.sh <image name prefix> <image tag>

Example:

    /vagrant/make-compose-config.sh orocrm 1.8.0

### Run containers

    cd /vagrant
    docker-compose up

If all docker containers started without errors, you can see web installer here: [http://orocrm.loc](http://orocrm.loc)

### Default credentials:

##### Application:

user: `admin`  
password: `admin1111`  
email: `johndoe@example.com`  

##### Database:

host: `db`  
database: `orocrm`  
user: `orocrm`  
password: `orocrm`  

*You can change it in your docker-compose.yml*

## Docker Container Info

**Parameters.yml Variables:**

`APP_DB_DRIVER=pdo_mysql`  
`APP_DB_HOST=db`  
`APP_DB_PORT=3306`  
`APP_DB_USER=orocrm`  
`APP_DB_PASSWORD=orocrm`  
`APP_DB_NAME=orocrm`  
`APP_DB_HOST=db`  
`APP_HOSTNAME=localhost`  
`APP_MAILER_TRANSPORT=smtp`  
`APP_MAILER_HOST=127.0.0.1`  
`APP_MAILER_PORT=`  
`APP_MAILER_ENCRYPTION=`  
`APP_MAILER_USER=`  
`APP_MAILER_PASSWORD=`  
`APP_WEBSOCKET_HOST=websocket`  
`APP_WEBSOCKET_PORT=8080`  
`APP_IS_INSTALLED=`  

**Advanced Variables:**

`CMD_INIT_BEFORE` - Command will be executed before initialization (or installation)  
`CMD_INIT_CLEAN` - Command will be used if application not installed (here you can initiate installation via cli)
`CMD_INIT_INSTALLED` - Command will be used for initialization of already installed application  
`CMD_INIT_AFTER` - Command will be executed after initialization (or installation)  
