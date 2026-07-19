---
layout: post
title:  "how to setup opencloud using podman rootless quadlets"
date:   2026-07-11 01:00:00
categories: opencloud authelia podman
---

It's intended mainly to document setup of opencloud connected via authelia provider with lldap as ldap backend.
So this is free list of steps to be done to have it working. As a domain here I use auth.tomho.eu for authelia
authentication, cloud.tomho.eu for opencloud access and cal.tomho.eu for calendar.
You should change it to your domain.

This comes with no guarantee - it may contain errors and is meant mainly as inspiration, not a fully tested guide.

All services will run under dedicated podman user using quadlets definition files. I use debian trixie actually
so all commands will be tested against it.


## Prepare user under which services will run and directory structure


Add dedicated user(-m for creating home dir):
~~~sh
useradd -m opencloud
~~~

Set some password:
~~~sh
passwd opencloud
~~~

And set enable-linger so services can run after logout:
~~~sh
loginctl enable-linger opencloud
~~~

Now login under the new user. 17170 is used by lldap and via mapping we can manage
it from our computer. User needs to be in AllowUsers in /etc/ssh/sshd_config
to be able to logon remotely.
~~~sh
ssh -L 17170:localhost:17170 -p <when using nonstandart port> 'opencloud@tomho.eu'
~~~

Create all needed directories:
~~~sh
mkdir -p .config/containers/systemd
mkdir -p containers/authelia/config
mkdir -p containers/authelia/data
mkdir -p containers/lldap/data
mkdir -p containers/opencloud/apps
mkdir -p containers/opencloud/config
mkdir -p containers/opencloud/data
mkdir -p containers/proxysthesis/config
mkdir -p containers/radicale/config
mkdir -p containers/radicale/data
~~~


## Add podman network which will be shared among all containers
 
Add quadlet definiton of network open into .config/containers/systemd/opencloud.network:
~~~ini
[Network]
NetworkName=opencloud
~~~

Register and start the network now, so it's ready for every container that will join it:
~~~sh
systemctl --user daemon-reload
systemctl --user start opencloud-network.service
~~~


## Setup lldap service

### Generate secrets

Generate secrets used by lldap container(- means read from input):
~~~sh
openssl rand -hex 64 | podman secret create lldap-key-seed -
openssl rand -hex 64 | podman secret create lldap-jwt-secret -
openssl rand -hex 64 | podman secret create lldap-ldap-user-pass -
~~~



### Quadlet definition

Add quadlet definition of lldap into .config/containers/systemd/lldap.container:
~~~ini
[Unit]
Description=LLDAP

[Service]
Restart=on-failure

[Container]
AutoUpdate=registry
ContainerName=lldap
Image=ghcr.io/lldap/lldap:latest

Network=opencloud.network

# environment variables
Environment=UID=1000
Environment=GID=1000
Environment=LLDAP_LDAP_BASE_DN=dc=tomho,dc=eu
Environment=LLDAP_LDAP_USER_EMAIL=tomashorak@post.cz

# set secrets
Environment=LLDAP_KEY_SEED_FILE=/run/secrets/lldap-key-seed
Environment=LLDAP_JWT_SECRET_FILE=/run/secrets/lldap-jwt-secret
Environment=LLDAP_LDAP_USER_PASS_FILE=/run/secrets/lldap-ldap-user-pass

# health check
HealthCmd=/app/lldap healthcheck
HealthInterval=30s
HealthRetries=3
HealthStartPeriod=15s
HealthTimeout=30s

# secrets - file based
Secret=lldap-jwt-secret,type=mount,uid=1000
Secret=lldap-key-seed,type=mount,uid=1000
Secret=lldap-ldap-user-pass,type=mount,uid=1000

Volume=%h/containers/lldap/data:/data:U,Z
PublishPort=127.0.0.1:17170:17170
PublishPort=127.0.0.1:3890:3890

