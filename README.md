# ST Terminal Manager

一键安装命令：

```bash
curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/bootstrap.sh | bash
```

现在安装程序会尽量模仿那种“先检测下载环境，再继续安装”的思路：

1. 检查 `curl` 是否正常
2. 如果 `curl` 不正常，就尝试修复 `curl/openssl/libngtcp2`
3. 如果 `curl` 还是不正常，就尝试改用 `wget`
4. 修不好再明确报错，提示重装最新版 `Termux`
5. 安装前会先输出中文诊断结果，告诉用户是 `curl` 坏了、镜像源没配，还是下载工具都不可用

## 菜单

1. 启动酒馆
2. 版本选择
3. 更新酒馆
4. 更新脚本
5. 查看日志
6. 修改端口
0. 退出

## 版本保留

- 酒馆版本最多保留 3 个
- 脚本版本最多保留 3 个

## 日志

查看日志时会显示最近的酒馆日志内容。

看完后按任意键返回菜单。

QQ群号：1097394254
