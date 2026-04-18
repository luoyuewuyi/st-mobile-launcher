# ST Terminal Manager

现在菜单只保留这几个选项：

1. 启动酒馆
2. 版本选择
3. 更新酒馆
4. 更新脚本
5. 查看日志
0. 退出

## 安装

正常环境直接执行：

```bash
curl -O https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/install-manager.sh && bash install-manager.sh
```

## 脚本更新说明

现在“更新脚本”不再只是覆盖当前文件。

而是：

1. 从仓库读取脚本版本号
2. 下载到新的脚本版本目录
3. 更新当前脚本软链接
4. 最多保留最近 3 个脚本版本

这样脚本更新能真正切到最新版本，同时保留最近 3 个旧版本，方便回退。

## 酒馆更新说明

“更新酒馆”会：

1. 获取官方最新版本
2. 下载并切换到最新版本
3. 最多保留最近 3 个酒馆版本

这样既能更新，也能保留回退空间。

## 日志

“查看日志”会显示最近一个日志文件内容。

看完后随便按一个键就能退出。

## 仓库地址

[https://github.com/luoyuewuyi/st-mobile-launcher](https://github.com/luoyuewuyi/st-mobile-launcher)

QQ群号：1097394254
