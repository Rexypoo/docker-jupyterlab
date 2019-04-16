
# docker-jupyterlab

Stand-alone [Jupyterlab] server on Debian Stretch with ipywidgets installed.

# Prerequisites

[Docker] 17.05+

# Usage

## Retrieving the Image

```shell
docker pull rexypoo/jupyterlab
```

## Authentication tokens

When running Jupyterlab as a daemon it won't print out the authentication token.  You can use docker exec to either set a password or print out the token.

### Configuring a password

This method works well for a permanently running notebook server

```shell
docker run -d --restart unless-stopped -p 127.0.0.1:8888:8888 --name jupyterlab rexypoo/jupyterlab
docker exec -it jupyterlab jupyter notebook password
Enter password:                                                                                                          
Verify password:                                                                      
[NotebookPasswordApp] Wrote hashed password to /jupyter/.jupyter/jupyter_notebook_config.json  
docker restart jupyterlab
```

## Sharing files with host

By default the jupyter server runs as a user other than root for security. The default user has UID and GID of 9999.

To make files accessible to both the host and the docker environment you should allow write permissions to group 9999.

E.g. to share your notebook directory:

```shell
mkdir ~/notebooks
chown -r $(whoami):9999 ~/notebooks
chmod g+w -r ~/notebooks
```

Now you can start docker with the notebook directory as a bind mount.

```shell
docker run -d --rm -v ~/notebooks:/jupyter/notebooks --name jupyterlab rexypoo/jupyterlab
docker exec -it jupyterlab jupyter notebook list
```

This will start a container "jupyterlab", enable saving notebooks to the host, and list the authentication token

After managing the permissions the volume can be shared with the docker container. 


## Starting Jupyterlab as daemon



You can run the basic command line interface for OpenSSL by running the image interactively:
```shell
docker run -it --rm rexypoo/openssl
```
You can also provide command line arguments to OpenSSL:
```shell
docker run -it --rm rexypoo/openssl genpkey -algorithm ed25519
```

See the Dockerfile labels related to `org.label-schema.docker.cmd` for more information.

[Jupyterlab]: https://github.com/jupyterlab/jupyterlab
[Docker]: https://www.docker.com
