## Introduction
This is a short notes on creating TCP Load Balancer using HAProxy and get the client IP from backend server (Apache HTTPD) and forward it to Application Server.

## Test Environment

Client
+ Windows 10
+ Firefox for Developer 82.0b9
+ 192.168.232.1
+ VMWare Workstation 15 for loading Virtual Machines

Load Balancer (HAProxy)
+ Ubuntu 18.04.3 LTS (Standard minimal server installation)
+ HA-Proxy version 1.8.8-1ubuntu0.11 2020/06/22 (from ubuntu repo)
+ 192.168.232.129

Apache HTTPD
+ Ubuntu 20.04.1 LTS (Standard minimal server installation)
+ Apache/2.4.41 (Ubuntu)
+ 192.168.232.130

Additional Application Server (for testing X-Forwarded-For)
= See Client computer


Target:

![diagram-01](https://i.imgur.com/gJoO1z3.png)


## TL;DR

Steps:
1. Setup haproxy with TCP mode. For this SSL purpose, we will bind to :443
2. Configure backend for send-proxy-v2 which is for using PROXY Protocol. (Refer to http://www.haproxy.org/download/1.8/doc/proxy-protocol.txt)
3. On apache site, configure VirtualHost to use PROXY Protocol.
4. On application site, capture Client IP from X-Forwarded-For

Pro:
+ Using PROXY Protocol, it is possible to get Client-IP even if HAProxy resides on a different subnet with Apache server (Client information is embedded inside PROXY Protocol)
+ No need to forward ipv4/ipv6 and messed up with

Caveats:
+ User can't go directly to Apache Server since it will expecting to use PROXY Protocol, not HTTPS Protocol. (Browser will use HTTPS Protocol).
+ Added PROXY Protocol will induce a little overhead on each request to Apache HTTPD server. Refer spec for overhead data.

## Setting up HAProxy @192.168.232.129

(Terminology: Backend Server = Apache HTTPD server)

This is minimal configuration for `haproxy.cfg`

```
global
        log /dev/log    local0
        log /dev/log    local1 notice
        chroot /var/lib/haproxy
        stats socket /run/haproxy/admin.sock mode 660 level admin
        stats timeout 30s

        user haproxy
        group haproxy
        daemon
        ssl-server-verify none

defaults

         log global
         option tcplog
         mode tcp
         option http-server-close
         timeout connect 1s
         timeout client  20s
         timeout server  20s
         timeout client-fin 20s
         timeout tunnel 1h

frontend https
         bind *:443
         mode tcp

         default_backend be_app

backend be_app
         mode tcp

         server server_01_443  192.168.232.130:443 check check-ssl send-proxy-v2
```

Important part is that,
1. TCP mode, transporting SSL from Client to 192.168.232.130:443 without decrypting SSL.
2. We don't use `ssl` directive on backend server. Instead, we are using `send-proxy-v2` to mark it using PROXY Protocol.
3. Also note that we are forcing `option http-server-close` as oppose to HTTP keep-alive (not to be confused with keepalived software). This would be important later when we design for multiple backend.

> Configuration `ssl-server-verify none` is assuming HAProxy trust 1000% backend server. For more secure, do ssl-verify with certificate from backend server. Basically like SSL-Pinning on mobile app. But each time renew certificate, this cert MUST also be replaced with new one, matching backend cert.

> Cert. Not key.

## Setting up Apache HTTPD @192.168.232.130

For Apache HTTPD utilize PROXY Protocol, enable mod_remoteip as follows,
```
# Enabling mod_remoteip
sudo a2enmod remoteip

# Restart Apache2 to take effect
sudo systemctl restart apache2
```
Refer to https://httpd.apache.org/docs/2.4/mod/mod_remoteip.html#page-header for `mod_remoteip` documentation.

This is the default Ubuntu apache's configuration for SSL.

```
<IfModule mod_ssl.c>
        <VirtualHost _default_:443>
                ServerAdmin webmaster@localhost

                RemoteIPProxyProtocol On
                RemoteIPTrustedProxy 192.168.232.129/32

                DocumentRoot /var/www/html

                LogFormat "%h %{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined

                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/ssl-access.log combined

                SSLEngine on
                SSLCertificateFile      /etc/ssl/certs/ssl-cert-snakeoil.pem
                SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

                <FilesMatch "\.(cgi|shtml|phtml|php)$">
                                SSLOptions +StdEnvVars
                </FilesMatch>
                <Directory /usr/lib/cgi-bin>
                                SSLOptions +StdEnvVars
                </Directory>
        </VirtualHost>
</IfModule>
```

This is standard VirtualHost binding 443 with SSL, except for these parameters:
1. `RemoteIPProxyProtocol On` to wrap this VirtualHost with Proxy Protocol. Means that instead of 443 is being used by SSL Protocol, 443 now is SSL wrapped inside PROXY Protocol.
2. `RemoteIPTrustedProxy 192.168.232.129/32` ensuring that this Apache HTTPD will trust proxy connection from that specific IP addresses.
3. `LogFormat "%h %{X-Forwarded-For}i %l ...`. Eventhough this is standard, but we will use this for testing to see if it working or not. %h is for Remote IP address (Client IP address) and X-Forwarded-For is for... X-Forwarded-For.

If you go directly to the server now, you will get error

![](https://i.imgur.com/1fXT7Dk.png)

As explained before, browser is expecting SSL handshake, but 192.168.232.130:443 now instructed to use PROXY protocol.


