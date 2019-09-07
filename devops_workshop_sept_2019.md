## 1 Server Prep

For the server we can use any provider as long as they provide SSH access. For the guide we using an Ubuntu 16.04 box.
Once you retrieve your SSH key pair we use it to connect to our instance. In this case my provider (AWS) gave me a .pem file.

```bash
$ ssh -i path/to/your/key root@SERVER_IP
# once logged in
$ sudo su
```
Now you should be logged as a `root` user.

### 1.1 Creating a sudoer User

We want to create a sudoer to run stuff like software updates and other things that require `sudo`. Later on we will disable the login for root user (for security reasons) and leave this user instead.

For now, we will name our sudoer `john`. As `root` we run the following commands:
```bash
$ adduser john --disabled-password
```
The system will ask us for some info (like first and last name, etc), they're optional and you can leave everything blank.

Now we add the user `john` to the `sudo` group.
```bash
$ usermod -aG sudo john
```
Then we edit `visudo` to allow sudoers to run `sudo` without a password
```bash
visudo
#look for this line
%sudo  ALL=(ALL:ALL) ALL
#change it for this
%sudo ALL=(ALL) NOPASSWD: ALL
```
With this now we have an user with no password able to use sudo. We can test it login into the user and running a command with sudo.
```bash
$ su john
$ sudo -v
#if no error is shown then this user can use sudo
```

Before going back to our `root` session, copy your public (.pub) key in `.ssh/authorized_keys`. Create the directory if it's not there:
```bash
# remember, we should be logged as the sudoer john!
$ su john
$ cd
$ mkdir .ssh
$ touch .ssh/authorized_keys
$ chmod 700 .ssh
$ chmod 644 .ssh/authorized_keys
```
Then edit the .ssh/authorized_keys with your favorite text editor and paste your `.pub` key. You can test this by opening a new terminal tab and connecting to the server with this new user.
```bash
$ ssh -i path/to/key john@SERVER_IP
```
We go back to our previous tab and go back to our root session by writing `exit` or pressing `ctrl + a + d`.

### 1.2 Disabling root and changing port 22

Leaving root is dangerous so we'll disable it and change the default SSH port.
```bash
$ nano /etc/ssh/sshd_config
```

```
Port 22 # change this to whatever port you wish to use, we'll use 333 for this example:
...
PermitRootLogin no
PasswordAuthentication no
...
PubkeyAuthentication yes
ChallengeResponseAuthentication no
```

At the end of sshd_config, enter:

```
UseDNS no
AllowUsers john myapp
```

Exit and reload the daemon.
```bash
$ sudo systemctl reload sshd
```
### 1.3 Install ufw and block/allow ports (optional)


