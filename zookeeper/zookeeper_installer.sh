#!/bin/bash

# touch adduser.sh && chmod +x adduser.sh && vi adduser.sh

DATE=`date "+%Y.%m.%d-%H.%M.%S"`
LOGFILE=zookeeper_installer.$DATE.log
OS=`gawk -F= '/^NAME/{print $2}' /etc/os-release  | tr -d '"'`

# basic configuration
ZK_USERGROUP=zookeeper
ZK_UID=1000
PROJECT_USERGROUP=miflash
PROJECT_UID=5099
MYID=1

# spell out coloring skema
RED='\033[1;31m'
BLUE='\033[0;34m'
LCYAN='\033[1;36m'
LWHITE='\033[1;37m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 2>&1 | tee $LOGFILE
   exit 1
fi

prompt_confirm() {
  while true; do
    read -r  -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf "\033[31m %s \n\033[0m" "Invalid input"
    esac
  done
}

show_curr_config() {

    echo ""
    echo "########################################################"
    echo "#   Zookeeper Installer. Current Cofing:"
    echo "#"
    echo -e "#     ${LWHITE}1${NC}. ZK_USERGROUP         = ${LCYAN}${ZK_USERGROUP}${NC}" 
    echo -e "#     ${LWHITE}2${NC}. ZK_UID               = ${LCYAN}${ZK_UID}${NC}" 
    echo -e "#     ${LWHITE}3${NC}. PROJECT_USERGROUP    = ${LCYAN}${PROJECT_USERGROUP}${NC}" 
    echo -e "#     ${LWHITE}4${NC}. PROJECT_UID          = ${LCYAN}${PROJECT_UID}${NC}" 
    echo -e "#     ${LWHITE}5${NC}. Zookeeper MYID       = ${LCYAN}${PROJECT_UID}${NC}" 
    echo "#"
    echo -e "#     ${LWHITE}Y${NC}. Agree. Proceed"
    echo "#"
    echo -e "#     OS Detected: ${RED}${OS}${NC}"
    echo -e "#     Zookeeper Location: ${RED}/opt/${PROJECT_USERGROUP}/zookeeper${NC}"
    echo -e "#     Installer Logfile: ${RED}${LOGFILE}${NC}"
    echo "#"
    echo "#######################################################"
    echo ""
}

prompt_curr_config() {

    read -r  -p "${1:-Next Step (1-4,Y)?}: " REPLY

    case $REPLY in
      [1]) read -r  -p "Enter username/groupname for zookeeper: " ZK_USERGROUP; return 0 ;;
      [2]) read -r  -p "Enter uid/gid (numbers) for zookeeper: " ZK_UID; return 0 ;;
      [3]) read -r  -p "Enter project username/groupname: " PROJECT_USERGROUP; return 0 ;;
      [4]) read -r  -p "Enter project uid/gid: " PROJECT_UID; return 0 ;;
      [5]) read -r  -p "Enter zookeeper myid: " PROJECT_UID; return 0 ;;
      [yY]) echo -e "\n${RED}Ok proceed${NC}"; return 1 ;;
      *) echo -e "\n${RED}Unknown response${NC}" ; return 0 ;;
    esac

}

show_curr_config
while prompt_curr_config; do
    show_curr_config
done