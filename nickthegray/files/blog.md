# Blog

## Deploying this website with LiveTerm
* 5/13/2022 - 11:18 AM

I was browsing [reddit.com/r/unixporn](https://reddit.com/r/unixporn) yesterday and stumbled upon a post showcasing a project called [LiveTerm](https://github.com/Cveinnt/LiveTerm). I thought to myself, this looks super cool! I want to use this as my personal website. It truly showcases my true nerdiness in an interactive fashion. After some tinkering, I had a Dockerfile ready that installs [node.js](https://nodejs.org/) on an Ubuntu base image.

Here's what the Dockerfile looks like:

<pre>
<code>
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
RUN git clone https://github.com/f0rkz/LiveTerm.git /app
RUN yarn install
ENTRYPOINT [ "yarn", "dev" ]
</code>
</pre>

Essentially, it installs node.js, clones a fork of the LiveTerm application that I modified and installs package dependencies. Of course, I wasn't done there. Next I was tinkering with actions to wire in [GitHub Packages](https://docs.github.com/en/packages) to service this docker container to my DMZ server. After a small amount of [GitHub Actions](https://github.com/features/actions), I was able to build the container and push it to the [GitHub Packages](https://docs.github.com/en/packages). But it was not enough... This was a showcase of me, after all. Let's deploy the website with CI/CD.

To the whiteboard (this one will be easy)!

<p align="center"><img src="https://static.nickthegray.com/img/2022-05-13_113753.png" alt="Whiteboard to the Rescue" /></p>

The concept should be easy. Using ansible and github actions self-hosted runners, we can run the workflows on the DMZ webserver and not have to deal with much credential exchange. I then deployed a docker container using the compose role I've used on several projects.

All the moving parts are here now! Let's complete the project.

<pre>
<code>
name: Create, publish, and deploy nickthegray.com

on:
  push:
    tags:
      - 'v*'
  release:
    types: [published]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build-and-push-image:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    
    steps:
      - uses: actions/checkout@v3

      - name: Log into registry
        uses: docker/login-action@f054a8b539a109f9f41c372932f1ae047eff08c9
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Extract metadata (tags, labels) for Docker
        id: meta
        uses: docker/metadata-action@98669ae865ea3cffbcbaa878cf57c20bbf1c6c38
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}

      - name: Build and push Docker image
        uses: docker/build-push-action@ad44023a93711e3deb337508980b4b5e9bcdc5dc
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
  deploy:
    if: ${{ success() }}
    runs-on: self-hosted
    needs: build-and-push-image
    steps:
      - uses: actions/checkout@v3
      - name: Install ansible
        run: pip install ansible
      - name: Run the playbook
        run: |
          cd ansible;
          ansible-playbook --connection=local --inventory 127.0.0.1, main.yml
</pre>
</code>

To put it simply: On tag creation with a v* name, build the docker container image and push it to GitHub Packages. On the success of the previous workflow (we don't want to deploy every time if the build fails) run the ansible-playbook main.yml on localhost. If you notice, the `runs-on` argument is set to `self-hosted`. This is a configured self-hosted runner specifically for this repo pointing to the DMZ webserver.

There you have it! A website deployment in a nutshell.

## First Post
* 5/13/2022 - 02:34 AM EST

Hello world!
