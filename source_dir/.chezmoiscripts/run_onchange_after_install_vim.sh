#!/bin/bash

set -euo pipefail

if ! command -v vim >/dev/null; then
    echo "Installing Vim..."
    sudo apt update && sudo apt install vim -y
    echo "Vim done!"
fi