# Bootstrapping. Uncomment the remainder of this section. Once
# the bootstrap files are ready. re-comment once bootstrapping is done.
# Secret=lldap-ldap-user-pass,type=env,target=LLDAP_ADMIN_PASSWORD
# Environment=LLDAP_URL=http://localhost:17170
# Environment=LLDAP_ADMIN_USERNAME=admin
# Environment=LLDAP_ADMIN_PASSWORD_FILE=/run/secrets/lldap-ldap-user-pass
# Volume=%h/containers/lldap:/bootstrap:ro,Z

[Install]
WantedBy=default.target
~~~

### Start service

Uncomment bootstrapping section and run it first time:
~~~sh
systemctl --user daemon-reload
systemctl --user start lldap.service
~~~

Then stop the service, comment it out again, and repeat the steps above. Or you can just leave it commented,
connect to admin console and create admin account directly.


### Retrieve the generated password

You can use your own password for lldap-ldap-user-pass or any other instead of running rand.
In case you didn't use it and need to know generated one, attach to running container and cat
it:
~~~sh
podman exec -it lldap /bin/sh
cat /run/secrets/lldap-ldap-user-pass
~~~

You can access lldap admin console now via http://localhost:17170(mapped via ssh -L param).





## Setup authelia service

### Quadlet definition

Add quadlet definition of authelia into .config/containers/systemd/authelia.container:
~~~ini
[Unit]
Description=Authelia

[Service]
Restart=on-failure

[Container]
AutoUpdate=registry
ContainerName=authelia
Image=docker.io/authelia/authelia:latest

Network=opencloud.network

# Match the user timezone so logs match your local system
Environment=TZ=Europe/Prague

Volume=%h/containers/authelia/config:/config:U,Z
Volume=%h/containers/authelia/data:/var/lib/authelia:U,Z
PublishPort=9091:9091

[Install]
WantedBy=default.target
~~~

### Configuration file

Add configuration into containers/authelia/config/configuration.yml:
~~~yml
###############################################################
#                 Authelia Core Configuration                 #
###############################################################

server:
  address: 'tcp://0.0.0.0:9091'

  endpoints:
    authz:
      forward-auth:
        implementation: 'ForwardAuth'

#log:  
#  level: 'trace'

storage:
  local:
    path: '/var/lib/authelia/db.sqlite3'
  encryption_key: 'replace f.e. with openssl rand -hex 64'

authentication_backend:
  ldap:
    implementation: 'lldap'
    address: 'ldap://lldap:3890'
    base_dn: 'DC=tomho,DC=eu'
    user: 'UID=authelia,OU=people,DC=tomho,DC=eu'
    password: 'replace with real user password'  

identity_validation:
  reset_password:
    jwt_secret: 'replace f.e. with openssl rand -hex 64'
    

# Intercepts reset requests and puts them in a text file instead of sending mail
notifier:
  filesystem:
    filename: '/config/notification.txt'

# Access parameters
access_control:
  default_policy: 'deny'
  rules:
    - domain: 'auth.tomho.eu'
      policy: 'bypass'
    - domain: 'cloud.tomho.eu'
      policy: 'one_factor'
    - domain: 'cal.tomho.eu'
      policy: 'one_factor'

# Domain Session configuration
session:
  name: 'authelia_session'
  secret: 'replace f.e. with openssl rand -hex 64'
  same_site: 'lax'
  expiration: '1h'
  inactivity: '5m'
  remember_me: '1M'
  cookies:
    - domain: 'tomho.eu'
      authelia_url: 'https://auth.tomho.eu'

