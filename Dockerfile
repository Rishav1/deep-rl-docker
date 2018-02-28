FROM tensorflow/tensorflow:1.4.0-py3
MAINTAINER USC RESL <heiden@usc.edu>

ARG USER
ARG HOME

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 USER=$USER HOME=$HOME

RUN echo "The working directory is: $HOME"
RUN echo "The user is: $USER"

RUN mkdir -p $HOME
WORKDIR $HOME

RUN apt-get update && apt-get install -y \
        sudo \
        git \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# install dependencies
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    build-essential \
    curl \
    nano \
    vim \
    libfreetype6-dev \
    libpng12-dev \
    libzmq3-dev \
    git \
    python-numpy \
    python-dev \
    python-opengl \
    cmake \
    zlib1g-dev \
    libjpeg-dev \
    xvfb \
    libav-tools \
    xorg-dev \
    libboost-all-dev \
    libsdl2-dev \
    swig \
    libgtk2.0-dev \
    wget \
    unzip \
    aptitude \
    pkg-config \
    qtbase5-dev \
    libqt5opengl5-dev \
    libassimp-dev \
    libpython3.5-dev \
    libboost-python-dev \
    libtinyxml-dev \
    golang \
    python-opencv \
    terminator \
    tmux \
    libcanberra-gtk-module \
    libfuse2 \
    libnss3 \
    fuse \
    python3-tk \
    libglfw3-dev \
    libgl1-mesa-dev \
    libgl1-mesa-glx \
    libglew-dev \
    libosmesa6-dev \
    net-tools \
    xpra \
    xserver-xorg-dev \
    libffi-dev \
    libxslt1.1 \
    libglew-dev \
    parallel \
    htop

RUN pip3 install --upgrade pip

RUN pip3 --no-cache-dir install \
    gym[all]==0.9.4 \
    scikit-image \
    plotly \
    ipykernel \
    jupyter \
    jupyterlab \
    matplotlib \
    numpy \
    scipy \
    sklearn \
    pandas \
    Pillow \
    empy \
    tqdm \
    pyopengl \
    mujoco-py==0.5.7 \
    ipdb \
    cloudpickle \
    imageio \
    mpi4py \
    jsonpickle \
    gtimer

# Set up permissions to use same UID and GID as host system user
# https://denibertovic.com/posts/handling-permissions-with-docker-volumes/
RUN apt-get -y --no-install-recommends install \
    ca-certificates \
    curl
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.4/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

# Install Jupyter Lab
RUN jupyter serverextension enable --py jupyterlab --sys-prefix

# Install Baselines
RUN cd /opt && git clone https://github.com/openai/baselines.git && cd baselines && pip install -e .

# Install Roboschool
ENV ROBOSCHOOL_PATH=/opt/roboschool
WORKDIR /opt
RUN git clone https://github.com/openai/roboschool.git /opt/roboschool
RUN git clone https://github.com/olegklimov/bullet3 -b roboschool_self_collision \
    && mkdir bullet3/build \
    && cd    bullet3/build \
    && cmake -DBUILD_SHARED_LIBS=ON -DUSE_DOUBLE_PRECISION=1 -DCMAKE_INSTALL_PREFIX:PATH=$ROBOSCHOOL_PATH/roboschool/cpp-household/bullet_local_install -DBUILD_CPU_DEMOS=OFF -DBUILD_BULLET2_DEMOS=OFF -DBUILD_EXTRAS=OFF  -DBUILD_UNIT_TESTS=OFF -DBUILD_CLSOCKET=OFF -DBUILD_ENET=OFF -DBUILD_OPENGL3_DEMOS=OFF .. \
    && make -j4 \
    && make install
RUN pip3 install -e /opt/roboschool

ENV DOCKER_HOME=$HOME

COPY ./internal/ /

# Install VirtualGL
RUN dpkg -i /virtualgl_2.5.2_amd64.deb && rm /virtualgl_2.5.2_amd64.deb

# Install MuJoCo 1.50 and 1.31
WORKDIR /opt
RUN mkdir mujoco && cd mujoco \
    && wget https://www.roboti.us/download/mjpro150_linux.zip \
    && unzip mjpro150_linux.zip \
    && rm mjpro150_linux.zip \
    && wget https://www.roboti.us/download/mjpro131_linux.zip \
    && unzip mjpro131_linux.zip \
    && rm mjpro131_linux.zip \
    && if [ -f "/mjkey.txt" ]; \
        then \
            mv /mjkey.txt . && \
            cp mjkey.txt mjpro150/bin/ && \
            cp mjkey.txt mjpro131/bin/ && \
            echo "Installed MuJoCo Key file." ; \
        else \
            echo "Could not find MuJoCo key file (mjkey.txt) in ./internal!\nPlease copy it manually to ~/.mujoco when inside the docker container." 1>&2 ; \
       fi
ENV MUJOCO_PY_MJPRO_PATH=/opt/mujoco/mjpro150
ENV MUJOCO_LICENSE_KEY=/opt/mujoco/mjkey.txt
ENV MUJOCO_PY_MUJOCO_PATH=/opt/mujoco
ENV LD_LIBRARY_PATH /opt/mujoco/mjpro150/bin:$LD_LIBRARY_PATH

ENV TERM xterm-256color


# Install mujoco-py
RUN pip3 --no-cache-dir install mujoco-py==0.5.7
# # see https://github.com/ryanjulian/mujoco-py/blob/master/Dockerfile
# WORKDIR /opt
# RUN curl -o /usr/local/bin/patchelf https://s3-us-west-2.amazonaws.com/openai-sci-artifacts/manual-builds/patchelf_0.9_amd64.elf \
#     && chmod +x /usr/local/bin/patchelf

# RUN git clone https://github.com/ryanjulian/mujoco-py.git
# WORKDIR /opt/mujoco-py
# RUN pip3 install -r requirements.txt
# RUN pip3 install -r requirements.dev.txt
# RUN python3 setup.py install
# # Cythonize mujoco-py
# RUN python3 -c "import mujoco_py; print('Successfully cythonized mujoco-py.')"

# TensorBoard
EXPOSE 6006

# Jupyter
EXPOSE 8888

ENTRYPOINT ["/docker-entrypoint.sh"]