Usually Ubuntu ships with ufw, otherwise install it. You may skip this step if your hosting provider already has a firewall service (like AWS' security groups)
```bash
$ sudo apt-get install ufw
```
Check the open ports (should be only SSH):
```bash
$ netstat --listening --tcp
```

Then allow SSH. Remember that our new SSH port is 333.
```bash
$ ufw deny 22 && ufw allow 333 && ufw logging off && ufw enable && ufw status
```

It's important to only open ports for services we're currently using and nothing else.

### 1.4 Creating an application User without sudo access

By adding www-data as part of the group apache can access the static files without sharing it with other users

```bash
# as root
$ adduser myapp --disabled-password
$ adduser www-data myapp
$ sudo chmod  750 /home/myapp/
$ su myapp
$ cd
$ mkdir .ssh
$ touch  .ssh/authorized_keys
$ chmod 700 .ssh
$ chmod 644 .ssh/authorized_keys
$ exit
```

### 1.5 Handshake with Github and Bitbucket

Log in as `myapp` user for the next few steps.

Shake hands with Github/Bitbucket and Generate a public/private key pair:
```bash
$ su myapp
$ cd
$ ssh -T git@github.com
$ ssh -T git@bitbucket.org
```

### 1.6 Create pub key and add it to Github

Generate a key
```bash
$ ssh-keygen -t rsa
```
Now add the keys as a deployment key to your repo, instructions for [Github](https://developer.github.com/guides/managing-deploy-keys/) and [Bitbucket](https://confluence.atlassian.com/display/BITBUCKET/Use+deployment+keys).

## 2 Dependencies installation

### 2.1 Ruby (with rbenv)

We'll use rbenv to handle our ruby instllation and versions.

```bash
$ cd
$ git clone https://github.com/rbenv/rbenv.git ~/.rbenv
$ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc
$ echo 'eval "$(rbenv init -)"' >> ~/.bashrc
$ exec $SHELL
# we also place the echo lines in a .bash_profile so it works when executing the script remotely
$ echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
$ echo 'eval "$(rbenv init -)"' >> ~/.bash_profile

$ git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
$ echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~/.bashrc
$ exec $SHELL

$ RUBY_CONFIGURE_OPTS="--disable-install-doc" rbenv install 2.5.1
$ rbenv global 2.5.1
```
If something goes wrong, like saying it can't build it, then go back as root and install the following packages.
```bash
$ apt-get update
$ apt-get install zlib1g-dev build-essential
```

Then we check the version to see if ruby was installed properly.

```bash
$ ruby -v
```
We finish off installing bundler
```bash
$ gem install bundler
```

### 2.2 Installing Rails (its dependencies)

Login as `john`

We'll install the following
- NodeJS
- PostgreSQL
- Nginx

```bash
$ curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
$ sudo apt-get update
$ sudo apt-get install git-core curl automake autoconf libtool libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev software-properties-common libffi-dev nodejs  postgresql postgresql-contrib libpq-dev nginx
```

If any of these fails, try to install it individually first then the rest.

### 2.3 Creating a user for PostgreSQL
You might skip this step if your DB is in another server/service like AWS RDS

Setup postgres user for the app
```bash
$ sudo su - postgres
createuser --pwprompt myapp
createdb -O myapp myapp_production
exit
```

The password you type in here will be the one to put in your my_app/current/config/database.yml later when you deploy your app for the first time.

## 3 Cloning the app

Log in as `myapp` and clone your app so we can install the gems.
```bash
$ cd
$ git clone git@github.com:Zauvohi/density-blog.git app
$ cd app
$ bundler install
```
You might encounter some errors while trying to install your gems, chances are you might need to log in as `john` again and install some dependencies, remember that this user cannot use `sudo`.

## 4 Nginx
Log in as john
### 4.1 Basic configuration
```bash
$ sudo nano /etc/nginx/sites-available/default
```

```
upstream puma {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    #server_name mydomain;

    root /home/myapp/app/public;

    try_files $uri/index.html $uri @puma;

    location ^~ /assets/ {
      gzip_static on;
      expires max;
      add_header Cache-Control public;
    }

    location @puma {
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_redirect off;

    proxy_pass http://puma;
  }


  location /cable {
    proxy_pass http://puma;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "Upgrade";

    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto https;
    proxy_redirect off;
  }

    error_page 500 502 503 504 /500.html;
    client_max_body_size 4G;
    keepalive_timeout 10;
}

```

## 5 Puma
First we need to check how many cores we have in our server with this comand
```bash
$ grep -c processor /proc/cpuinfo
```
In our local project we open `config/puma.rb`
### 5.1 Setting up Puma
This is a basic configuraiton for puma
```ruby
# Change to match your CPU core count
workers 1

# Min and Max threads per worker
threads 1, 6

app_dir = File.expand_path("../..", __FILE__)
shared_dir = "#{app_dir}/shared"

# Default to production
rails_env = ENV['RAILS_ENV'] || "production"
environment rails_env
control_app_url = "tcp://127.0.0.1:3000"
activate_control_app control_app_url, { auth_token: ENV.fetch("CONTROL_APP_TOKEN") { '12345' } }
# Logging
stdout_redirect "#{shared_dir}/logs/puma.stdout.log", "#{shared_dir}/logs/puma.stderr.log", true

# Set master PID and state locations
pidfile "#{shared_dir}/pids/puma.pid"
state_path "#{shared_dir}/pids/puma.state"
activate_control_app

on_worker_boot do
  require "active_record"
  ActiveRecord::Base.connection.disconnect! rescue ActiveRecord::ConnectionNotEstablished
  ActiveRecord::Base.establish_connection(YAML.load_file("#{app_dir}/config/database.yml")[rails_env])
end

```

Commit these changes and push them to your repository.

## 6 Deployment scripts
This script will be in the home directory for the user.
```bash
#loggged in as myapp
$ cd
$ touch deploy.sh
$ chmod a+x deploy.sh
$ nano deploy.sh
```
These are the contents
```bash
#!/bin/bash
set -e

cd "$(dirname "$0")"
cd app
source .env.local
# this part updates our repository
rbenv rehash

git checkout "$APP_BRANCH"
git pull origin "$APP_BRANCH"
git reset --hard HEAD

# this other part boots our server
mkdir -p shared/pids shared/sockets shared/log

bundle install --without development test --deployment

bundle exec rake db:migrate assets:clean assets:precompile

[ -f shared/pids/puma.pid ] && [ -e /proc/"$(cat shared/pids/puma.pid)" ] && kill "$(cat shared/pids/puma.pid)"
bundle exec puma -C config/puma.rb -d -p "$RAILS_PORT"


echo "deployment completed"
```
### 6.1 Environment variables
We place our environment variables in a `.env` file called `.env.local`
```bash
#logged as myapp
touch app/.env.local
nano app/.env.local
#these are the variables we need for this example
export RAILS_ENV="production"
export APP_BRANCH="master"
export RAILS_PORT=3000
export DB_HOST="localhost"
export DB_USERNAME=DB_USERNAME
export DB_PASSWORD=DB_PASSWORD
export RAILS_MAX_THREADS=5
export SECRET_KEY_BASE=SECRET_FOR_PROD
```
### 6.2 Run it!
To deploy the app we run this script through SSH
```bash
$ ssh myapp@MY_SERVER -p 333 /bin/bash -l deploy.sh
```
And look at it go.
