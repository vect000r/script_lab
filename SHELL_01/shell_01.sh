#!/bin/bash


# check the number of arguments
if (( $# < 1 || $# > 2)); then
    printf 'Expected: only B or A and B' >&2
    exit 2
fi

# check if the arguments are integers
for argument in "$@"; do
    if [[ ! $argument =~ ^-?(0|[1-9][0-9]*)$ ]]; then
        printf 'The arguments must be integers!' "$argument" >&2
        exit 2
    fi
done

# check if A > B 
if [ $A -gt $B ]; then 
    printf 'Error! A > B!' >&2
    exit 2 
fi

A="$1"
B="$2"
