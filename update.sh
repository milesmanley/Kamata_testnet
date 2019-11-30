#!/bin/bash

COIN_NAME='zelcash'

#wallet information
COIN_DAEMON='./src/zelcashd'
COIN_CLI='/src/zelcash-cli'
USERNAME="$(whoami)"

#color codes
YELLOW='\033[1;33m'
RED='\033[1;31m'
SEA="\\033[38;5;49m"
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"

#end of required details
#

#Stop any zel instances
echo -e "${YELLOW}Stopping any instances of Zel to update...${NC}"
~/$COIN_NAME/$COIN_CLI stop > /dev/null 2>&1 && sleep 2
sudo killall ${COIN_NAME}d > /dev/null 2>&1
cd ~/$COIN_NAME
git pull && make
$COIN_DAEMON > /dev/null 2>&1
echo -e "${SEA}Update is complete...${NC}"
