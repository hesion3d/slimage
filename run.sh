#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

readonly SLIMAGE_NAME=golang
readonly DOCKER_VERSION_SUPPORT=12
readonly OUTPUT_DIR=/tmp/slimage

slimage::msg::err() {
    >&2 echo -e "\033[0;31m$1\033[0m"
    exit 1
}

slimage::msg::warn() {
    echo -e "\033[0;33m$1\033[0m"
}

slimage::common::substr() {
    if [[ "${1/${2}//}" == "$1" ]]; then
        false
    else
        true
    fi
}

slimage::image::build() {
    echo Building...
    docker build --rm -t $DOCKER_IMAGE_NAME $OUTPUT_DIR/out
}

slimage::image::run() {
    docker run --privileged --rm $1 $SLIMAGE_NAME bash -c 'source /dockerize/dockerize.sh'
}

slimage::run::usage() {
    echo "Usage: $(basename $0) [-f file|-l level|-n name|-v mounted files or dirs|-h]"
    exit
}

slimage::run::help() {
    echo "This script is used to run dockerize image and build go source automatically."
    echo "-h Show this help."
    echo "-f file The config file used for docker running"
    echo "-l level There are 4 levels to build, [min, basic, extra, net]."
    echo "   min: we only have the res file which defined in config file."
    echo "   basic: we also have some basic filetools: ls, cat, echo, grep."
    echo "   extra: extends basic set with some useful tools: bash, sh, dash, pwd, mkdir, chmod, chown, rm, sed, ln, cp, mv."
    echo "   net: extends extra set with net tools: curl, ping, ss, ip."
    echo "   if not set, will use basic, if you want more other tools, you should add in config file with RES_FILES"
    echo "-n name Docker image name which will build out. If not set, will be the name of config file."
    echo "-v extra mounted files or dirs, used in copy dockerized files. format: -v /home/$USER/Docuemtns:/root/doc -v /usr/local/bin"
    slimage::msg::warn "When using in MINGW, our script and GOPATH should only in current user directory, which restricted by docker."
    exit
}

slimage::run::checkenv() {
    if [[ ! -e $GOPATH ]]; then
        slimage::msg::err "Please specify GOPATH at first."
    fi
    local -r DOCKER_VERSION=$(docker version |grep -A1 "Client:"|awk 'END{print $2}'|awk -F '.' '{print $2}')
    if [[ (($DOCKER_VERSION < $DOCKER_VERSION_SUPPORT)) ]]; then
        slimage::msg::err "Sorry, your docker version is not supported, please update at first."
    fi
}

slimage::run::prepare() {
    MINGW_EXTRA_SPLASH=
    if slimage::common::substr $(uname) "MINGW"; then
        MINGW_EXTRA_SPLASH="/"
    fi
}

slimage::run::parseopts() {
    if [[ -z $@ ]]; then
        slimage::run::usage
    fi
    DOCKER_CONFIG_FILE=
    DOCKER_IMAGE_LEVEL=
    DOCKER_IMAGE_NAME=
    DOCKER_MOUNTED_PATHS=
    while getopts "f:l:n:v:h" optname; do
        case "$optname" in
            "f") DOCKER_CONFIG_FILE=$OPTARG;;
            "l") DOCKER_IMAGE_LEVEL=$OPTARG;;
            "n") DOCKER_IMAGE_NAME=$OPTARG;;
            "v") DOCKER_MOUNTED_PATHS="$DOCKER_MOUNTED_PATHS $OPTARG";;
            "h") slimage::run::help;;
            "?") slimage::run::usage;;
        esac
    done
    if [[ -z $DOCKER_CONFIG_FILE ]]; then
        slimage::msg::err "Please specify DOCKER_CONFIG_FILE by -f."
    fi
    if [[ ! ${DOCKER_CONFIG_FILE:0:1} = "/" ]]; then
        DOCKER_CONFIG_FILE=$(pwd)/${DOCKER_CONFIG_FILE}
    fi
    if [[ -z $DOCKER_IMAGE_NAME ]]; then
        local FILE_NAME=$(basename $DOCKER_CONFIG_FILE)
        DOCKER_IMAGE_NAME=${FILE_NAME%.*}
    fi
    if [[ -z $DOCKER_IMAGE_LEVEL ]]; then
        DOCKER_IMAGE_LEVEL=basic
    fi
    MOUNTS_ARGS=
    if [[ -n $DOCKER_MOUNTED_PATHS ]]; then
        for mnt in ${DOCKER_MOUNTED_PATHS[@]}; do
            left=`eval echo ${mnt%%:*}`
            right=`eval echo ${mnt#*:}`
            MOUNTS_ARGS+=" -v $MINGW_EXTRA_SPLASH$left:$MINGW_EXTRA_SPLASH$right"
        done
    fi
}

slimage::main() {
    slimage::run::prepare
    slimage::run::parseopts $*
    slimage::run::checkenv
    local DOCKER_ARGS="-v $MINGW_EXTRA_SPLASH$GOPATH:$MINGW_EXTRA_SPLASH/gopath \
        -v $MINGW_EXTRA_SPLASH`pwd`:$MINGW_EXTRA_SPLASH/dockerize \
        -v $MINGW_EXTRA_SPLASH$OUTPUT_DIR/bin:$MINGW_EXTRA_SPLASH/gopath/bin \
        -v $MINGW_EXTRA_SPLASH$OUTPUT_DIR/out:$MINGW_EXTRA_SPLASH/tmp/out \
        $MOUNTS_ARGS \
        -e DOCKER_IMAGE_LEVEL=$DOCKER_IMAGE_LEVEL \
        --env-file=$DOCKER_CONFIG_FILE"
    slimage::image::run "$DOCKER_ARGS"
    slimage::image::build
}

slimage::main $*