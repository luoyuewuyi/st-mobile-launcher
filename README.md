# ST Terminal Manager

这是一个完全依赖终端的 `SillyTavern` 管理器。

它不再以 `APK` 为核心，而是直接在 `Termux` 里提供一个数字菜单界面，让你通过输入数字完成这些事：

1. 查看官方全部版本
2. 安装指定版本
3. 安装最新版本
4. 切换已安装版本
5. 启动酒馆
6. 停止酒馆
7. 刷新当前版本依赖
8. 查看日志
9. 修改端口

## 适合什么人

适合想要：

- 完全依赖 `Termux`
- 不想装单独 `APK`
- 用数字菜单管理 `SillyTavern`
- 想下载和切换不同官方版本

## 一键安装

在 `Termux` 里执行：

```bash
curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/bootstrap.sh | bash
```

安装完成后，如果命令还不能立刻识别，就重开一次 `Termux`。

然后运行：

```bash
st-terminal
```

## 使用方式

运行 `st-terminal` 后，你会看到一个数字菜单，大概是这样：

```text
1. First-time setup
2. Show official versions
3. Install a specific version
4. Install latest official version
5. List installed versions
6. Switch active version
7. Start SillyTavern
8. Stop SillyTavern
9. Refresh active version dependencies
10. Show latest log
11. Change server port
0. Exit
```

你只要输入数字就行。

## 推荐使用顺序

第一次建议这样操作：

1. 输入 `1`
   作用：安装基础依赖
2. 输入 `2`
   作用：查看官方版本列表
3. 输入 `3`
   作用：按版本号安装指定版本
4. 输入 `7`
   作用：启动酒馆

启动后，在浏览器打开：

```text
http://127.0.0.1:8000
```

如果你改过端口，就打开你设置的新端口。

## 版本管理说明

这个工具会从官方仓库实时抓取 `SillyTavern` 的 tag 列表，所以可以看到官方历史版本。

已实现的版本相关能力：

- 查看远端官方版本
- 安装指定 tag 版本
- 安装最新官方版本
- 切换当前激活版本

每个版本会单独放在自己的目录里，互不覆盖。

## 当前目录结构

安装后，主要内容会在这里：

```text
~/sillytavern-terminal/
```

里面大致包括：

- `versions/`
  - 每个安装好的 `SillyTavern` 版本
- `logs/`
  - 启动日志
- `state.env`
  - 当前激活版本和端口

## 当前限制

目前这个工具已经能完成“纯终端菜单管理 + 多版本安装切换”的主流程。

但我也实话告诉你两点：

1. “实时更新”目前指的是实时获取官方版本列表，以及可安装最新官方版本
2. 还没有做成自动后台轮询更新提醒

如果你要，我下一步可以继续把它补成：

- 启动时自动检查是否有更新
- 显示“当前版本和最新版本差距”
- 一键升级到最新版本

## 仓库地址

[https://github.com/luoyuewuyi/st-mobile-launcher](https://github.com/luoyuewuyi/st-mobile-launcher)
