# T9_skin_Short_press_ios

元书输入法（Hamster3）的 T9 九键键盘皮肤，包含浅色 / 深色两套主题，适配 iPhone 竖屏与横屏。

![demo](demo.png)

## 特性

### T9 拼音键盘

- **竖屏 5 列布局**：`123 / #+= / 中英`、数字列 `1 4 7 0`、双列数字区 + 空格、`退格 / 重输 / 回车`
  - `中英`、`回车` 各占两行合并单元格
  - `空格` 占两列合并单元格
- **顶部横向拼音音节候选栏**：输入时显示 `mi ni m n o …` 等音节，点击可筛选候选词
- **纵向候选栏保留音节筛选**：展开候选栏时，右侧一列显示纵向拼音音节列表，可在展开态继续点选音节
- **回车/确定键**
  - 常态灰色，文字随输入框类型动态显示（换行 / 发送 / 前往 / 搜索 / 完成 …）
  - 浅色模式下，首次拼音输入后锁定为蓝色并保持提醒
  - 深色模式不变色，仅保留动态文字
- **`1` 键**
  - 常态：点击输入 `，`，下滑输入 `？`，上滑输入 `1`
  - 打字中（有预编辑）：切换为「分隔」，用于 T9 分词
- **`0` 键**采用与空格键一致的背景色，风格统一

### 26 键字母键盘

- 底部功能键：`En/中`（切回 T9 拼音键盘）、`#+=`（切符号键盘）、`空格`、`.`（英文句点）、`回车`
- 已移除 26 键上的「切数字键盘」入口
- `J` 上滑输入 `'`（单引号）
- `X` 上滑输入 `~`

## 安装

1. 在 [Releases](../../releases) 下载最新的 `T9_skin_Short_press_ios.cskin`
2. 把文件传到 iOS 设备，用「元书输入法」打开即可导入
3. 在元书「键盘皮肤」中选择本皮肤
4. 输入方案选择「中文九键」

## 环境要求

- 元书输入法 **1.6.0** 及以上
- 需要 RIME「中文九键」方案（雾凇拼音自带的「中文九键」即可）
- `t9HorizontalSymbols`（横向拼音音节列表）为实验功能，需 TestFlight ≥ 350 的版本

## 目录结构

```
T9_skin_Short_press_ios/
├── config.yaml          # 键盘类型映射
├── demo.png             # 应用内预览图
├── README.md
├── light/               # 浅色主题（6 个键盘 yaml）
├── dark/                # 深色主题（6 个键盘 yaml）
├── jsonnet/             # 皮肤源码（生成 light/dark 的 yaml）
└── skills/              # 皮肤制作技能文档（不参与运行）
```

`config.yaml` 声明了 `pinyin` / `alphabetic` / `numeric` 三类键盘的竖屏与横屏文件。

## 二次开发

皮肤的 `light/`、`dark/` 目录由 `jsonnet/` 源码生成：

```bash
# 需要 jsonnet（或 Python 的 _jsonnet）
jsonnet -m . jsonnet/main.jsonnet
```

修改布局或样式后，重新生成 `light/`、`dark/` 与 `config.yaml` 即可。

主要源码文件：

- `jsonnet/main.jsonnet`：编译入口
- `jsonnet/Components/PinyinPortrait.libsonnet` / `PinyinLandscape.libsonnet`：T9 拼音键盘
- `jsonnet/Components/AlphabeticKeyboard.libsonnet`：26 键字母键盘
- `jsonnet/Components/Toolbar.libsonnet`：候选栏、音节栏、纵向候选列
- `jsonnet/Constants/`：颜色、字体、按键定义

## 已知限制

- 展开纵向候选栏时，右侧音节列表在**首次展开**时可能为空，需要先在横向候选栏点一次音节后才刷新。这是应用侧音节数据的刷新时机问题，非皮肤配置错误。
- `t9HorizontalSymbols` 放在 `verticalCandidatesLayout` 中不会刷新数据（会显示空白），因此纵向布局改用 `t9Symbols` 承载音节列表。
- 回车键的蓝色锁定在键盘视图重建后会重置（收起再呼出键盘、切换应用后回到灰色）。
- 回车键蓝色仅在浅色模式生效，深色模式不变色。

## 发布

仓库内置 `.github/workflows/release.yml`：

- 在 Actions 页面手动运行 `Build T9_skin_Short_press_ios skin`
- 自动打包 `.cskin`、生成版本号（`v1.x`）并创建 GitHub Release

## License

仅供个人学习与使用；基于元书输入法皮肤格式制作。
