#!/bin/bash
PATH_ENV="./path.env"
if [ ! -f "$PATH_ENV" ]; then
    echo -e "${PATH_ENV} does not exist.\n\n    echo \"path/to/ouralogs\" > ${PATH_ENV}\n\nto create it."
    exit 2
fi

SOURCE_TYPE="N2N"
SOURCE_BEARER="Tcp"
SOURCE_ADDRESS="relays-new.cardano-mainnet.iohk.io:3001"
NODE_ENV="./node.env"
unset LOCAL_NODE_SOCKET
if [ -f "$NODE_ENV" ]; then
    SOURCE_TYPE="N2C"
    SOURCE_BEARER="Unix"
    SOURCE_ADDRESS="\/ipc\/node.socket"
    LOCAL_NODE_SOCKET=$( cat $NODE_ENV )
fi

docker stop oura_handlescraper
docker rm oura_handlescraper
     
OURALOGS_PATH=$( cat $PATH_ENV )
BLOCK_HASH="89f93419845d5f6ce8040fd5eeedda93d764c8569f7c2cc6802a8429a0da877b"
SLOT="47931310"
MAXBYTES="1000000"

echo "log path: ${OURALOGS_PATH}"
if ls ${OURALOGS_PATH}/ouralogs* 1> /dev/null 2>&1; then
    ls -1rt ${OURALOGS_PATH}/ouralogs* | tail -n1
    cat $( ls -1rt ${OURALOGS_PATH}/ouralogs* | tail -n1 ) | tail -n1 > last_tx
    BLOCK_HASH=$( cat last_tx | jq -r .context.block_hash )
    SLOT=$( cat last_tx | jq -r .context.slot )
    MAXBYTES="10000"
else
    echo "starting from genesis"
fi

if [ ${#SLOT} -le 1 ]; then
    BLOCK_HASH="89f93419845d5f6ce8040fd5eeedda93d764c8569f7c2cc6802a8429a0da877b"
    SLOT="47931310"
fi
echo "starting from ${BLOCK_HASH} ${SLOT}..."

cat daemon.template | sed "s/{block}/${BLOCK_HASH}/g" | sed "s/{slot}/${SLOT}/g" | sed "s/{maxbytes}/${MAXBYTES}/g" | sed "s/{type}/${SOURCE_TYPE}/g" | sed "s/{bearer}/${SOURCE_BEARER}/g" | sed "s/{address}/${SOURCE_ADDRESS}/g" |  tee daemon.toml

if [ -n ${LOCAL_NODE_SOCKET+x} ]; then
    echo "starting oura with local node: ${LOCAL_NODE_SOCKET} ..."
    docker run --name oura_handlescraper --mount type=bind,source=${LOCAL_NODE_SOCKET},target="/ipc" --mount type=bind,source=${PWD}/daemon.toml,target=/etc/oura/daemon.toml -v ${OURALOGS_PATH}:/logoutput -it ghcr.io/txpipe/oura:latest daemon
else
    echo "starting oura with remote node..."
    docker run --name oura_handlescraper --mount type=bind,source=${PWD}/daemon.toml,target=/etc/oura/daemon.toml -v ${OURALOGS_PATH}:/logoutput -it ghcr.io/txpipe/oura:latest daemon
fi