identity_providers:
  oidc:
    lifespans:
      refresh_token: '24 hours'
      access_token: '1 hour'
      id_token: '1 hour'
    cors:
      endpoints:
        - authorization
        - token
        - revocation
        - introspection
        - userinfo
      allowed_origins:
        - https://auth.tomho.eu
        - https://cloud.tomho.eu
        - https://cal.tomho.eu
      allowed_origins_from_client_redirect_uris: true
    hmac_secret: 'replace f.e. with openssl rand -hex 64'
    jwks:
      - key_id: "authelia"
        algorithm: "RS256"
        use: "sig"
        key: |
          # replace with openssl genrsa 2048

    claims_policies:
         
      opencloud_policy:
        id_token:
          - preferred_username
          - name
          - email
          - email_verified
          - groups
        access_token:
          - preferred_username
          - name
          - email
          - email_verified
          - groups
        userinfo:
          - preferred_username
          - name
          - email
          - email_verified
          - groups
    
    clients:
      # ── OpenCloud web app ─────────────────────────────────────────────────
      - client_id: opencloud
        client_name: OpenCloud
        public: true
        claims_policy: default_policy
        authorization_policy: one_factor
        access_token_signed_response_alg: RS256
        grant_types:
          - authorization_code
        response_types:
          - code
        redirect_uris:
          - https://cloud.tomho.eu/oidc-callback.html
          - https://cloud.tomho.eu/oidc-silent-redirect.html
        scopes:
          - openid
          - profile
          - email
          - groups
        claims_policy: opencloud_policy
      # ────────────────────────────────────────────────────────────────────────────

      # ── OpenCloud Android app ─────────────────────────────────────────────────
      - client_id: OpenCloudAndroid
        client_name: OpenCloud Android
        public: true
        authorization_policy: one_factor
        access_token_signed_response_alg: RS256
        id_token_signed_response_alg: RS256
        audience:
          - OpenCloudAndroid
        grant_types:
          - authorization_code
          - refresh_token
        response_types:
          - code
        redirect_uris:
          - oc://android.opencloud.eu
        scopes:
          - openid
          - profile
          - email
          - offline_access
          - groups
        claims_policy: opencloud_policy
      # ────────────────────────────────────────────────────────────────────────────

      # ── OpenCloud Desktop client ──────────────────────────────────────────────
      - client_id: OpenCloudDesktop
        client_name: OpenCloud Desktop
        public: true
        claims_policy: default_policy
        authorization_policy: one_factor
        access_token_signed_response_alg: RS256
        grant_types:
          - authorization_code
          - refresh_token
        response_types:
          - code
        redirect_uris:
          - http://127.0.0.1
          - http://localhost
        scopes:
          - openid
          - profile
          - email
          - offline_access
          - groups
        claims_policy: opencloud_policy

      # ── OpenCloud iOS app ─────────────────────────────────────────────────────
      - client_id: OpenCloudIOS
        client_name: OpenCloud iOS
        public: true
        claims_policy: default_policy
        authorization_policy: one_factor
        access_token_signed_response_alg: RS256
        grant_types:
          - authorization_code
          - refresh_token
        response_types:
          - code
        redirect_uris:
          - oc://ios.opencloud.eu
        scopes:
          - openid
          - profile
          - email
          - offline_access
          - groups
        claims_policy: opencloud_policy


# Disable the external network time synchronization checks
ntp:
  disable_startup_check: true
  disable_failure: true          
~~~

### Start service

Start and stop authelia service:
~~~sh
systemctl --user daemon-reload
systemctl --user start authelia.service
systemctl --user stop authelia.service
~~~

## Setup proxysthesis service

You can see sources on https://github.com/tomas303/proxysthesis and I have created image which
just wraps this one standalone binary. Just adds groups into scope parameter if is missing.
Mobile apps just don't put it there and without it is impossible to use oidc login.

### Quadlet definition

Add quadlet definition of proxysthesis into .config/containers/systemd/proxysthesis.container:
~~~ini
[Unit]
Description=Proxysthesis (groups scope manage)

[Service]
Restart=on-failure

[Container]
AutoUpdate=registry
ContainerName=proxysthesis
Image=ghcr.io/tomas303/proxysthesis:latest

Network=opencloud.network

Environment=TZ=Europe/Prague

Volume=%h/containers/proxysthesis/config:/config:U,Z
PublishPort=8831:8831

AddHost=auth.tomho.eu:host-gateway

[Install]
WantedBy=default.target
~~~

### Configuration file

Add configuration into ./containers/proxysthesis/config/config.yaml:
~~~yml
listen: ":8831"
upstream: "http://auth.tomho.eu:9091"
debug_traffic: false
~~~

### Start service

Start proxysthesis service:
~~~sh
systemctl --user daemon-reload
systemctl --user start proxysthesis.service
~~~

