# SSL via PROXY Protocol
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

> Cert. Not key. Refer to: https://owasp.org/www-community/controls/Certificate_and_Public_Key_Pinning

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

## Result #1

If you go directly to the server now (https://192.168.232.130), you will get error

![](https://i.imgur.com/1fXT7Dk.png)

As explained before, browser is expecting SSL handshake, but 192.168.232.130:443 now configured to use PROXY protocol. Not even log shows anything.

Now, if we go directly to HAProxy from client, we will get:
![](https://i.imgur.com/DqY7bvE.png)

If we look at error log,
![](https://i.imgur.com/UdxoKU1.png)
Nice!

To check what happens if we "telnet" directly to 192.168.232.130:443 (our Apache HTTPD server),
![](https://i.imgur.com/7lkUoyz.png)
Of course, openssl expecting SSL handshake at the beginning.

Now if we "telnet" to our HAProxy Server 192.168.232.129:443, we will get,
![](https://i.imgur.com/iE9wRib.png)
which is also nice. 

Client 192.168.232.1 -- SSL --> 192.168.232.129:443 -- PROXY + SSL --> 192.168.232.130:443.

# Add another spice: ProxyPass

This is pretty straight forward. Now that Apache HTTPD will treat Client IP captured from HAProxy, as its own Client IP, it will easily forward Client IP using X-Forwarded-For.

At the client computer (192.168.232.1), just create a simple python file to serve HTTP and print all headers they got. Or you can use anything that will do the same job.

```
#!/usr/bin/env python3

import http.server as SimpleHTTPServer
import socketserver as SocketServer
import logging

PORT = 8000

class GetHandler(
        SimpleHTTPServer.SimpleHTTPRequestHandler
        ):

    def do_GET(self):
        logging.error(self.headers)
        SimpleHTTPServer.SimpleHTTPRequestHandler.do_GET(self)


Handler = GetHandler
# run as root/administrator to bind to all IP 0.0.0.0
httpd = SocketServer.TCPServer(("0.0.0.0", PORT), Handler)

httpd.serve_forever()
```

And add a ProxyPass/ProxyPassReverse for reverse proxy setup at Apache HTTPD.

```
# Anywhere inside VirtualHost
        ProxyPass               "/test/" "http://192.168.232.1:8000/"
        ProxyPassReverse        "/test/" "http://192.168.232.1:8000/"
```

![](https://i.imgur.com/bd2FieX.png)

Nice. Backend Application will receive Client IP from `X-Forwarded-For`. `X-Forwarded-Host` is where the Client IP access it and `X-Forwarded-Server` is the relaying proxy (can safely ignore this).
> Forget about ERROR:root from python since we don't do anything on root.

# More spice: Apache HTTPD High Availability (active-active).

For this setup, i will just create a duplicate default-ssl.conf at Apache HTTPD server to serve port 444.

```
<IfModule mod_ssl.c>
        <VirtualHost _default_:444>
                ServerAdmin webmaster@localhost

                RemoteIPProxyProtocol On
                RemoteIPTrustedProxy 192.168.232.129/32

                DocumentRoot /var/www/html

                LogFormat "%h %{X-Forwarded-For}i %l %u %t \"%r\" %>s %O \"%{Referer}i\" \"%{User-Agent}i\"" combined

                ErrorLog ${APACHE_LOG_DIR}/error.log
                CustomLog ${APACHE_LOG_DIR}/ssl-access-444.log combined

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
Just change port `VirtualHost:443` to `VirtualHost:444` and change custom log to `ssl-access-444.log`.

As for HAProxy server, it is as easy as add another line to backend section. (refer to last line).
```
## ^ other config
backend be_app
         mode tcp

         server server_01_443  192.168.232.130:443 check check-ssl send-proxy-v2
         server server_01_444  192.168.232.130:444 check check-ssl send-proxy-v2
         # ^ not this comment. but this one ^
```

`curl` from client computer multiple time, we will get this (notice the short time between curl and the alternating log between `ssl-access.log` and `ssl-access-444.log`)
![](https://i.imgur.com/R2ZvAm1.png)

# Final Form: Active-Active with IP Persist

![](https://i.imgur.com/6ykHDVO.png)

Well i'm not going to explain High Availability for HAProxy setup in here (hint hint: keepalived or pacemaker or LVS). But instead, we are going to apply active-active configuration **WITH** IP Persist for the backend server.

Using active-active without IP Persist is highly recomended to distribute load fairly between backend servers and highly recomended for security reason (you need to launch big DDOS campaign from multiple source to take down whole cluster of backend server).

But then again, this is important for some project when Apache HTTPD requires same client IP to go to same instance (caching/local persist/authentication).

What needed to do is add these two lines in backend section of HAProxy. There's a lot of ways to it like checking cookies etc. But persist by IP is far more easier and compatible with L4 and L7 mode (persist by cookies only works at L7 balancing).

```
backend be_uap
         mode tcp

         stick-table type ip size 1m expire 30s
         stick on src

         server server_01_443  192.168.232.130:443 check check-ssl send-proxy-v2
         server server_01_444  192.168.232.130:444 check check-ssl send-proxy-v2
```

This will,
+ `stick-table` use stick table
+ `type ip` using IP for
+ `size 1m` store up to 1 millions of record
+ `expire 30s` each sticky will expire in 30s. choosing which backend will go next depends on the algorithm (in this default case, round robin).

![](https://i.imgur.com/LMYYym9.png)

Here as you can see:
1. 192.168.232.1 goes to 443
2. 192.168.232.130 goes to 444 (round robin)
3. 192.168.232.1 goes to 443 (sticky)
4. 192.168.232.129 goes to 444 (round robin)
5. 192.168.232.130 goes to 443 (round robin (prev record .130 expired))

One final note though, make sure IP Sticky expiry matchup with backend persist expiry (like cookies, etc). Let say if cookies at Apache HTTPD expired after 1 hour, it's a good way to matchup expiry in HAProxy 60m (assuming HAProxy -> Apache HTTPD transported in ms of course).
