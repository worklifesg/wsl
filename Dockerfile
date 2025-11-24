FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y debootstrap tar xz-utils sudo curl wget gnupg lsb-release
WORKDIR /workspace
COPY . /workspace
CMD ["bash","build.sh"]
