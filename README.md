# hap_assistant

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## IDE安装命令
```
18:15:20.264: Build task in 12 s 179 ms
18:15:20.266: Launching com.dossen.hap
18:15:20.268: $ hdc shell aa force-stop com.dossen.hap
18:15:20.601: $ hdc shell mkdir data/local/tmp/38de51c6ea9d40eb854db91b6e6a2b6e
18:15:22.614: $ hdc file send /Users/zou/Documents/dev/dossen/dossen-app-harmony/main/build/debug/outputs/default/main-default-signed.hap "data/local/tmp/38de51c6ea9d40eb854db91b6e6a2b6e" in 2 s 13 ms
18:15:24.141: $ hdc shell bm install -p data/local/tmp/38de51c6ea9d40eb854db91b6e6a2b6e  in 1 s 524 ms
18:15:24.230: $ hdc shell rm -rf data/local/tmp/38de51c6ea9d40eb854db91b6e6a2b6e
18:15:24.527: $ hdc shell aa start -a MainAbility -b com.dossen.hap in 151 ms
18:15:24.528: com.dossen.hap successfully launched within 4 s 262 ms
```

```
// 关闭应用
hdc shell aa force-stop com.dossen.hap
// 创建临时目录
hdc shell mkdir data/local/tmp/随机文件名
// 发送 hap 文件到临时目录
hdc file send path to hap data/local/tmp/随机文件名
// 安装 hap 文件
hdc shell bm install -p data/local/tmp/随机文件名
// 删除临时目录
hdc shell rm -rf data/local/tmp/随机文件名
// 启动应用
hdc shell aa start -a MainAbility -b com.dossen.hap
```

 ```
 // 设备列表
hdc list targets



 ```