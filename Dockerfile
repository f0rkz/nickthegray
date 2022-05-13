FROM ubuntu:20.04
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -yq && apt install -y --no-install-recommends \
        wget \
        git \
        ca-certificates \
        curl \
        gnupg
RUN wget https://deb.nodesource.com/setup_14.x -O /tmp/install_node.sh && bash /tmp/install_node.sh
RUN apt install -y nodejs

RUN curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg >/dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN apt update -yq && apt install -y yarn
RUN mkdir -p /app
WORKDIR /app
RUN git clone https://github.com/Cveinnt/LiveTerm.git /app
RUN yarn install
