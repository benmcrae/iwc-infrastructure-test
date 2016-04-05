# Technical Test - Ben McRae

Steps of workflow / implementation.

1. Exploratory testing of server and Apache installation / configuration.
2. Identify implementation strategies.
3. Write ServerSpec tests for conformity and convergence.
4. Technical implementation.

## 1. Exploratory testing

Ubuntu Precise 12.04 LTS machine with Apache 2.2.4 installed from source.

```
root@ip-172-31-45-119:/opt/apache/bin# ./apachectl -V
Server version: Apache/2.2.4 (Unix)
Server built:   Dec  7 2015 14:14:15
Server's Module Magic Number: 20051115:4
Server loaded:  APR 1.2.8, APR-Util 1.2.8
Compiled using: APR 1.2.8, APR-Util 1.2.8
Architecture:   64-bit
Server MPM:     Prefork
  threaded:     no
    forked:     yes (variable process count)
Server compiled with....
 -D BIG_SECURITY_HOLE
 -D APACHE_MPM_DIR="server/mpm/prefork"
 -D APR_HAS_SENDFILE
 -D APR_HAS_MMAP
 -D APR_HAVE_IPV6 (IPv4-mapped addresses enabled)
 -D APR_USE_SYSVSEM_SERIALIZE
 -D APR_USE_PTHREAD_SERIALIZE
 -D APR_HAS_OTHER_CHILD
 -D AP_HAVE_RELIABLE_PIPED_LOGS
 -D DYNAMIC_MODULE_LIMIT=128
 -D HTTPD_ROOT="/opt/apache"
 -D SUEXEC_BIN="/opt/apache/bin/suexec"
 -D DEFAULT_PIDLOG="logs/httpd.pid"
 -D DEFAULT_SCOREBOARD="logs/apache_runtime_status"
 -D DEFAULT_LOCKFILE="logs/accept.lock"
 -D DEFAULT_ERRORLOG="logs/error_log"
 -D AP_TYPES_CONFIG_FILE="conf/mime.types"
 -D SERVER_CONFIG_FILE="conf/httpd.conf"
```

A few observations from this...

* This is an old version of Apache from 2007.

* Was curious about 'BIG_SECURITY_HOLE'. A quick Google search came back with 'Apache has not been designed to serve pages while running as root', suggesting that BIG_SECURITY_HOLE is not necessary if we change the Apache config user to a non 'root' user.

* The server installation has been compiled the with following *static* extensions - I found the modules by looking at `./apachectl -M` and comparing with the `./configure --help` documentation (on an ubuntu/precise64 Vagrant box). Adding the modules statically via compilation allows faster execution time than enabling the modules through DSO. Static compilation also installs the whole module set which may not be needed (best practices are to install only the required modules used).
```
./configure --prefix /opt/apache /
--enable-so /
--enable-rewrite /
--enable-proxy /
--enable-vhost-alias /
--enable-cache /
--enable-dav /
--enable-disk-cache /
--enable-headers /
--enable-expires /
--enable-dav-lock
```

* The server has been setup to use the 'prefork' MPM (incurs threading to be turned off). Since the website is served through the proxy module, we could use either the 'worker' or 'event' (apache 2.4+) MPM which gives better concurrency via child processes and threading.

* Permissions on the `/opt/apache` directory should be restricted from RWX for 'everyone' to a minimum `755`.

* Apache logs exist in `/opt/apache/logs` - the correct standard would be in `/var/log`. No log rotation for `access.log` or `error.log`. The PID file was also in the same directory - this should be in `/var/run`.

##2. Implementation strategies

I have identified 2 potential implementations for managing Apache. I will discuss the pros and cons for each approach.

1. **Keep existing Apache installation** - which has been installed from source. Run a configuration management tool to implement any desired fixes discovered from exploratory testing.
  * **PRO:** Can install modules statically, this has marginally better performance.
  * **CON:** It can be dangerous to converge an application which has been installed outside of a configuration management tool and subject to entropy.
  * **CON:** When installing from source, to achieve idempotency will require more work.
  * **CON:** Unable to make full use of existing configuration management tools which will lead to more complexity in setup scripts.

2. **Install Apache through a package manager** - remove old source installation. This will install the latest (pinned) Apache from the 'apt' package manager.
  * **PRO:** The apache binaries will have more thorough testing for the particular OS installation (Ubuntu 12.04 LTS).
  * **PRO:** Security patches will be easier to obtain and apply.
  * **PRO:** Additional tools provided such as a2enmod to manage DSO modules.
  * **PRO:** Fresh install of Apache - no entropy.
  * **PRO:** Will create logrotate entries for any logs in `/var/log/apache2`
  * **CON:** More difficult to statically add modules, if necessary.
  * **CON:** Will need to diff existing configuration scripts to make sure we don't lose any configuration settings.
  * **CON:** Will require additional scripts to stop and remove existing apache installation.

