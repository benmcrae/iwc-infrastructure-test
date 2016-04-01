# Technical Test - Ben McRae

Steps of workflow / implementation.

1. Exploratory testing of server and Apache installation / configuration.
2. Write ServerSpec tests for conformity and convergence.

## 1. Exploratory testing

Ubuntu Precise 12.04 machine with Apache 2.2.4 installed from source.

*This is an old version of Apache. Correct steps would be to upgrade to latest stable (for security purposes if anything), however, this looks out of scope for the user story.*


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
Was curious about 'BIG_SECURITY_HOLE'. A quick google search came back with 'Apache has not been designed to serve pages while running as root', suggesting that BIG_SECURITY_HOLE is not necessary if we change the Apache User to a non 'root' user.

## 2. ServerSpec tests

Define some conformity tests to ensure we don't deviate from expected behaviour during upgrades or idempotency tests. These tests should **ALWAYS** pass / run green.

* **[CON-001]** Port 80 should always be listening
* **[CON-002]** httpd process should be running
* **[CON-003]** The parent httpd process should be owned by root

Below are the tests I have written through my findings when navigating the server.

* **[FIX-001]** Create 'apache' user
* **[FIX-002]** Create 'apache' group
* **[FIX-003]** Apache directory permissions should be more restrictive (755)
* **[FIX-004]** Child httpd processes should be executed as non 'root' user
* **[FIX-005]** Apache has incorrect runlevels for startup

### Run ServerSpec tests

If you want to run the ServerSpec tests locally, there are some environment prerequisites.

* Local Ruby installation (I currently run Ruby 2.3.0)
* Installation of bundler gem (`gem install bundler`)
* Run `bundle install` - if the gem dependencies fail, delete the `Gemfile.lock` and run install again

Before executing tests, make sure you have the server private key added to your authentication agent `ssh-add path_to_private_key.pem`. Then off you go...

1. `cd ec2-tests`
2. `rake spec`
