FROM nvidia/opengl:1.0-glvnd-runtime-ubuntu16.04

################################## JUPYTERLAB ##################################

ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

RUN apt-get -o Acquire::ForceIPv4=true update && apt-get -yq dist-upgrade \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
	locales cmake git build-essential \
    python-pip \
	python3-pip python3-setuptools \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN pip3 install jupyterlab==0.35.4 bash_kernel==0.7.1 tornado==5.1.1 \
 && python3 -m bash_kernel.install

ENV SHELL=/bin/bash \
	NB_USER=jovyan \
	NB_UID=1000 \
	LANG=en_US.UTF-8 \
	LANGUAGE=en_US.UTF-8

ENV HOME=/home/${NB_USER}

RUN adduser --disabled-password \
	--gecos "Default user" \
	--uid ${NB_UID} \
	${NB_USER}

EXPOSE 8888

CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0", "--NotebookApp.token=''"]

###################################### ROS #####################################

# install packages
RUN apt-get -o Acquire::ForceIPv4=true update && apt-get -o Acquire::ForceIPv4=true install -q -y \
    dirmngr \
    gnupg2 \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# setup keys
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 421C365BD9FF1F717815A3895523BAEEB01FA116

# setup sources.list
RUN echo "deb http://packages.ros.org/ros/ubuntu `lsb_release -sc` main" > /etc/apt/sources.list.d/ros-latest.list

# install bootstrap tools
RUN apt-get -o Acquire::ForceIPv4=true update && apt-get -o Acquire::ForceIPv4=true install --no-install-recommends -y \
    python-rosdep \
    python-rosinstall \
    python-vcstools \
    python-catkin-tools \
    && rm -rf /var/lib/apt/lists/*

# bootstrap rosdep
RUN rosdep init \
    && rosdep update

# install ros packages
ENV ROS_DISTRO kinetic
RUN apt-get -o Acquire::ForceIPv4=true update && apt-get -o Acquire::ForceIPv4=true install -y \
    ros-kinetic-ros-base=1.3.2-0* \
    && rm -rf /var/lib/apt/lists/*

# setup entrypoint
COPY ./ros_entrypoint.sh /

ENTRYPOINT ["/ros_entrypoint.sh"]

##################################### APT ######################################

RUN apt-get -o Acquire::ForceIPv4=true update \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
    qt5-default \
    libqt5svg5-dev \
    git \
    subversion \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

##################################### PIP ######################################

RUN pip install  \
    sympy==0.7.1

################################### SOURCE #####################################

RUN apt-get -o Acquire::ForceIPv4=true update \
 && apt-get -o Acquire::ForceIPv4=true install -yq --no-install-recommends \
    libassimp-dev \
    libxml2-dev \
    libboost-dev \
    libboost-python-dev \
    libeigen3-dev \
    libbullet-dev \
    libode-dev \
    liblapack-dev \
    python-scipy \
    libfcl-dev \
    collada-dom2.4-dp* \
    libsoqt4-dev \
    coreutils \
    nano \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/rdiankov/openrave.git /openrave \
 && cd /openrave \
 && mkdir build \
 && cd build \
 && cmake  ../ \
 && make -j4 install \
 && rm -fr /openrave

RUN git clone https://github.com/crigroup/openrave_catkin.git /openrave_catkin \
 && cd /openrave_catkin \
 && mkdir -p ${HOME}/catkin_ws/src \
 && cp -R /openrave_catkin ${HOME}/catkin_ws/src/. \
 && cd ${HOME}/catkin_ws \
 && apt-get -o Acquire::ForceIPv4=true update \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep update && rosdep install --as-root apt:false --from-paths src --ignore-src -r -y" \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_make" \
 && rm -fr /openrave_catkin

RUN git clone https://github.com/crigroup/raveutils.git /raveutils \
 && cd /raveutils \
 && mkdir -p ${HOME}/catkin_ws/src \
 && cp -R /raveutils ${HOME}/catkin_ws/src/. \
 && cd ${HOME}/catkin_ws \
 && apt-get -o Acquire::ForceIPv4=true update \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep update && rosdep install --as-root apt:false --from-paths src --ignore-src -r -y" \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_make" \
 && rm -fr /raveutils

##################################### COPY #####################################

RUN mkdir ${HOME}/robotsp

COPY . ${HOME}/robotsp

#################################### CATKIN ####################################

RUN mkdir -p ${HOME}/catkin_ws/src && ln -s ${HOME}/robotsp ${HOME}/catkin_ws/src/.

RUN cd ${HOME}/catkin_ws \
 && apt-get -o Acquire::ForceIPv4=true update \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && rosdep update && rosdep install --as-root apt:false --from-paths src --ignore-src -r -y" \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && /bin/bash -c "source /opt/ros/${ROS_DISTRO}/setup.bash && catkin_make"

RUN echo "source ~/catkin_ws/devel/setup.bash" >> ${HOME}/.bashrc

##################################### TAIL #####################################

RUN chown -R ${NB_UID} ${HOME}

USER ${NB_USER}

WORKDIR ${HOME}/robotsp
