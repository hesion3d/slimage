#slimage#

中文版请见 [README.zh_CN.md](https://github.com/hesion3d/slimage/blob/master/README.zh_CN.md)

Make slim docker image for golang applications.

##background##

[Docker](https://www.docker.com/) makes deployment of server-side applications much easier.

And to build docker image, the simplest way is to depends on some Golang image and ADD your code in. However, there are two main drawbacks in this approach.
- The size is usauly ~500MB;
- The source code is also delivered with the binary.

There are already lots of creative way to build a small docker image on the web. Slimage is a simple commandline tool inspired by [Nick Gauthier](https://blog.codeship.com/author/nickgauthier/)'s idea with slight modification. With slimage, you could build go application w/o Cgo support at ~25MB (include some basic linux commandline binaries for debugging).

slimage works in Bash. And we also provide a version port for windows commandline.

##usage##
linux/mingw or mac:
```
slimage$ ./run.sh -f demo-config.sh -l min -n hello-slimage
Prepare for building...
Building src...
Analyzing ELF files...
Building...
Sending build context to Docker daemon 8.127 MB
Step 1 : FROM scratch
 ---> 
Step 2 : COPY . /
 ---> Using cache
 ---> 8c143d09beb3
Step 3 : ENTRYPOINT /opt/bin/hello-slimage --server_ip=0.0.0.0
 ---> Using cache
 ---> 422adde5b9af
Successfully built 422adde5b9af

slimage$ docker run --rm -p 8080:80 hello-slimage
```

or in windows:
```
run.bat -f demo-config.sh -l min -n hello-slimage
```

##insides##

Instead of build docker image in docker, as described in most of the articles on the web, slimage build go source code from the image. Basically, we

 1. find out all the dependencies of the binaries to pack
 2. make the directory tree
 3. copy the tree to temporary dir with a DOCKERFILE
 4. exit from the docker container and build the image outside.

##reference##

1. Building Minimum Docker Containers for Go Applications. https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/
