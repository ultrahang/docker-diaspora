# Diaspora*

![Diaspora Logo](https://i.imgur.com/J50tnoC.png)

[Diaspora](https://diasporafoundation.org/) is a nonprofit, user-owned, distributed social network that is based upon the free Diaspora software. Diaspora consists of a group of independently owned nodes (called pods) which interoperate to form the network.

 **Automated build of the image can be found on the [Docker Hub](https://hub.docker.com/u/ultrahang/diaspora/).**

 **forked from angristan/docker-diaspora which is not updated any more by the original maintainer**


  - updated to 0.7.12.0
  - added libjemalloc-dev for improving memory usage

## Features

- Based on the official [ruby:2.4-slim-stretch](https://hub.docker.com/_/ruby/) image
- Running the latest stable version of [diaspora/diaspora](https://github.com/diaspora/diaspora)
- Ran as an unprivileged user (see `UID` and `GID`)

### Build-time variables

- **`DIASPORA_VER`**: Diaspora version (`0.8.0.0`)
- **`GID`**: group id *(default: `942`)*
- **`UID`**: user id *(default: `942`)*

### Volumes

- **`/diaspora/public`**: location of the assets and user uploads

## Usage

The image can work *as-is* using the provided docker-compose.yml, diaspora.yml, database.yml, nginx-vhost.conf configuration files. 

It is recommended to change at least the diaspora.yml in order to get it work in production environment - otherwise it listens on http://localhost .


### Configuration files

**Before** doing anything, modify the **database.yml** as per your needs in case you use different database setup. The included **docker-compose.yml** uses a standalone postgress container for the database.

Do the same with **diaspora.yml** and **read it** completely. Diaspora starts on localhost with the provided defaults.

FYI you will need to modify these at least:

- environment.url
- server.rails_environment: `production`

### Docker Compose

Here is the included `docker-compose.yml`:

```yaml
version: '2.3'

services:
  postgres:
    container_name: diaspora_postgres
    image: postgres:9.6-alpine
    restart: always
    volumes:
      - ./postgres:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=diaspora
      - POSTGRES_PASSWORD=diaspora
      - POSTGRES_DB=diaspora_production

  redis:
    container_name: diaspora_redis
    image: redis:4.0-alpine
    restart: always
    volumes:
      - ./redis:/data

  unicorn:
    container_name: diaspora_unicorn
    image: ultrahang/diaspora:latest
    restart: always
    command: bin/bundle exec unicorn -c config/unicorn.rb -E production
    volumes:
      - ./data:/diaspora/public/
      - ./diaspora.yml:/diaspora/config/diaspora.yml
      - ./database.yml:/diaspora/config/database.yml
    depends_on:
      - postgres
      - redis

  sidekiq:
    container_name: diaspora_sidekiq
    image: ultrahang/diaspora:latest
    restart: always
    command: bin/bundle exec sidekiq
    volumes:
      - ./data:/diaspora/public/
      - ./diaspora.yml:/diaspora/config/diaspora.yml
      - ./database.yml:/diaspora/config/database.yml
    depends_on:
      - postgres
      - redis

  nginx:
    container_name: diaspora_nginx
    image: nginx:stable
    restart: always
    volumes:
      - ./nginx-vhost.conf:/etc/nginx/conf.d/default.conf:ro
      - ./data:/var/www/html
    ports:
      - 127.0.0.1:80:80
```

We need a Nginx container to server the uploads and assets, as Unicorn doesn't do it.

Here is the example Nginx vhost configuration file with no SSL support:

```nginx
server {
    listen 80;

    root /var/www/html;

    client_max_body_size 5M;
    client_body_buffer_size 256K;

    try_files $uri @diaspora;

    location /assets/ {
        expires max;
        add_header Cache-Control public;
    }

    location @diaspora {
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://unicorn:3000;
    }
}
```

I assume you're using another container for HTTPS, but feel free to use this as a base if it's not the case.

### Installation

When running the instance for the first time, run this command to setup the database:

```sh
docker-compose run --rm unicorn bin/rake db:create db:migrate
```

Then compile the assets:

```sh
docker-compose run --rm unicorn bin/rake assets:precompile
```

You can now lauch your pod!

```sh
docker-compose up -d
```

You can check your Diaspora installation on the http://localhost with no modification on the configuraiton files. To set the administrator account follow the [Official FAQ instructions](https://wiki.diasporafoundation.org/FAQ_for_pod_maintainers#What_are_roles_and_how_do_I_use_them.3F_.2F_Make_yourself_an_admin_or_assign_moderators) after creating an account on the site.



### Update

Modify the versions in your `docker-compose.yml`, then pull the new images:

```sh
docker-compose pull
```

Update the database:

```sh
docker-compose run --rm unicorn bin/rake db:migrate
```

Then compile the assets:

```sh
docker-compose run --rm unicorn bin/rake assets:precompile
```

Recreate containers with new images:

```sh
docker-compose up -d
```
