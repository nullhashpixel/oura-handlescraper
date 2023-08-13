#!/bin/bash
NODE_SOCKET=/cardano/mainnet/ipc/
mkdir -p ouralogs
docker run --mount type=bind,source=$NODE_SOCKET,target=/node-ipc --mount type=bind,source=${PWD}/daemon.toml,target=/etc/oura/daemon.toml -v ${PWD}/ouralogs:/logoutput -it ghcr.io/txpipe/oura:latest daemon
