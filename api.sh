#!/bin/bash

# ############################################################################ #
#                         G L O B A L   V A R I A B L E S                      #
# ############################################################################ #
YELLOW='\033[1;33m'
RED='\033[1;31m'
NC='\033[0m' # No Color

NAME="$0"
VERSION="1.0"
COPYRIGHT="urbanSoft 2022"

ACCOUNT_JSON_FILE=".account.json"
TOKEN_JSON_FILE=".token.json"
SETTING_JSON_FILE=".setting.json"

# ############################################################################ #
#                              F U N C T I O N S                               #
# ############################################################################ #

# ############################################################################ #
# printHelp()
#   Print out a short usage information for this script.
#   out A short help message describing the use of this script.
# ############################################################################ #
function printHelp()
{
  echo "Usage: $NAME [-a <param>|-h|-V]"
  echo "  -a|--action  <param> Do an action with a parameter."
  echo "  -h|--help    Print this help."
  echo "  -V|--version Print version info."
}

# ############################################################################ #
# printVersion()
#   Print out a short version information about this script.
#   out A version information message.
# ############################################################################ #
function printVersion()
{
  echo "$NAME Version $VERSION"
  echo "Copyright $COPYRIGHT"
}

# ############################################################################ #
# warn()
#   A wrapper around echo to print out formated text.
#   param [$1, $2, ...] A message to print on stdout.
#   out   <string>      The same message as param but formated with a color.
# ############################################################################ #
function warn()
{
  echo -en "${YELLOW}"
  echo -en $@
  echo -e  "${NC}"
}

# ############################################################################ #
# error()
#   A wrapper around echo to print out formated text.
#   param [$1, $2, ...] A message to print on stdout.
#   out   <string>      The same message as param but formated with a color.
# ############################################################################ #
function error()
{
  echo -en "${RED}"
  echo -en $@
  echo -e  "${NC}"
}

# ############################################################################ #
#                                  M A I N                                     #
# ############################################################################ #


# check if account data is available to use the api
if [[ ! -f $ACCOUNT_JSON_FILE ]]; then
    error "File '$ACCOUNT_JSON_FILE' is missing."
    exit 1
fi

# if token is already present load it
if [[ -f $TOKEN_JSON_FILE ]]; then
    access_token=$(cat .token.json | jq -r '.access_token')
fi

# Check if getopt is available
getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I'm sorry, `getopt --test` failed in this environment."
    exit 1
fi

OPTIONS=dg:hlmrV
LONGOPTIONS=discover,get:,help,login,me,refresh,version
#echo -en "${RED}"
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@" 2> >(sed $'s,.*,\e[1;31m&\e[m,'>&2))
if [[ $? -ne 0 ]]; then

  printHelp
  exit 2
fi

# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -d|--discover)
            source ./discover.sh
            exit 0
            ;;
        -g|--get)
            source ./get.sh $2
            #shift 2
            exit 0
            ;;
        -h|--help)
            printHelp
            exit 0
            ;;
        -l|--login)
            source ./login.sh
            if [[ ! -f $SETTING_JSON_FILE ]]; then
              source ./discover.sh
            fi
            exit 0
            ;;
        -m|--me)
            source ./me.sh
            exit 0
            ;;
        -r|--refresh)
            source ./refresh.sh
            exit 0
            ;;
        -V|--version)
            printVersion
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done