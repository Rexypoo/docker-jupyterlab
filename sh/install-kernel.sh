#!/usr/bin/env sh

if [ -z "$VIRTUAL_ENV" ]; then
    >&2 echo "Error: unable to determine the virtual environment. Please activate a virtual environment or install manually."
    >&2 echo 'Install manually with: python -m ipykernel install --user --name VENV_NAME --display-name "VENV DISPLAY NAME"'
    exit 1
fi

workdir=$(basename "$VIRTUAL_ENV")
name=${1:-$workdir}
display=${2:-$name}

pip install ipykernel
python -m ipykernel install --user --name "$name" --display-name "$display"
