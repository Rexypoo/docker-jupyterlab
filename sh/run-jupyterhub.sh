#!/usr/bin/env bash

# Pass command line arguments to jupyter
jupyter_args="$@"

# Generate a config if it doesn't exist
if [ ! -f "~/.jupyter/jupyter_notebook_config.py" ]; then
    jupyter notebook --generate-config
fi

/jupyter/ve/jupyterhub/bin/jupyter hub "$jupyter_args"
