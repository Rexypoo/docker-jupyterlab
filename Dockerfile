ARG  TAG="3-stretch"
FROM python:${TAG} AS build
ARG BASEDIR="/jupyter-base"
WORKDIR $BASEDIR

# Install jupyterlab
RUN mkdir -p ve \
    && python3 -m venv $(pwd)/ve/jupyterlab \
    && . $(pwd)/ve/jupyterlab/bin/activate \
    && pip install --no-cache-dir jupyterlab

FROM build AS enable-widgets
# ipywidgets requries nodejs
COPY --from=node:lts-stretch /usr/local/ /usr/local/

# Install jupyter-widgets
RUN ve/jupyterlab/bin/jupyter \
    labextension install \
    @jupyter-widgets/jupyterlab-manager

# Remove node
FROM python:${TAG} AS remove-node
ARG BASEDIR="/jupyter-base"
COPY --from=enable-widgets ${BASEDIR}/ ${BASEDIR}/
WORKDIR ${BASEDIR}

# Include virtualenv for older python support
RUN python3 -m venv $(pwd)/ve/virtualenv \
    && . $(pwd)/ve/virtualenv/bin/activate \
    && pip install --no-cache-dir virtualenv

# Link jupyter and virtualenv to $PATH
RUN ln -s \
    $(pwd)/ve/jupyterlab/bin/jupyter \
    /usr/local/bin \
    && ln -s \
    $(pwd)/ve/virtualenv/bin/virtualenv \
    /usr/local/bin

# Configure a basic set of tools for jupyter terminal
RUN apt update && apt install -y \
    man \
    python-dev \
    tmux \
    vim \
    zip \
    && rm -rf /var/lib/apt/lists/*

FROM remove-node AS drop-privileges
ENV USER=jupyteruser

# Work in a user app directory
WORKDIR /jupyter

# Create the user and chown the working directory
RUN groupadd -g 9999 $USER \
    && useradd -u 9999 -g $USER $USER \
    && chown -R $USER:$USER $(pwd) \
    && usermod \
    --shell /bin/bash \
    --home $(pwd) \
    $USER

# From here forward files may be shared with host
# To ease sharing I want all files writeable by group
RUN chfn --other='umask=002' $USER

# Drop privileges
USER $USER

# Configure the default jupyter terminal shell
ENV SHELL=/bin/bash

# Create volume subfolders
RUN mkdir -p \
    .local/share/jupyter \
    config \
    kernels \
    notebooks \
    ve

# Include helpful scripts
# (This gets overridden by bind mounts)
COPY sh sh

# Link jupyter configuration files
RUN ln -s \
    $(pwd)/config $HOME/.jupyter \
    && ln -s \
    $(pwd)/kernels $HOME/.local/share/jupyter/

# Generate a default config file
# (This gets overridden by bind mounts)
RUN jupyter lab --generate-config

# Configure the server options
ENTRYPOINT ["jupyter","lab"]
CMD ["--ip=0.0.0.0","--no-browser","--notebook-dir=/jupyter/notebooks"]
EXPOSE 8888
# Persist the virtualenvs, kernels, config, etc.
VOLUME /jupyter

FROM drop-privileges AS dev
USER root
ENTRYPOINT ["/usr/bin/env","bash"]

FROM drop-privileges AS release

LABEL org.opencontainers.image.url="https://hub.docker.com/r/rexypoo/jupyterlab" \
      org.opencontainers.image.documentation="https://hub.docker.com/r/rexypoo/jupyterlab" \
      org.opencontainers.image.source="https://github.com/Rexypoo/docker-jupyterlab" \
      org.opencontainers.image.version="0.1a" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.ref.name="stretch" \
      org.opencontainers.image.description="Self-contained Jupyterlab image on Debian Stretch." \
      org.opencontainers.image.title="rexypoo/jupyterlab" \
      org.label-schema.docker.cmd="docker run -d \
    -p 127.0.0.1:8888:8888 \
    -v ~/notebooks:/jupyter/notebooks \
    -v /srv/jupyter/config:/jupyter/config \
    -v /srv/jupyter/kernels:/jupyter/kernels \
    -v /srv/jupyter/ve:/jupyter/ve \
    --name jupyterlab \
    --restart always \
    rexypoo/jupyterlab" \
      org.label-schema.docker.cmd.devel="docker run -it --rm rexypoo/jupyterlab:dev" \
      org.label-schema.docker.cmd.debug="docker exec -it --user root <container> bash" \
      org.label-schema.docker.cmd.help="docker run -it --rm rexypoo/jupyterlab jupyter lab --help"

# Note: you can get the server token with `docker exec -it <container> jupyter notebook list`
