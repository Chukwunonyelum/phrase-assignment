#!/bin/bash
yum update -y
yum install -y docker
systemctl enable docker
systemctl start docker

# Create custom NGINX config with /phrase health endpoint
mkdir -p /opt/nginx
cat <<EOF > /opt/nginx/nginx.conf
events {}
http {
    server {
        listen 80;

        location /phrase {
            return 200 "Service alive\n";
            add_header Content-Type text/plain;
        }

        location / {
            return 200 "Hello from NGINX\n";
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Run NGINX container with restart policy
docker run -d --name nginx_app \
  --restart always \
  -p 80:80 \
  -v /opt/nginx/nginx.conf:/etc/nginx/nginx.conf \
  nginx:stable-alpine
