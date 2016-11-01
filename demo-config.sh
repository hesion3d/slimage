TARGET_DIR=/opt/bin

# Note that we directly set this config to docker run --env-file, so here we do NOT support
# multiple lines for one variable. That means we must set each variable in one line WITHOUT '\'.

# docker build variables. if not defined, you should define PACKAGE_NAME.
# MAKE_CMD="go install hesion3d/greeting"

# this variable used for defining go build packages
# default build cmd: CGO_ENABLED=0 go install -a -installsuffix cgo -ldflags '-s' $PACKAGE_NAME
# if you use cgo, please define MAKE_CMD like above.
PACKAGE_NAME="hesion3d/greeting"

# before build, you can do some thing here.
PRE_MAKE=""

# resources that dockerized for running app. format is left:right, :right can be ignored if left is equal to right.
# each path must be absolute. and should be surrounded by ().
DOCKERIZED_FILES=(${GOPATH}/bin/greeting:${TARGET_DIR}/hello-slimage /usr/bin/dirname)

# entrypoint for Dockerfile. here variable ${TARGET_DIR} is the env when we building, but not running env.
# you can add prefix '\' to use a running env. ex: \$PATH
ENTRYPOINT="${TARGET_DIR}/hello-slimage --server_ip=0.0.0.0"
