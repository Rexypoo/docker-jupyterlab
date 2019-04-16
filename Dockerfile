ARG  TAG="3-stretch"
FROM python:${TAG} AS build
ARG BASEDIR="/jupyter-base"
WORKDIR $BASEDIR

# Install jupyterlab
RUN mkdir -p ve \
    && python3 -m venv $(pwd)/ve/jupyterlab \
    && . $(pwd)/ve/jupyterlab/bin/activate \
    && pip install --no-cache-dir jupyterlab

# Include virtualenv to support older python environments
RUN python3 -m venv $(pwd)/ve/virtualenv \
    && . $(pwd)/ve/virtualenv/bin/activate \
    && pip install --no-cache-dir virtualenv

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


FROM remove-node AS configure-environment

# Link jupyter and virtualenv to $PATH
RUN ln -s \
    $(pwd)/ve/jupyterlab/bin/jupyter \
    /usr/local/bin \
    && ln -s \
    $(pwd)/ve/virtualenv/bin/virtualenv \
    /usr/local/bin

# python-dev is required for some pip packages
RUN apt update && apt install -y \
    python-dev \
    && rm -rf /var/lib/apt/lists/*

# Configure a basic set of tools for jupyter terminal
RUN apt update && apt install -y \
    bash \
    man \
    tmux \
    vim \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Set up a clean and sensible home directory
ENV HOME=/jupyter

# Configure the default jupyter terminal shell
ENV SHELL=/bin/bash

WORKDIR $HOME

# Patch settings into /etc/passwd
RUN sed -i "s|^root.*$|root:x:0:0:root:$HOME:$SHELL|" /etc/passwd

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

# Link jupyter configuration files to the root of the volume
RUN ln -s $(pwd)/config $HOME/.jupyter \
    && ln -s $(pwd)/kernels $HOME/.local/share/jupyter/

# Generate a default config file
# (This gets overridden by bind mounts)
RUN jupyter lab --generate-config

# Configure the server options
ENTRYPOINT ["jupyter","lab"]
CMD ["--ip=0.0.0.0","--no-browser","--notebook-dir=/jupyter/notebooks","--allow-root"]
EXPOSE 8888
# Persist the virtualenvs, kernels, config, etc.
VOLUME /jupyter

FROM configure-environment AS dev
ENTRYPOINT ["/usr/bin/env","bash"]

FROM configure-environment AS release

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