## Setup opencloud service

### Generate secrets

First prepare two secrets - oidc is brand new so generate as usual, second one is password to lldap, so this
can be done by echo, but don't forget -n switch, which suppresses common linebreak generation:
~~~sh
openssl rand -hex 64 | podman secret create opencloud-proxy-oidc-client-secret -
echo -n 'your lldap password'  | podman secret create opencloud-oc-ldap-bind-password-secret -
~~~

### Initialize configuration

Next we have to pull opencloud's image and initialize configuration:
~~~sh
podman pull docker.io/opencloudeu/opencloud-rolling:latest
podman run --rm -it \
     -v /home/opencloud/containers/opencloud/config:/etc/opencloud \
     -v /home/opencloud/containers/opencloud/data:/var/lib/opencloud \     
     -e IDM_ADMIN_PASSWORD=<replace f.e. with openssl rand -hex 64> \
     opencloudeu/opencloud-rolling:latest init
~~~

### Quadlet definition

Add quadlet definition of opencloud into .config/containers/systemd/opencloud.container:
~~~ini
[Unit]
Description=open cloud 

[Service]
Restart=on-failure

[Container]
AutoUpdate=registry
ContainerName=opencloud
Image=docker.io/opencloudeu/opencloud-rolling:latest

Network=opencloud.network
AddHost=cloud.tomho.eu:host-gateway
AddHost=auth.tomho.eu:host-gateway

Environment=OC_URL=https://cloud.tomho.eu
Environment=OC_INSECURE=false
Environment=OC_OIDC_ISSUER=https://auth.tomho.eu


# authelia
Environment=PROXY_TLS_EXTERNAL=https://cloud.tomho.eu
Environment=PROXY_OIDC_ISSUER=https://auth.tomho.eu
Environment=PROXY_OIDC_CLIENT_ID=opencloud
Secret=opencloud-proxy-oidc-client-secret,type=env,target=PROXY_OIDC_CLIENT_SECRET
Environment=PROXY_AUTOPROVISION_ACCOUNTS=false
Environment=PROXY_ROLE_ASSIGNMENT_DRIVER=oidc

Environment=PROXY_OIDC_REWRITE_WELLKNOWN=true
Environment=WEB_OIDC_AUTHORITY=https://auth.tomho.eu
Environment=WEB_OIDC_CLIENT_ID=opencloud
Environment="WEB_OIDC_SCOPE=openid profile email groups"
Environment=PROXY_CSP_CONFIG_FILE_LOCATION=/etc/opencloud/csp.yaml

Environment=SETTINGS_SETUP_DEFAULT_ASSIGNMENTS="false"
Environment=GRAPH_ASSIGN_DEFAULT_USER_ROLE=false
Environment=GRAPH_USERNAME_MATCH=none
Environment=OC_EXCLUDE_RUN_SERVICES=idp

# OpenCloud LDAP configuration
Environment=OC_LDAP_URI=ldap://lldap:3890
Environment=OC_LDAP_SERVER_WRITE_ENABLED=false
Environment=FRONTEND_READONLY_USER_ATTRIBUTES="user.onPremisesSamAccountName,user.displayName,user.mail,user.passwordProfile,user.accountEnabled,user.appRoleAssignments"
Environment=OC_LDAP_INSECURE=true
Environment=OC_LDAP_BIND_DN=uid=authelia,ou=people,dc=tomho,dc=eu
Secret=opencloud-oc-ldap-bind-password-secret,type=env,target=OC_LDAP_BIND_PASSWORD
Environment=OC_LDAP_USER_BASE_DN=ou=people,dc=tomho,dc=eu
Environment=OC_LDAP_DISABLE_USER_MECHANISM=none
Environment=OC_LDAP_GROUP_BASE_DN=ou=groups,dc=tomho,dc=eu
Environment=GRAPH_LDAP_SERVER_UUID=true

# --- PROXY AUTHENTICATION ROUTING ---
Environment=PROXY_USER_OIDC_CLAIM=preferred_username
Environment=PROXY_USER_CS3_CLAIM=username

