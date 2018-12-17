# Project sfw_login

This is the first of hopefully many Schema Framework development patterns.

This pattern is for an authorized login.  The project includes:

- MySQL scripts for creating a database, some tables and procedures.
- A SRM (Schema Response Mode) file that uses the procedures to
  drive several interactions.
- Scripts to install and uninstall the demo by updating settings,
  configuring Apache for web access, loading MySQL scripts, etc.

## Prerequisites

If the environment is properly set up for running Schema Framework
applications, this project can be cloned and quickly made into a
running web application.  The following items are assumed to be
prepared for the project to run:

- An installed and up-to-date [SchemaServer](https://www.github.com/cjungmann/SchemaServer),
  the back-end environment of the Schema Framework
- An installed and up-to-date [Schema Framework](https://www.github.com/cjungmann/schemafw),
  the client-side environment that interacts with the SchemaServer.
- A working installation of *git*.
- A working MySQL installation.
- Working Apache installation.
- A directory with appropriate Apache security settings (see below).
- For running on *localhost*, use the **/etc/hosts** file to
  translate the hostname to the localhost IP address (127.0.0.1)

## Download and Install

### Download

Go to the directory under which the demo will be installed.  For
this example, I am pretending to be on my development computer,
with the command line prompt reflecting the directory under which
I install web applications.

~~~sh
/home/chuck/work/www$ git clone https://www.github.com/cjungmann/sfw_login.git
~~~

### Install the Project

Go into the *setup* directory, and run the *setup* script.

There are two considerations when running *setup*:
- Use *sudo* in order to install an Apache configuration file
  and to enable the site and restart Apache.
- The *setup* script must take one parameter, either *install*
  or *uninstall*.  It can optionally take up to two more
  parameters, the second replaces the default value of *sfw_login*
  as the hostname, and the third replaces the default database
  name of *SFW_Login*.

~~~sh
/home/chuck/work/www$ cd sfw_login/setup
/home/chuck/work/www/sfw_login/setup$ sudo ./setup install
~~~

### Prepare Host Environment

Apache uses the hostname to direct requests to the appropriate
web installation.  On a development computer, this means the
system file **/etc/hosts** must contain a hostname entry.

Open the *hosts* file like this:

~~~sh
/home/chuck/work/www/sfw_login/setup$ sudo emacs /etc/hosts
~~~

and add to the file the second line in the following example
(assuming the default hostname*sfw_login*):

~~~
127.0.0.1   localhost
127.0.0.1   sfw_login
~~~

### Viewing the Website

Open your browser and type `http://sfw_login` on the address line
to go to the site.


## Apache Directory Security Settings

Apache requires that the directory in which a website is installed
must be designated with appropriate security settings.  On my
development computer, I develop web applications in a **www** directory
under my **home** directory.  The path is `/home/chuck/work/www`.
All web application projects are children of this directory.

The make children of */home/chuck/work/www* work under Apache,
I added the following lines to the */etc/apache2/apache2.conf* file
near the other directory security settings:

~~~conf
<Directory /home/chuck/work/www>
	Options Indexes FollowSymLinks
	AllowOverride None
	Require all granted
</Directory>
~~~


  


