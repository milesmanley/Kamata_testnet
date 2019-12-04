#!/bin/bash

###############################################################################################################################################################################################################
# IF PLANNING TO RUN ZELNODE FROM HOME/OFFICE/PERSONAL EQUIPMENT & NETWORK!!!
# You must understand the implications of running a ZelNode on your on equipment and network. There are many possible security issues. DYOR!!!
# Running a ZelNode from home should only be done by those with experience/knowledge of how to set up the proper security.
# It is recommended for most operators to use a VPS to run a ZelNode
#
# **Potential Issues (not an exhaustive list):**
# 1. Your home network IP address will be displayed to the world. Without proper network security in place, a malicious person sniff around your IP for vulnerabilities to access your network.
# 2. Port forwarding: The p2p port for ZelCash will need to be open.
# 3. DDOS: VPS providers typically provide mitigation tools to resist a DDOS attack, while home networks typically don't have these tools.
# 4. Zelcash daemon is ran with sudo permissions, meaning the daemon has elevated access to your system. **Do not run a ZelNode on equipment that also has a funded wallet loaded.**
# 5. Static vs. Dynamic IPs: If you have a revolving IP, every time the IP address changes, the ZelNode will fail and need to be stood back up.
# 6. Home connections typically have a monthly data cap. ZelNodes will use 2.5 - 6 TB monthly usage depending on ZelNode tier, which can result in overage charges. Check your ISP agreement.
# 7. Many home connections provide adequate download speeds but very low upload speeds. ZelNodes require 100mbps (12.5MB/s) download **AND** upload speeds. Ensure your ISP plan can provide this continually. 
# 8. ZelNodes can saturate your network at times. If you are sharing the connection with other devices at home, its possible to fail a benchmark if network is saturated.
###############################################################################################################################################################################################################

###### you must be logged in as a sudo user, not root #######

COIN_NAME='zelcash'

#wallet information

UPDATE_SCRIPT='https://raw.githubusercontent.com/dk808/Kamata_testnet/master/update.sh'
UPDATE_FILE='update.sh'
CONFIG_DIR='.zelcash'
CONFIG_FILE='zelcash.conf'
RPCPORT='26124'
PORT='26125'
SSHPORT='22'
COIN_DAEMON='./src/zelcashd'
COIN_CLI='./src/zelcash-cli'
USERNAME="$(whoami)"

#color codes
RED='\033[1;31m'
YELLOW='\033[1;33m'
BLUE="\\033[38;5;27m"
SEA="\\033[38;5;49m"
GREEN='\033[1;32m'
CYAN='\033[1;36m'
NC='\033[0m'

#emoji codes
CHECK_MARK="${GREEN}\xE2\x9C\x94${NC}"
X_MARK="${RED}\xE2\x9D\x8C${NC}"
PIN="${RED}\xF0\x9F\x93\x8C${NC}"

#end of required details
#

#Suppressing password prompts for this user so zelnode can operate
clear
sudo echo -e "$(whoami) ALL=(ALL) NOPASSWD:ALL" | sudo EDITOR='tee -a' visudo
echo -e "${YELLOW}====================================================================="
echo -e " Zelnode Kamata Testnet"
echo -e "=====================================================================${NC}"
echo -e "${CYAN}Nov 2019, revamped by dk808 from AltTank Army and Zel's team."
echo -e "Special thanks to Goose-Tech, Skyslayer, & Packetflow"
echo -e "Node setup starting, press [CTRL+C] to cancel.${NC}"
sleep 5
if [ "$USERNAME" = "root" ]; then
	echo -e "${CYAN}You are currently logged in as ${GREEN}root${CYAN}, please switch to the username you just created.${NC}"
	exit
fi

#functions
function wipe_clean() {
	echo -e "${YELLOW}Removing any instances of ${COIN_NAME^}${NC}"
	~/$COIN_NAME/src/${COIN_NAME}-cli stop > /dev/null 2>&1 && sleep 2
	sudo killall ${COIN_NAME}d > /dev/null 2>&1
	sudo rm -rf zelcash
	sudo rm -rf .zelbenchmark
	rm zelnodeupdate.sh > /dev/null 2>&1
}

function spinning_timer() {
	animation=( ⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏ )
	end=$((SECONDS+$NUM))
	while [ $SECONDS -lt $end ];
	do
		for i in ${animation[@]};
		do
			echo -ne "${RED}\r$i ${CYAN}${MSG1}${NC}"
			sleep 0.1
		done
	done
	echo -e "${MSG2}"
}

