#!/bin/bash
docker stop oura_handlescraper
docker rm oura_handlescraper
OURALOGS_PATH=$( cat path.env )
cat $( ls -1rt ${OURALOGS_PATH}/ouralogs* | tail -n1 ) | tail -n1 > last_tx
BLOCK_HASH=$( cat last_tx | jq -r .context.block_hash )
SLOT=$( cat last_tx | jq -r .context.slot )
echo "starting from ${BLOCK_HASH} ${SLOT}..."
cat daemon.template | sed "s/{block}/${BLOCK_HASH}/g" | sed "s/{slot}/${SLOT}/g" | tee daemon.toml
docker run --name oura_handlescraper --mount type=bind,source=${PWD}/daemon.toml,target=/etc/oura/daemon.toml -v ${OURALOGS_PATH}:/logoutput -it ghcr.io/txpipe/oura:latest daemon
