#!/usr/bin/env bash

apt-get update
apt-get install -y haproxy

# Below is haproxy configuration
#file : /etc/haproxy/haproxy.cfg
cat <<EOF | sudo tee /etc/haproxy/haproxy.cfg
global
   log /dev/log	local0
   log /dev/log	local1 notice
   chroot /var/lib/haproxy
   stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
   stats timeout 30s
   user haproxy
   group haproxy
   daemon

   # Default SSL material locations
   ca-base /etc/ssl/certs
   crt-base /etc/ssl/private

   # Default ciphers to use on SSL-enabled listening sockets.
   # For more information, see ciphers(1SSL). This list is from:
   #  https://hynek.me/articles/hardening-your-web-servers-ssl-ciphers/
   # An alternative list with additional directives can be obtained from
   #  https://mozilla.github.io/server-side-tls/ssl-config-generator/?server=haproxy
   ssl-default-bind-ciphers ECDH+AESGCM:DH+AESGCM:ECDH+AES256:DH+AES256:ECDH+AES128:DH+AES:RSA+AESGCM:RSA+AES:!aNULL:!MD5:!DSS
   ssl-default-bind-options no-sslv3

defaults
   log	global
   mode	http
   option	httplog
   option	dontlognull
       timeout connect 5000
       timeout client  50000
       timeout server  50000
   errorfile 400 /etc/haproxy/errors/400.http
   errorfile 403 /etc/haproxy/errors/403.http
   errorfile 408 /etc/haproxy/errors/408.http
   errorfile 500 /etc/haproxy/errors/500.http
   errorfile 502 /etc/haproxy/errors/502.http
   errorfile 503 /etc/haproxy/errors/503.http
   errorfile 504 /etc/haproxy/errors/504.http

frontend k8s-api
   bind 0.0.0.0:6443
   mode tcp
   option tcplog
   default_backend k8s-api-backend

backend k8s-api-backend
   mode tcp
   option tcplog
   option tcp-check
   balance roundrobin
   default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
       server k8smaster1 192.168.56.111:6443 check
       server k8smaster2 192.168.56.112:6443 check
       server k8smaster3 192.168.56.113:6443 check
EOF

systemctl restart haproxy
systemctl status haproxy