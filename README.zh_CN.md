#slimage#

为 Go 语言应用创建最小化的 Docker 镜像。

##背景##

[Docker](https://www.docker.com/)已经使得发布应用到服务器的流程简单了很多。

在我们创建 Docker 镜像的过程中，最直接的方法是从包含 Go 的镜像开始，把源码 ADD 到里面，编译，生成镜像，但是这个过程中有两个问题：
- 镜像通常会比较大，~500MB;
- 连同源码也一起打包到镜像内部。

网上有很多文章提到的了如何为 Go 应用建立一个非常紧凑的 Docker 镜像。受到 [Nick Gauthier](https://blog.codeship.com/author/nickgauthier/) 的想法的启发，我们开发了 slimage，一个命令行工具，使得这个过程更加简单易用。使用 slimage，我们支持编译带或不带 Cgo 支持的 Go 应用，最终的镜像大小为 ~25MB (包含一些命令行调试工具)。

slimage 是一个 Bash 应用。我们同时还提供一个 windows cmd 的版本。

##用法##

##大致原理##

网上很多文章提到在 Docker 容器中使用 Docker 生成镜像，我们没有这么做。slimage 在 Docker 容器中编译 Go 源码。然后：

 1. 找到要打包的可执行文件 (ELF 格式) 的依赖关系
 2. 整理好完整的 linux 路径，将所有需要的文件，包括被依赖的库放到对应目录
 3. 把该目录从容器中拷贝出来
 4. 在容器外把刚刚整理好的文件树生成 Docker 镜像

##参考##

1. Building Minimum Docker Containers for Go Applications. https://blog.codeship.com/building-minimal-docker-containers-for-go-applications/