function ssh_port() {
	echo -e "${YELLOW}Detecting SSH port being used...${NC}" && sleep 1
	SSHPORT=$(grep -w Port /etc/ssh/sshd_config | sed -e 's/.*Port //')
	whiptail --yesno "Detected you are using $SSHPORT for SSH is this correct?" 8 56
	if [ $? = 1 ]; then
		SSHPORT=$(whiptail --inputbox "Please enter port you are using for SSH" 8 43 3>&1 1>&2 2>&3)
		echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
	else
		echo -e "${YELLOW}Using SSH port:${SEA} $SSHPORT${NC}" && sleep 1
	fi
}

function ip_confirm() {
	echo -e "${YELLOW}Detecting IP address being used...${NC}" && sleep 1
	WANIP=$(wget http://ipecho.net/plain -O - -q)
	whiptail --yesno "Detected IP address is $WANIP is this correct?" 8 60
	if [ $? = 1 ]; then
		WANIP=$(whiptail --inputbox "        Enter IP address" 8 36 3>&1 1>&2 2>&3)
	fi
}

function install_packages() {
	echo -e "${YELLOW}Installing Packages...${NC}"
	if [[ $(lsb_release -d) = *Debian* ]] && [[ $(lsb_release -d) = *9* ]]; then
		sudo apt-get install dirmngr apt-transport-https -y
	fi
	sudo apt-get install software-properties-common -y
	sudo apt-get update -y
	sudo apt-get upgrade -y
	sudo apt-get install nano htop pwgen ufw figlet tmux -y
	sudo apt-get install build-essential libtool pkg-config -y
	sudo apt-get install libc6-dev m4 g++-multilib -y
	sudo apt-get install autoconf ncurses-dev unzip git python python-zmq -y
	sudo apt-get install wget curl bsdmainutils automake fail2ban -y
	sudo apt-get remove sysbench -y
	echo -e "${YELLOW}Packages complete...${NC}"
}

function create_conf() {
	echo -e "${YELLOW}Creating Conf File...${NC}"
	if [ -f ~/$CONFIG_DIR/$CONFIG_FILE ]; then
		echo -e "${CYAN}Existing conf file found backing up to $COIN_NAME.old ...${NC}"
		mv ~/$CONFIG_DIR/$CONFIG_FILE ~/$CONFIG_DIR/$COIN_NAME.old;
	fi
	RPCUSER=$(pwgen -1 8 -n)
	PASSWORD=$(pwgen -1 20 -n)
	zelnodeprivkey=$(whiptail --title "ZELNODE PRIVKEY" --inputbox "Enter your Zelnode Privkey generated by your Zelcore/Zelmate wallet" 8 72 3>&1 1>&2 2>&3)
	zelnodeoutpoint=$(whiptail --title "ZELNODE OUTPOINT" --inputbox "Enter your Zelnode collateral txid" 8 60 3>&1 1>&2 2>&3)
	zelnodeindex=$(whiptail --title "ZELNODE PRIVKEY" --inputbox "Enter your Zelnode collateral output index usually a 0/1" 8 60 3>&1 1>&2 2>&3)
	if [ "x$PASSWORD" = "x" ]; then
		PASSWORD=${WANIP}-$(date +%s)
	fi
		mkdir ~/$CONFIG_DIR > /dev/null 2>&1
		touch ~/$CONFIG_DIR/$CONFIG_FILE
		echo "rpcuser=$RPCUSER" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "rpcpassword=$PASSWORD" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "rpcallowip=127.0.0.1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "rpcport=$RPCPORT" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "port=$PORT" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "zelnode=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo zelnodeprivkey=$zelnodeprivkey >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo zelnodeoutpoint=$zelnodeoutpoint >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo zelnodeindex=$zelnodeindex >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "testnet=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "server=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "daemon=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "txindex=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "listen=1" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "externalip=$WANIP" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "bind=$WANIP" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "addnode=206.189.77.60" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "addnode=24.190.67.229" >> ~/$CONFIG_DIR/$CONFIG_FILE
		echo "maxconnections=256" >> ~/$CONFIG_DIR/$CONFIG_FILE
		sleep 2
}

function install_zel() {
	echo -e "${YELOW}Downloading binaries...${NC}"
	git clone https://github.com/zelcash/zelcash.git && cd zelcash
	git checkout v4.0.0 && ./zcutil/build.sh -j$(nproc)
	cd src && wget https://zelcore.io/kamata/benchmark.tar.gz
	tar -xvzf benchmark.tar.gz
	rm -rf benchmark.tar.gz && cd
}

function zk_params() {
	echo -e "${YELLOW}Installing zkSNARK params...${NC}"
	sudo chmod +x ~/$COIN_NAME/zcutil/fetch-params.sh && ~/$COIN_NAME/zcutil/fetch-params.sh
}

function update_script() {
	echo -e "${YELLOW}Downloading update script for easy updating...${NC}"
	wget $UPDATE_SCRIPT
	sudo chmod +x $UPDATE_FILE
}

function basic_security() {
	echo -e "${YELLOW}Configuring firewall and enabling fail2ban...${NC}"
	sudo ufw allow $SSHPORT/tcp
	sudo ufw allow $PORT/tcp
	sudo ufw logging on
	sudo ufw default deny incoming
	sudo ufw limit OpenSSH
	echo "y" | sudo ufw enable > /dev/null 2>&1
	sudo systemctl enable fail2ban > /dev/null 2>&1
	sudo systemctl start fail2ban > /dev/null 2>&1
}

function start_daemon() {
	NUM='105'
	MSG1='Starting daemon & syncing with chain please be patient this will take about 2 min...'
	MSG2=''
	cd zelcash && $COIN_DAEMON > /dev/null 2>&1
	if [ $? = 0 ]; then
		echo && spinning_timer
		NUM='10'
		MSG1='Getting info...'
		MSG2="${CHECK_MARK}"
		echo && spinning_timer
		echo
		$COIN_CLI getinfo
		sleep 5
	else
		echo -e "${RED}Something is not right the daemon did not start. Will exit out so try and run the script again.${NC}"
		exit
	fi
}
	
function status_loop() {
	while true
	do
		clear
		echo -e "${YELLOW}======================================================================================"
		echo -e "${GREEN} ZELNODE SYNC STATUS"
		echo -e " THIS SCREEN REFRESHES EVERY 15 SECONDS"
		echo -e " CHECK BLOCK HEIGHT ON TESTNET POOL AT https://test.zellabs.net/coins/testnet"
		echo -e " DO NOT START THE ZELNODE UNTIL THE ZELNODE IS FULLY SYNCED TO CHAIN"
		echo -e "${YELLOW}======================================================================================${NC}"
		echo
		$COIN_CLI getinfo
		sudo chown -R $USERNAME:$USERNAME /home/$USERNAME
		NUM='15'
		MSG1="${CYAN}Refreshes every 15 seconds while syncing to chain. [CTRL+C] to stop the loop.${NC}"
		MSG2="\e[2K\r"
		spinning_timer
	done
}

function check() {
	echo && echo && echo
	echo -e "${YELLOW}Running through some checks...${NC}"
	if pgrep zelcashd > /dev/null; then
		echo -e "${CHECK_MARK} ${CYAN}${COIN_NAME^} daemon is installed and running${NC}" && sleep 1
	else
		echo -e "${X_MARK} ${CYAN}${COIN_NAME^} daemon is not running${NC}" && sleep 1
	fi
	if [ -d "/home/$USERNAME/.zcash-params" ]; then
		echo -e "${CHECK_MARK} ${CYAN}zkSNARK params installed${NC}" && sleep 1
	else
		echo -e "${X_MARK} ${CYAN}zkSNARK params not installed${NC}" && sleep 1
	fi
	if [ -f "/home/$USERNAME/$UPDATE_FILE" ]; then
		echo -e "${CHECK_MARK} ${CYAN}Update script downloaded${NC}" && sleep 3
	else
		echo -e "${X_MARK} ${CYAN}Update script not installed${NC}" && sleep 3
	fi
	echo && echo && echo
}

function display_banner() {
		echo -e "${BLUE}"
		figlet -t -k "KAMATA    TESTNET"
		echo -e "${NC}"
		echo -e "${YELLOW}================================================================================================================================"
		echo -e " PLEASE COMPLETE THE ZELNODE SETUP IN THE KAMATA TESTNET FOLDER${NC}"
		echo -e "${CYAN} COURTESY OF DK808${NC}"
		echo
		echo -e "${YELLOW}   Commands to manage ${COIN_NAME}. Note that you have to be in the zelcash directory when entering commands.${NC}"
		echo -e "${PIN} ${CYAN}TO START: ${SEA}${COIN_DAEMON}${NC}"
		echo -e "${PIN} ${CYAN}TO STOP : ${SEA}${COIN_CLI} stop${NC}"
		echo -e "${PIN} ${CYAN}RPC LIST: ${SEA}${COIN_CLI} help${NC}"
		echo
		echo -e "${PIN} ${YELLOW}To update binaries wait for announcement that update is ready then enter:${NC} ${SEA}./${UPDATE_FILE}${NC}"
		echo -e "${YELLOW}================================================================================================================================${NC}"
		read -n1 -r -p "Press any key to continue..." key
		status_loop
}

#
#end of functions

#run functions
	wipe_clean
	ssh_port
	ip_confirm
	install_packages
	create_conf
	install_zel
	zk_params
	update_script
	basic_security
	start_daemon
	check
	display_banner
  
