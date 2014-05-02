##Canvas LMS


###Why Canvas?

In my search to find a LMS (Learning Management System) that would serve my needs I found Canvas.  While there are a number of open source LMS platforms, they were either far too much for what I needed or were almost impossible to set up and configure.

That's where Canvas comes in.  Does Canvas have any drawbacks?  Yep.  It's not going to serve up your SCORM compliant content, but if you have PowerPoints or videos, Canvas will work just fine.  Canvas is also quite easy to set up, once you understand how Ruby, Gems, Apache, and Redis all work together.


---

This install document assumes the following:

* That the user will be utilizing this platform in a production setting.  If you would like to use the system in a test or development environment, please see [here.](https://github.com/instructure/canvas-lms/wiki/Quick-Start)
* That the user will be using Ubuntu 12 as the base operating system.
* That the user's environment allows them to install PPAs.  If you do not know what a PPA is, please see [here.](http://askubuntu.com/questions/4983/what-are-ppas-and-how-do-i-use-them)
* That the user has a basic understanding of Ruby and how to install gems.
* That the user is willing to use Apache as the web server.  NGINX and LIGHTTPD are not discussed in the materials.
* That the user is willing to use Redis, not MEMCACHED, as a caching server. 
* That the user understands that this is open source software, it is not commercially supported, and that the user installs and uses the software and related materials at their own risk.

---
##Installing Requirements for Canvas

##Note:  This install will not work on the new LTS release of Ubuntu. Still working on that.
---

###First Update Your System
	>sudo apt-get update
	>sudo apt-get upgrade

###Install OpenSSH for Remote Management
	>sudo apt-get install ssh
	
###Install the Dependencies
	>sudo apt-get install ruby1.9.3 zlib1g-dev libxml2-dev libmysqlclient-dev libxslt1-dev imagemagick libpq-dev libxmlsec1-dev libcurl4-gnutls-dev libxmlsec1 build-essential openjdk-7-jre unzip

###Install Git
	>sudo apt-get install git-core

###Install PPA Tools
	>sudo apt-get install python-software-properties
	
###Install Brightbox Ruby PPA and Install Ruby
	>sudo apt-add-repository ppa:brightbox/ruby-ng
	>sued apt-get update
	>sudo apt-get install ruby rubygems ruby-switch
	>sudo apt-get install ruby1.9.3

###Install NODE.JS via PPA 
	>sudo add-apt-repository ppa:chris-lea/node.js
	>sudo apt-get update
	>sudo apt-get install nodejs
	
###Install the Required Ruby Gems
Canvas will not work with the 1.6.1 version of bundler.  As such, you need to back it up to version 1.5.3.

	>sudo gem1.9.3 install bundler -v '1.5.3'
	>sudo gem install rake
			
###Install Passenger Phusion
	>sudo apt-get install passenger-common1.9.1
		
###Install Postgres
	>sudo apt-get install postgresql-9.1

###Install Apache and Passenger Requirements
	>sudo apt-get install libapache2-mod-passenger apache2
	
###Enable All Needed Mods for Apache2
	>sudo a2enmod passenger
	>sudo a2enmod ssl
	>sudo a2enmod rewrite
	
###Install Sqlite (Resolves Test Dependencies)
	>sudo apt-get install libsqlite3-dev
	
###Install Postfix as a SmartHost
Yes, Canvas can send mail on it's own, but I like to use Postfix to have better control.  In TASKSEL, set Postfix up as a "Smarthost".  You will need to edit the main.cf file for Postfix to point it to whatever mail server will ultimately receive the email.

	>sudo apt-get install postfix mailutils libsasl2-2 ca-certificates libsasl2-modules
	
---
							
##Building Canvas

---

###Download Canvas Via Git

	>cd /var
	>sudo git clone https://github.com/gluelue/canvas-lms canvas
	>cd canvas/
	>sudo git branch --set-upstream stable origin/stable
	
###Set Up Your Database
Make sure that you record the password you assign to the the database user.

	>sudo -u postgres createuser canvas --no-createdb --no-superuser --no-createrole --pwprompt
	>sudo -u postgres createdb canvas_production --owner=canvas
	>sudo -u postgres createdb canvas_queue_production --owner=canvas
	
###Copy Config Files Needed By Canvas
Note: Stay in the /var/canvas directory from this point forward.  

	>sudo cp config/database.yml.example config/database.yml
	>sudo cp config/domain.yml.example config/domain.yml
	>sudo cp config/security.yml.example config/security.yml
	>sudo cp config/outgoing_mail.yml.example config/outgoing_mail.yml
	
###Edit the Config Files Needed By Canvas

	>sudo vi config/database.yml 
(Enter the postgres user and password under "Production" and "Production Queue" that you created earlier.)

	>sudo vi config/domain.yml 
(Set the domain and domain prefix that should be used by the system.  E.g. canvas.sample.com, canvas.sample.local, etc.)

	>sudo vi config/security.yml
 (Set a random character set of at least 25 characters under "Production".)
  
  	>sudo vi config/outgoing_mail.yml
 (Set the address, port, username and password, as well as the domain and default name.)
 
###Install NPM With "--unsafe-perm" For Javascript Needs
Note:  If you do not install with "--unsafe-perm", a needed file will not be installed and the whole install will fail.

	 >sudo npm install --unsafe-perm
 
###Build the Bundle & Populate your Database
	>sudo bundle _1.5.3_ install --path vendor/bundle --without=sqlite
 	>sudo RAILS_ENV=production bundle _1.5.3_ exec rake db:initial_setup
 
Near the end of the DB setup, you'll be asked for an email address, password, and organization name to use for the install.  Make sure you record this information.
 
###Compile Assets For Use by Canvas
	>sudo bundle _1.5.3_ exec rake canvas:compile_assets

---
##Securing Canvas

---

###Restrict Canvas
Set up or choose a user you want the Canvas Rails application to run as. This can be the same user as your webserver (www-data on Debian/Ubuntu), your personal user account, or something else. Once you've chosen or created a new user, you need to change the ownership of key files in your application root to that user, like so

	>sudo adduser --disabled-password --gecos canvas canvasuser
	>sudo mkdir -p log tmp/pids public/assets public/stylesheets/compiled
	>sudo touch Gemfile.lock
	>sudo chown -R canvasuser config/environment.rb log tmp public/assets \
                                  public/stylesheets/compiled Gemfile.lock config.ru
                                  
Passenger will choose the user to run the application on based on the ownership settings of config/environment.rb. Note that it is probably wise to ensure that the ownership settings of all other files besides the ones with permissions set just above are restrictive, and only allow your canvasuser user account to read the rest of the files.

###Restrict Access to Canvas Files

There are a number of files in your configuration directory (/var/canvas/config) that contain passwords, encryption keys, and other private data that would compromise the security of your Canvas installation if it became public. These are the .yml files inside the config directory, and we want to make them readable only by the canvasuser user.

	>sudo chown canvasuser config/*.yml
	>sudo chmod 400 config/*.yml

Note that once you change these settings, to modify the configuration files henceforth, you will have to use: 

	>sudo.

###Configure Canvas with Apache

Now we need to tell Passenger about your particular Rails application. 

First, disable any Apache VirtualHosts you don't want running. On Debian/Ubuntu, you can simply unlink any of the symlinks in the /etc/apache2/sites-enabled subdirectory you aren't interested in. In other set-ups, you can remove or comment out VirtualHosts you don't want.

	>sudo unlink /etc/apache2/sites-enabled/000-default
	
Now, we need to make a VirtualHost for your app. On Debian/Ubuntu, we are going to need to make a new file called /etc/apache2/sites-available/canvas. On other setups, find where you put VirtualHosts definitions. You can open this file like so:

	>sudo vi /etc/apache2/sites-available/canvas

In the new file, or new spot, depending, you want to place the following snippet. 

Note:  You will want to modify the lines designated ServerName(2), ServerAdmin(2), DocumentRoot(2), SetEnv(2), Directory(2), and probably SSLCertificateFile(1) and SSLCertificateKeyFile(1), discussed below in the "Note about SSL Certificates".

	<VirtualHost *:80>
	  ServerName canvas.example.com
	  ServerAlias files.canvas.example.com
	  ServerAdmin youremail@example.com
	  DocumentRoot /var/canvas/public
	  RewriteEngine On
	  RewriteCond %{HTTP:X-Forwarded-Proto} !=https
	  RewriteCond %{REQUEST_URI} !^/health_check
	  RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [L]  
	  ErrorLog /var/log/apache2/canvas_errors.log
	  LogLevel warn
	  CustomLog /var/log/apache2/canvas_access.log combined
	  SetEnv RAILS_ENV production
	  <Directory /var/canvas/public>
	    Allow from all
	    Options -MultiViews
	  </Directory>
	</VirtualHost>
	<VirtualHost *:443>
	  ServerName canvas.example.com
	  ServerAlias files.canvas.example.com
	  ServerAdmin youremail@example.com
	  DocumentRoot /var/canvas/public
	  ErrorLog /var/log/apache2/canvas_errors.log
	  LogLevel warn
	  CustomLog /var/log/apache2/canvas_ssl_access.log combined
	  SSLEngine on
	  BrowserMatch "MSIE [2-6]" nokeepalive ssl-unclean-shutdown downgrade-1.0 force-response-1.0
	  BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown
	  # the following ssl certificate files are generated for you from the ssl-cert package.
	  SSLCertificateFile /etc/ssl/certs/ssl-cert-snakeoil.pem
	  SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key
	  SetEnv RAILS_ENV production
	  <Directory /var/canvas/public>
	    Allow from all
	    Options -MultiViews
	  </Directory>
	</VirtualHost>

And finally, if you created this as its own file inside /etc/apache2/sites-available, we'll need to make it an enabled site.

	>sudo a2ensite canvas

###A Note about SSL Certificates

You'll notice in the above Canvas configuration file that we provided directives to an SSLCertificateFile and an SSLCertificateKeyFile. The files specified are self-signed certificates that come with your operating system.

Browsers, by default, are configured not to accept self-signed certificates without complaining. The reason for this is because otherwise a server using a self-signed certificate can risk what's called a man-in-the-middle attack.

If you want to get a certificate for your Canvas installation that will be accepted automatically by your user's browsers, you will need to contact a certificate authority and generate one. For the sake of example, Verisign is a commonly used certificate authority.

For more information on setting up Apache with SSL, please see O'Reilly OnLamp.com's instructions, Apache's official SSL documentation, or any one of many certificate authority's websites.

###Using Redis

Canvas supports two different methods of caching: Memcache and redis. However, there are some features of Canvas that require redis to use, such as OAuth2, so it's recommended that you use redis for caching as well to keep things simple.

Below are instructions for setting up redis.

###Redis Installation and Configuration

Required version: redis 2.6.x or above.

Note: Ubuntu installs an older version by default. See [http://redis.io/download](http://redis.io/download) for instructions on how to manually install redis 2.6.x or above manually or use the PPA below.

For Ubuntu, you can use the redis-server package. However, on Precise, it's not new enough, so you'll want to use a backport PPA to provided [here](https://launchpad.net/~chris-lea/+archive/redis-server).

After installing redis, start the server. There are multiple options for doing this. You can set it up so it runs automatically when the server boots, or you can run it manually.

Now we need to go back to your canvas-lms directory and edit the configuration. Inside the config folder, we're going to copy two files that already set up for a production system where redis is installed on the same system as Canvas.

	>sudo cp config/cache_store.yml.production config/cache_store.yml
	>sudo cp config/redis.yml.production config/redis.yml 

In the example, redis is running on the same server as Canvas. That's not ideal in a production setup, since Rails and redis are both memory-hungry. Just change 'localhost' to the address of your redis instance server if you decide to change it.

Canvas has the option of using a different redis instance for cache and for other data. The simplest option is to use the same redis instance for both. If you would like to split them up, keep the redis.yml config for data redis, but add another separate server list to cache_store.yml to specify which instance to use for caching.

Save the file and restart Canvas.

###Automated jobs

Canvas has some automated jobs that need to run at occasional intervals, such as email reports, statistics gathering, and a few other things. Your Canvas installation will not function properly without support for automated jobs, so we'll need to set that up as well.

Canvas comes with a daemon process that will monitor and manage any automated jobs that need to happen. If your application root is /var/canvas, this daemon process manager can be found at /var/canvas/script/canvas_init.

You'll need to run these job daemons on at least one server. Canvas supports running the background jobs on multiple servers for capacity/redundancy, as well.

Because Canvas has so many jobs to run, it is advisable to dedicate one of your app servers to be just a job server. You can do this by simply skipping the Apache steps on one of your app servers, and then only on that server follow these automated jobs setup instructions.

###Installation of Automated Jobs

If you're on Debian/Ubuntu, you can install this daemon process very easily, first by making a symlink from /var/canvas/script/canvas_init to /etc/init.d/canvas_init, and then by configuring this script to run at valid runlevels (we'll be making an upstart script soon):

	>sudo ln -s /var/canvas/script/canvas_init /etc/init.d/canvas_init
	>sudo update-rc.d canvas_init defaults
	>sudo /etc/init.d/canvas_init start

###Restart Apache and Use Canvas!

Restart Apache (>sudo /etc/init.d/apache2 restart), and point your browser to your new Canvas installation! Log in with the administrator credentials you set up during database configuration, and you should be ready to use Canvas.
	


