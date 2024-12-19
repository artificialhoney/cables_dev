FROM debian:latest AS build-stage

# Replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
RUN apt-get update && apt-get install -y -q --no-install-recommends \
        apt-transport-https \
        build-essential \
        ca-certificates \
        curl \
        git \
        libssl-dev \
        wget \
    && rm -rf /var/lib/apt/lists/*

ENV LD_LIBRARY_PATH=/lib/arm-linux-gnueabihf

ENV NVM_DIR /usr/app/.nvm
ENV NODE_VERSION 20.13.1
RUN mkdir -p $NVM_DIR
RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.40.1/install.sh | /bin/bash
RUN . $NVM_DIR/nvm.sh \
    && nvm install v$NODE_VERSION \
    && nvm alias default v$NODE_VERSION \
    && nvm use default

WORKDIR /usr/app
COPY ./ /usr/app
RUN chmod +x ./install_local.sh
RUN . $NVM_DIR/nvm.sh && ./install_local.sh https

FROM nginx:latest AS production-stage
COPY --from=build-stage /usr/app/cables_ui/dist /usr/share/nginx/html
COPY ./nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
