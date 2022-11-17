#!/bin/sh

# 检查 go 是否安装
checkGoEnv() {
    # go是否安装
    if ! command -v go &>/dev/null; then
        echo "go not installed or available in the PATH" >&2
        echo "please check https://golang.google.cn" >&2
        exit 1
    fi

    # go proxy 是否设置  < 17 set GOPROXY=https 说明没有设置
    goProxy=$(go env | grep "GOPROXY")
    if [ ${#goProxy} -lt 17 ]; then
        echo "go proxy not set in the PATH" >&2
        echo "please set GOPROXY, https://goproxy.cn,direct || https://goproxy.io,direct" >&2
        exit 1
    fi

    echo "go env installed ..."
}

# 检查 go 相关工具包是否安装
checkGoLintEnv() {
    if ! command -v goimports &>/dev/null; then
        echo "goimports not installed or available in the PATH" >&2
        echo "install goimports ..." >&2
        go install golang.org/x/tools/cmd/goimports@latest
        checkGoLintEnv
        return
    fi

    echo "goimports installed ..."
}

installGoLint(){
    goVersion=$(go version |grep "1.19")
    if [ -z "$goVersion" ]; then
        # 没有 go 环境间接安装
        curl  http://10.1.0.60/ywb/tool/-/raw/master/gotool/golangci-lint.exe -o "$(go env GOBIN)/golangci-lint.exe"
    else
        # 有 go 环境直接安装
        go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.50.1
    fi

    if [ $? -ne 0 ]; then
        exit 1
    fi
}

# 检查 golangci-lint 是否安装
checkCiLintEnv() {
    if ! command -v golangci-lint &>/dev/null; then
        echo "golangci-lint not installed or available in the PATH" >&2
        echo "install golangci-lint ..." >&2
        installGoLint
    fi

    # 检查版本
    version=$(golangci-lint.exe --version | grep "1.50.1")
    if [ -z "$version" ]; then
        echo "golangci-lint version dont is 1.50.1 ..."
        installGoLint
    fi

    echo "golangci-lint installed ..."
}

# 初始化钩子配置
initHooks() {
    # 如果当前目录不存在 .githooks 目录，说明位置不对
    if [ ! -d ".githooks" ]; then
        echo "exec incorrect position"
        exit 1
    fi

    # 检查是否已经设置了
    exist=$(git config core.hooksPath)
    if [ -z $exist ]; then
        # 设置 hooks 默认位置
        git config core.hooksPath .githooks
        echo "init git hooks ..." >&2
    fi
}

main() {
    checkGoEnv
    checkGoLintEnv
    checkCiLintEnv
    initHooks
}

main