# --- GLOBAL LDAP SCHEMA CONFIGURATION ---
# Inform OpenCloud that users are tracked uniquely by their server UUID
Environment=OC_LDAP_USER_SCHEMA_ID=entryuuid
Environment=OC_LDAP_GROUP_SCHEMA_ID=cn

# Inform OpenCloud that the readable username lookup corresponds to 'uid'
Environment=OC_LDAP_USER_SCHEMA_USERNAME=uid

# --- GRAPH SERVICE SPECIFIC ALIGNMENT ---
# These parameters directly enforce the Shared User Directory specifications
Environment=GRAPH_LDAP_SERVER_UUID=true
Environment=GRAPH_LDAP_USER_SCHEMA_ID=entryuuid
Environment=GRAPH_LDAP_USER_SCHEMA_USERNAME=uid
Environment=GRAPH_LDAP_GROUP_SCHEMA_ID=cn
Environment=GRAPH_LDAP_GROUP_SCHEMA_NAME=cn

# Logs
# Environment=OC_LOG_LEVEL=debug
# Environment=PROXY_LOG_LEVEL=debug

# Persistent Volume Storage Mount on the Host
Volume=%h/containers/opencloud/config:/etc/opencloud:U,Z
Volume=%h/containers/opencloud/data:/var/lib/opencloud:U,Z
Volume=%h/containers/opencloud/apps:/var/lib/apps:U,Z

PublishPort=127.0.0.1:9200:9200

[Install]
WantedBy=default.target
~~~

### Start service

Start opencloud service:
~~~sh
systemctl --user daemon-reload
systemctl --user start opencloud.service
~~~

## Setup radicale service

This one will use the forward-auth example from https://www.authelia.com/integration/proxies/caddy/?utm_source=chatgpt.com.
Authelia's authz endpoint was already configured in the authelia section above.

### Quadlet definition

Add quadlet definition of radicale into .config/containers/systemd/radicale.container:
~~~ini
###
### radicale - podman quadlet file
### https://docs.podman.io/en/latest/markdown/podman-systemd.unit.5.html
###

[Unit]
Description=Radicale CalDAV/CardDAV server

[Service]
Restart=on-failure

[Container]
AutoUpdate=registry
ContainerName=radicale
Image=docker.io/tomsquest/docker-radicale:latest

Network=opencloud.network

Volume=%h/containers/radicale/config:/config:ro,U,Z
Volume=%h/containers/radicale/data:/data:U,Z

PublishPort=127.0.0.1:5232:5232


[Install]
WantedBy=default.target
~~~

### Configuration file

Add radicale config containers/config/config:
~~~ini
[server]
hosts = 0.0.0.0:5232

[auth]
# Trust the "X-Remote-User" header set by the reverse proxy (Authelia
# forward-auth) instead of doing its own authentication.
# IMPORTANT: radicale must only be reachable through the proxy - the proxy
# has to strip any client-supplied X-Remote-User header and set it itself
# after Authelia validates the session, otherwise auth can be spoofed.
type = http_x_remote_user

[rights]
type = owner_only

[storage]
filesystem_folder = /data/collections

[logging]
level = info
mask_passwords = True

[web]
type = internal
prefer_browser_login = True

~~~

### Start service

And start radicale service:
~~~sh
systemctl --user daemon-reload
systemctl --user start radicale.service
~~~

## Configure Caddy reverse proxy

This Caddy configuration ties all the services together behind a single reverse proxy.

~~~conf
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace ":80" below with your
# domain name.

# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile

(auth_headers_up) {
	header_up X-Real-IP {remote_host}
	header_up X-Forwarded-Scheme https
	header_up X-Forwarded-Port 443
}

(auth_inject_groups) {
	@missing_groups expression `{query}.contains("scope") && !{query.scope}.contains("groups")`
	uri @missing_groups query scope "{query.scope} groups"
	#respond "Test check uri: {http.request.uri}" 200 {
	#	close
	#}
}

# static web pages
tomho.eu, www.tomho.eu {
	root * /var/www/html
	file_server
}

