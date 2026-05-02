#!/usr/bin/env bash

# BATS helper — must be sourced with `load '../helpers'`
# Navigate to project root for all tests
cd "$(dirname "$(dirname "$(dirname "$(readlink -f "$0")")")")"
