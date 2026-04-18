# ST Terminal Manager

这是一个专门给 `Termux` 用的 `SillyTavern` 终端管理器。

特点：

- 全中文菜单
- 数字选择操作
- 自动拉取官方版本列表
- 支持安装指定版本
- 支持安装最新版本
- 支持切换版本
- 启动后带基础保活
- 打开 `Termux` 自动进入界面

## 一键安装

如果你的 `Termux` 是干净、正常的新环境，直接运行：

```bash
curl -O https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/install-manager.sh && bash install-manager.sh
```

## 如果之前报过 curl / openssl / libngtcp2 错误

那说明不是本项目本身的问题，而是你的 `Termux` 底层库已经乱了。

这种情况先修环境，再装管理器：

```bash
curl -O https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/fix-termux.sh && bash fix-termux.sh
```

修完后再执行安装命令：

```bash
curl -O https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/install-manager.sh && bash install-manager.sh
```

## 安装后的体验

安装完成后会自动：

- 进入终端菜单
- 把自动启动写入 `~/.bashrc`

所以以后你重新打开 `Termux`，会直接进这个管理界面。

## 终端菜单功能

当前支持：

1. 首次环境准备
2. 查看官方版本列表
3. 安装指定版本
4. 安装最新官方版本
5. 查看已安装版本
6. 切换当前版本
7. 启动 `SillyTavern`
8. 停止 `SillyTavern`
9. 刷新当前版本依赖
10. 查看最新日志
11. 修改服务端口

## 保活说明

启动酒馆时会：

1. 使用守护循环拉起进程
2. 如果系统支持，就调用 `termux-wake-lock`

这会比单次后台启动稳很多。

但如果安卓系统本身强杀 `Termux`，任何普通终端脚本都无法承诺绝对 100% 不死。

## 仓库地址

[https://github.com/luoyuewuyi/st-mobile-launcher](https://github.com/luoyuewuyi/st-mobile-launcher)

QQ群号：1097394254
