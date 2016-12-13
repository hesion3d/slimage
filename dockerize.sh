#!/bin/bash

set -o errexit

readonly GOPATH=/gopath
readonly ELF_FILE_TXT=/tmp/elf$RANDOM
readonly OUTPUT_DIR=/tmp/out

slimage::dockerize::resetenv() {
	read -r -a DOCKERIZED_FILES <<< `echo "${DOCKERIZED_FILES}" |sed -e 's/^(//' -e 's/)$//'`
	read -r ENTRYPOINT <<< `echo "${ENTRYPOINT}" |sed -e 's/^"//' -e 's/"$//'`
}

slimage::dockerize::buildsource() {
	rm -rf $OUTPUT_DIR/*
	if [[ -n $PRE_MAKE ]]; then
		echo Prepare for building...
		eval `eval echo ${PRE_MAKE}`
	fi
	echo Building src...
	if [[ -n ${MAKE_CMD} && -n ${PACKAGE_NAME} ]]; then
		echo -e "\033[0;33mBoth MAKE_CMD and PACKAGE_NAME are defined, PACKAGE_NAME will be ignored.\033[0m"
	fi
	if [[ -z ${MAKE_CMD} ]]; then
		if [[ -z ${PACKAGE_NAME} ]]; then
			echo "No buildable Go source files in $GOPATH"
			exit 3
		else
			CGO_ENABLED=0 go install -a -installsuffix cgo -ldflags '-s' `eval echo ${PACKAGE_NAME}`
		fi
	else
		eval `eval echo ${MAKE_CMD}`
	fi
}

slimage::dockerize::dependency() {
	local ELFS=$(cat $ELF_FILE_TXT|sort -u)
	echo Analyzing ELF files...
	for elf in $ELFS; do
		/dockerize/get_deps.sh $elf /tmp/tmp.txt;
		for f in $(cat /tmp/tmp.txt); do
			mkdir -p $OUTPUT_DIR/$(dirname $f)
			cp -rn $f $OUTPUT_DIR$f
		done
	done
}

slimage::dockerize::addresources() {
	local EXTRA_RESFILES="/etc/group /etc/nsswitch.conf /etc/passwd /etc/ssl/certs/ca-certificates.crt /usr/share/zoneinfo"
	local -r BASIC_FILETOOLS=" /bin/ls /bin/cat /bin/echo /bin/grep"
	local -r EXTRA_FILETOOLS=" /bin/pwd /bin/bash /bin/sh /bin/dash /bin/cp /bin/mv /bin/mkdir /bin/chmod /bin/chown /bin/rm /bin/sed /bin/ln"
	local -r NET_FILETOOLS=" /bin/ss /bin/ip /usr/bin/curl"
	local ALL_FILETOOLS=
	if [[ "$DOCKER_IMAGE_LEVEL" = "min" ]]; then
		:
	elif [[ "$DOCKER_IMAGE_LEVEL" = "basic" ]]; then
		ALL_FILETOOLS=$BASIC_FILETOOLS
	elif [[ "$DOCKER_IMAGE_LEVEL" = "extra" ]]; then
		ALL_FILETOOLS=$BASIC_FILETOOLS
		ALL_FILETOOLS+=$EXTRA_FILETOOLS
	elif [[ "$DOCKER_IMAGE_LEVEL" = "net" ]]; then
		ALL_FILETOOLS=$BASIC_FILETOOLS
		ALL_FILETOOLS+=$EXTRA_FILETOOLS
		ALL_FILETOOLS+=$NET_FILETOOLS
	fi
	if [[ -n ${CMD} && ( "$DOCKER_IMAGE_LEVEL" = "min" || "$DOCKER_IMAGE_LEVEL" = "basic" ) ]]; then
		ALL_FILETOOLS+="/bin/bash"
	fi
	EXTRA_RESFILES+=" $ALL_FILETOOLS"
	if [[ -n $DOCKERIZED_FILES ]]; then
		for res in ${DOCKERIZED_FILES[@]}; do
			f=`eval echo ${res}`
			EXTRA_RESFILES+=" $f"
		done
	fi
	for res in ${EXTRA_RESFILES[@]}; do
		left=`eval echo ${res%%:*}`
		right=`eval echo ${res#*:}`
		if [[ ! ${left:0:1} = / ]]; then
			>&2 echo "Path for resource $left must be absolute."
		fi
		if [[ ! ${right:0:1} = / ]]; then
			>&2 echo "Path for resource $right must be absolute."
		fi
		if [[ ${right:${#right}-1:1} = / ]]; then
			right_dir=$right
		else
			right_dir=$(dirname $right)
		fi
		mkdir -p $OUTPUT_DIR$right_dir
		cp -rn $left $OUTPUT_DIR$right
		echo $left>>$ELF_FILE_TXT
	done
}

slimage::dockerize::processcmd() {
	CMD_ARG=""
	if [[ -n ${CMD} ]]; then
		CMD=`eval echo ${CMD}`
	fi
	if [[ -n ${ENTRYPOINT} ]]; then
		ENTRYPOINT=${ENTRYPOINT//,/ } #replace all , to space
		ENTRYPOINT=${ENTRYPOINT// /,} #then replace all space to ,
		ENTRYPOINT=${ENTRYPOINT//\\,/ } #if we have '\ ', revert
		ENTRYPOINT=`eval echo ${ENTRYPOINT}`
		CMD_ARG=\"${ENTRYPOINT//,/\",\"}\"
	fi
}

slimage::dockerize::writedocker() {
	echo "FROM scratch">>$OUTPUT_DIR/Dockerfile
	echo "COPY . /">>$OUTPUT_DIR/Dockerfile
	echo "WORKDIR $DOCKER_WORKDIR">>$OUTPUT_DIR/Dockerfile
	if [[ -n ${CMD} ]]; then
		echo "CMD ${CMD}">>$OUTPUT_DIR/Dockerfile
	fi
	if [[ -n ${ENTRYPOINT} ]]; then
		echo "ENTRYPOINT [$CMD_ARG]">>$OUTPUT_DIR/Dockerfile
	fi
}

slimage::dockerize::cleanup() {
	if [[ -n ${CLEAN_UP} ]]; then
		echo Cleanup...
		eval `eval echo ${CLEAN_UP}`
	fi
	rm -f /tmp/tmp.txt
	chmod -R a+w $OUTPUT_DIR
}

slimage::dockerize::build() {
	slimage::dockerize::resetenv
	trap slimage::dockerize::cleanup EXIT INT TERM QUIT
	slimage::dockerize::buildsource
	slimage::dockerize::addresources
	slimage::dockerize::dependency
	slimage::dockerize::processcmd
	slimage::dockerize::writedocker
	trap '' EXIT INT TERM
	slimage::dockerize::cleanup
}
slimage::dockerize::build