# backup via restic
backup.tomho.eu {
	reverse_proxy http://localhost:8000 {
		header_up Authorization {http.request.header.Authorization}
	}
}

# opencloud
cloud.tomho.eu {
	reverse_proxy https://127.0.0.1:9200 {
		header_up Host {host}
		header_up X-Forwarded-Proto https

		transport http {
			tls_insecure_skip_verify
		}
	}
}

# auth provider authelia
auth.tomho.eu {
	# 8831 will add groups into scopes if missing - parameter aswell as body in case of token renewal
	handle /api/oidc/authorization {
		reverse_proxy http://127.0.0.1:8831 {
			import auth_headers_up
		}
	}
	handle /api/oidc/token {
		reverse_proxy http://127.0.0.1:8831 {
			import auth_headers_up
		}
	}
	handle {
		reverse_proxy http://127.0.0.1:9091 {
			import auth_headers_up
		}
	}
}

# radicale
cal.tomho.eu {
	forward_auth 127.0.0.1:9091 {
		uri /api/authz/forward-auth
		copy_headers Remote-User Remote-Groups Remote-Email Remote-Name
	}

	reverse_proxy http://127.0.0.1:5232 {
		header_up X-Remote-User {http.request.header.Remote-User}
	}
}
~~~





## Tips

### Generating passwords

rsa key:
~~~sh
openssl genrsa 2048
~~~

random password as hex:
~~~sh
openssl rand -hex 64
~~~


### Restarting a failed service

If a quadlet-based service fails to start a few times in a row, systemd applies a rate
limit and refuses further attempts, logging something like:
~~~
lldap.service: Start request repeated too quickly.
lldap.service: Failed with result 'exit-code'.
~~~
This message alone doesn't tell you what actually went wrong, it just means the retry
limit was hit. To find the real cause, check the service and container logs:
~~~sh
journalctl --user -u lldap.service -e --no-pager | tail -n 100
podman logs lldap 2>&1 | tail -n 100
~~~
Once you've fixed the underlying issue, clear the failed/rate-limited state and start the
service again:
~~~sh
systemctl --user daemon-reload
systemctl --user reset-failed lldap.service
systemctl --user start lldap.service
~~~


### lldap fixed schema people

Lldap has a fixed schema - all user accounts always live under `ou=people`, no
matter what "group" you create through the lldap admin console (those are LDAP groups
under `ou=groups`, not organizational units for accounts).


### Mapping subdomains to the host gateway

Containers on the shared `opencloud` network resolve each other by container name
(e.g. `lldap`, `authelia`), but sometimes a container needs to reach a service via its
public subdomain instead - for example proxysthesis talking to Authelia through
`auth.tomho.eu` rather than the internal `authelia` name. Since that subdomain only
resolves on the host (or publicly), the container needs an extra host entry pointing it
back to the host itself:
~~~ini
AddHost=auth.tomho.eu:host-gateway
~~~
`host-gateway` is a special value podman resolves to the IP of the host from inside the
container, so the subdomain now reaches whatever is listening on the host (e.g. your
reverse proxy) instead of failing to resolve or hitting the wrong endpoint. Just add one
`AddHost=` line per subdomain you need mapped this way.


### Setting up a GitHub image repo (GHCR) for your own image

GitHub Container Registry (`ghcr.io`) can host your own small images (like proxysthesis),
so quadlets can pull them via `Image=ghcr.io/<user>/<image>:latest` just like the `lldap`
image above.

Create a Personal Access Token (classic) with `write:packages` scope, then login:
~~~sh
echo $GH_TOKEN | podman login ghcr.io -u <your-github-username> --password-stdin
~~~

A locally built image (e.g. `localhost/proxysthesis:latest`) can't be pushed directly,
it first needs to be tagged with the full `ghcr.io` reference so podman knows under which
name to publish it:
~~~sh
podman tag localhost/proxysthesis:latest ghcr.io/<your-github-username>/proxysthesis:latest
podman push ghcr.io/<your-github-username>/proxysthesis:latest
~~~

By default the pushed package is private - make it public in the package settings on
GitHub if you want anonymous pulls, otherwise use a read-only token on the podman host
when pulling.

