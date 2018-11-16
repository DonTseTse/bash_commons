#! /bin/bash

### print_sources
# Prints $BASH_SOURCE 
function print_sources()
{
        local src
        for src in "${BASH_SOURCE[@]}"; do
                echo "$src"
        done
}
