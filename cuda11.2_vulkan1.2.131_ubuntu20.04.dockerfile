FROM nvidia/cudagl:11.2.2-devel-ubuntu20.04

# This is found at
# https://askubuntu.com/questions/909277/avoiding-user-interaction-with-tzdata-when-installing-certbot-in-a-docker-contai
# and
# http://p.cweiske.de/582
#

# Allow using GUI apps.
ENV TERM=xterm
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y tzdata \
 && ln -fs /usr/share/zoneinfo/America/New_York /etc/localtime \
 && dpkg-reconfigure --frontend noninteractive tzdata \
 && apt-get clean

# Some useful tools.
RUN apt-get update \
 && apt-get install --no-install-recommends -y \
        build-essential sudo \
        cmake \
        gdb \
        git \
        vim \
        tmux \
        wget \
        less \
        curl \
        htop \
        python3-pip \
        python-tk \
        libsm6 libxext6 \
        libboost-all-dev zlib1g-dev \
        lsb-release \
 && apt-get clean

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        libsdl2-dev \
        && \
    apt-get clean

ARG VULKAN_VERSION=1.2.131

# https://vulkan.lunarg.com/sdk/home
# Works on both Ubuntu 20.04 (focal) and 18.04 (bionic).
RUN wget -qO - https://packages.lunarg.com/lunarg-signing-key-pub.asc | sudo apt-key add - && \
    wget -qO /etc/apt/sources.list.d/lunarg-vulkan-${VULKAN_VERSION}-bionic-focal.list https://packages.lunarg.com/vulkan/${VULKAN_VERSION}/lunarg-vulkan-${VULKAN_VERSION}-bionic.list && \
    apt update && \
    apt install vulkan-sdk -y && \
    apt-get clean

# Copied from
# https://github.com/carla-simulator/carla/blob/78e7ea11306ca164fb664ec74d2224f2e1d01923/Util/Docker/Release.Dockerfile#L15
RUN VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9|\.]+'` && \
	mkdir -p /etc/vulkan/icd.d/ && \
	echo \
	"{\
		\"file_format_version\" : \"1.0.0\",\
		\"ICD\": {\
			\"library_path\": \"libGLX_nvidia.so.0\",\
			\"api_version\" : \"${VULKAN_API_VERSION}\"\
		}\
	}" > /etc/vulkan/icd.d/nvidia_icd.json \

# Add a user with the same user_id and group_id as the user outside the container.
ARG user_id=1000
ARG group_id=100
ARG user_name=unreal
ARG group_name=users_1
# The "users" group with id=100 is already in the system.
# For other group setting, uncomment the following.
# RUN groupadd -g ${group_id} ${group_name}
ENV USERNAME ${user_name}
RUN useradd --uid ${user_id} --gid ${group_id} -ms /bin/bash $USERNAME \
 && echo "$USERNAME:$USERNAME" | chpasswd \
 && adduser $USERNAME sudo \
 && echo "$USERNAME ALL=NOPASSWD: ALL" >> /etc/sudoers.d/$USERNAME \
 && adduser $USERNAME audio \ 
 && adduser $USERNAME video

# Run as the new user.
USER $USERNAME

# Container start dir.
WORKDIR /home/$USERNAME

# Entrypoint command.
CMD /bin/bash
