FROM nvidia/vulkan:1.1.121-cuda-10.1--ubuntu18.04

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
        git \
        cmake \
        gdb \
        vim \
        tmux \
        htop \
        curl \
        wget \
        less \
        python3-pip \
        python-tk \
        libsm6 libxext6 \
        libboost-all-dev zlib1g-dev \
        lsb-release \
 && apt-get clean

# Copied from
# https://github.com/carla-simulator/carla/blob/78e7ea11306ca164fb664ec74d2224f2e1d01923/Util/Docker/Release.Dockerfile#L15
RUN packages='libsdl2-2.0-0 libsdl2-dev xserver-xorg libvulkan1 libvulkan-dev' \
       && apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $packages --no-install-recommends \
       && VULKAN_API_VERSION=`dpkg -s libvulkan1 | grep -oP 'Version: [0-9|\.]+' | grep -oP '[0-9|\.]+'` && \
	mkdir -p /etc/vulkan/icd.d/ && \
	echo \
	"{\
		\"file_format_version\" : \"1.0.0\",\
		\"ICD\": {\
			\"library_path\": \"libGLX_nvidia.so.0\",\
			\"api_version\" : \"${VULKAN_API_VERSION}\"\
		}\
	}" > /etc/vulkan/icd.d/nvidia_icd.json \
	&& rm -rf /var/lib/apt/lists/*

# Add a user with the same user_id and group_id as the user outside the container.
ARG user_id=1001
ARG group_id=100
ARG user_name=unreal
ARG group_name=sard
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
