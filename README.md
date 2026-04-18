# ST Mobile Launcher

这个项目的目的很简单：

- 让手机上运行官方 `SillyTavern`
- 尽量把操作压缩到傻瓜式

## APK 到底是干嘛的

这个 `APK` 不是酒馆本体。

它是一个“启动器”：

1. 帮你在手机上点一下就启动 `Termux` 里的酒馆服务
2. 等酒馆启动好
3. 直接把酒馆页面打开给你用

也就是说：

- `Termux` 负责真的运行官方 `SillyTavern`
- `APK` 负责把“打开 Termux、输入命令、等服务起来、再打开页面”这些动作尽量简化

所以这两个东西要一起用：

1. `Termux`
2. `st-mobile-launcher-debug.apk`

## 最终怎么用

按正常使用理解，流程应该是这样的：

### 第一次安装

1. 手机安装 `Termux`
2. 手机安装 `APK`
3. 打开 `Termux`
4. 在 `Termux` 里执行这一条命令：

```bash
curl -fsSL https://raw.githubusercontent.com/luoyuewuyi/st-mobile-launcher/master/termux/bootstrap.sh | bash
```

5. 等它自动装完
6. 关闭一次 `Termux`，再重新打开一次
7. 打开 `APK`
8. 第一次如果弹权限，允许它调用 `Termux`

做完这一次后，后面就简单很多了。

### 以后日常使用

以后基本就是：

1. 点开 `APK`
2. 它自动尝试启动酒馆
3. 自动进入酒馆页面

这就是这个启动器存在的意义。

## 如果你问“那我平时到底点哪个”

按我现在做的方案，你平时主要点：

- `APK`

只有下面几种情况，你才需要进 `Termux`：

- 第一次安装
- 更新酒馆
- 出问题要看日志

## 更新怎么做

如果以后要更新酒馆，在 `Termux` 里运行：

```bash
bash ~/sillytavern-mobile/update-st.sh
```

## 现在给你准备好的文件

你当前可以直接用的 APK 在这里：

[`st-mobile-launcher-debug.apk`](E:\自己瞎搞\st-mobile-launcher\release\st-mobile-launcher-debug.apk)

原始构建输出还在这里：

[`app-debug.apk`](E:\自己瞎搞\st-mobile-launcher\android\app\build\outputs\apk\debug\app-debug.apk)

## 项目地址

GitHub 仓库：

[https://github.com/luoyuewuyi/st-mobile-launcher](https://github.com/luoyuewuyi/st-mobile-launcher)

## 当前方案的真实情况

这套方案已经能做到：

- 官方 `SillyTavern` 跑在手机本地
- 有独立 APK 负责一键启动
- 首次配置后，后续使用尽量接近一键进入

但它不是“完全不需要 Termux”。

因为真正的酒馆服务还是在 `Termux` 里跑的。  
我已经按“最省事、最接近原版功能、最容易成功”这个方向做到了当前最稳的方案。