### Decision

I have decided to go with second implementation - **Install Apache through a package manager**. The main reasons are due to fresh install of apache - no entropy, better tools to support idempotency, easier to build and roll out new machines.

## 3. ServerSpec tests

Define some conformity tests to ensure we don't deviate from expected behaviour during upgrades or idempotency tests. These tests should **ALWAYS** pass / run green.

* **[CON-001]** Port 80 should always be listening
* **[CON-002]** Apache configuration syntax test
* **[CON-003]** Check default server and namevhost are set to 'www.leodis.ac.uk'

Below are the tests I have written based on the selection of the second implementation - **Install Apache through a package manager**. The idea is to turn these tests green!

* **[FIX-001]** 'www-data' user exists
* **[FIX-002]** 'www-data' group exists
* **[FIX-003]** 'apache2' process should be running
* **[FIX-004]** Parent 'apache2' process should be owned by root
* **[FIX-005]** Child 'apache2' processes should be owned as 'www-data'
* **[FIX-006]** Apache should be enabled for startup
* **[FIX-007]** Apache server should use MPM 'worker'
* **[FIX-008]** Apache 2.2.22 should be installed via apt package manager

### Run EC2 ServerSpec tests

If you want to run the ServerSpec tests locally, there are some environment prerequisites.

1. Local Ruby installation (I currently run Ruby 2.3.0).
2. Installation of bundler gem (`gem install bundler`).
3. Run `bundle install` in project directory - if the gem dependencies fail, delete the `Gemfile.lock` and run install again.

Before executing tests, make sure you have the server private key added to your authentication agent `ssh-add path_to_private_key.pem`. Then off you go...

1. `cd ec2-tests`
2. `rake spec`

![ServerSpec first test run](assets/ec2-test-pre.png)

## 4. Technical Implementation

I decided to do the technical implementation using Ansible *(Disclaimer: this is my first time using Ansible - feedback welcome!)*.

First I created a single playbook file, then after reading the [Ansible best practices](http://docs.ansible.com/ansible/playbooks_best_practices.html), decided to refactor into multiple roles and files - changes can be seen between commits `bee13f8` and `ccde4fd`.

A lot of Apache modules have been enabled, this is purely to match the configuration of the previous server. A handful of these can be turned off if desired - the main ones we need are 'vhost' and 'proxy' (this is enough to satisfy the minimum requirements of the website).

### New Server

I first worked on completing the playbook for new servers (no existing installation of Apache).

When running `vagrant up` in the local directory, an Ubuntu 12.04 LTS machine will be created with a 2 step provision process.

1. **Shell:** This creates a very simple index.html on port 1337 to mimic the leodis website.
2. **Ansible:** This installs and configures Apache on the guest host.

As part of the output from Vagrant, you will see the output from the Ansible run.

```
PLAY RECAP *********************************************************************
new-server                 : ok=26   changed=22   unreachable=0    failed=0   
```

This successfully updated 22 tasks on the server. If we now run `vagrant provision`, a second run of the same Ansible playbook will begin. The final output now looks like...

```
PLAY RECAP *********************************************************************
new-server                 : ok=25   changed=0    unreachable=0    failed=0
```

On the second run no tasks were changed - this demonstrates that idempotency was successful.

If you open a browser and go to `http://127.0.0.1:8080`, you will see a mock website of leodis built using the playbook.

#### Run Vagrant ServerSpec tests

An identical `apache_spec.rb` file exists in both the 'ec2-test' and 'vagrant-tests' directories.

1. `cd vagrant-tests`
2. `rake spec`

![ServerSpec first test run](assets/vagrant-test.png)

### Old Server

I created an additional Ansible role called 'remove_http'. I didn't worry too much about idempotency as this role will only ever be ran once.

I executed the role as follows `ansible-playbook -i production rebuild-webservers.yml --private-key ../techtest-Ben-McRae.pem`

The 'rebuild-webservers.yml' specification will use the 'remove_http' role to remove the old apache installation and then use the 'apache' role to reinstall it the correct way.

![ServerSpec first test run](assets/ec2-during.png)

Ansible rightly suggested I could have used the 'service' and 'file' modules.

```
PLAY RECAP *********************************************************************
52.48.226.89               : ok=30   changed=26   unreachable=0    failed=0   
```

This time Ansible updated 26 tasks instead of the previous 22 (the 4 additional tasks were used to remove the old apache install).

### Homogeneous / Heterogeneous Systems

The configuration for the MPM worker was not changed from the default installation. If using homogeneous systems we can hardcode the new values into the default vars file. If the systems are heterogeneous, I advise creating group_vars per server type as necessary.
