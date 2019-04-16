#!/usr/bin/env bash

# Generate a config if it doesn't exist
if [ ! -f "~/.jupyter/jupyter_notebook_config.py" ]; then
    jupyter notebook --generate-config
fi
