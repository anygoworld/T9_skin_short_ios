local fonts = import '../Constants/Fonts.libsonnet';
local params = import '../Constants/Keyboard.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local preedit = import 'Preedit.libsonnet';
local toolbar = import 'Toolbar.libsonnet';
local utils = import 'Utils.libsonnet';

local hintStyle = {
  hintStyle: {
    size: { width: 50, height: 50 },
  },
};

local topBadgeLabelUpParams = {
  center: {
    y: 0.2,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

local leftBadgeLabelUpParams = {
  center: {
    x: 0.25,
    y: 0.2,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

local rightBadgeLabelUpParams = {
  center: {
    x: 0.75,
    y: 0.2,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

local createSwipeUpHintStyle(isDark, params={}) = {
  [params.name + 'SwipeUpHintForegroundStyle']:
    basicStyle.newAlphabeticButtonHintStyle(isDark) + basicStyle.getKeyboardActionText(params.params),
};

local createSwipeDownHintStyle(isDark, params={}) = {
  [params.name + 'SwipeDownHintForegroundStyle']:
    basicStyle.newAlphabeticButtonHintStyle(isDark) + basicStyle.getKeyboardActionText(params.params),
};

local createButtonForegroundStyle(isDark, params={}) = {
  [params.name + 'ForegroundStyle']:
    basicStyle.newAlphabeticButtonForegroundStyle(isDark, params.params),
};

local createTopBadgeForegroundStyle(isDark, params={}) = {
  [params.name + 'BadgeForegroundStyle']:
    basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, params.params + topBadgeLabelUpParams),
};

local createLeftTopBadgeForegroundStyle(isDark, params={}) = {
  [params.name + 'BadgeForegroundStyle']:
    basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, params.params + leftBadgeLabelUpParams),
};

local createRightTopBadgeForegroundStyle(isDark, params={}) = {
  [params.name + 'BadgeForegroundStyle']:
    basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, params.params + rightBadgeLabelUpParams),
};

// ---- 上滑角标 / 下滑提示（移植自 T9_i2Nine 的 26 键）----
// 角标文字直接取自按键定义里的 swipeUpAction / swipeDownAction；
// 快捷指令（剪切、复制…）没有可显示的字符，用 swipeUpText / swipeDownText 指定文字，
// 也可用 swipeDownSystemImageName 显示 SF Symbols 图标。
local bottomBadgeLabelDownParams = {
  center: {
    y: 0.8,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

// 动作对应的可输入字符；快捷指令、tab 等返回空串
local swipeActionText(action) =
  if std.type(action) == 'object' && std.objectHas(action, 'symbol') then action.symbol
  else if std.type(action) == 'object' && std.objectHas(action, 'character') then action.character
  else '';

local swipeLabelText(p, actionKey, textKey) =
  if std.objectHas(p, textKey) then p[textKey]
  else if std.objectHas(p, actionKey) then swipeActionText(p[actionKey])
  else '';

local newSwipeLetterButton(isDark, button, extraParams={}) =
  local p = button.params;
  local name = button.name;
  local upText = swipeLabelText(p, 'swipeUpAction', 'swipeUpText');
  local downText = swipeLabelText(p, 'swipeDownAction', 'swipeDownText');
  local downImage = if std.objectHas(p, 'swipeDownSystemImageName') then p.swipeDownSystemImageName else '';
  // 上 / 下滑气泡只给能输入字符的动作，快捷指令不弹气泡
  local upHint = if std.objectHas(p, 'swipeUpAction') then swipeActionText(p.swipeUpAction) else '';
  local downHint = if std.objectHas(p, 'swipeDownAction') then swipeActionText(p.swipeDownAction) else '';
  local upBadgeName = name + 'SwipeUpBadgeForegroundStyle';
  local downBadgeName = name + 'SwipeDownBadgeForegroundStyle';
  local upHintName = name + 'SwipeUpHintForegroundStyle';
  local downHintName = name + 'SwipeDownHintForegroundStyle';
  basicStyle.newAlphabeticButton(
    name,
    isDark,
    extraParams
    + p {
      hintStyle: hintStyle.hintStyle
                 + (if upHint != '' then { swipeUpForegroundStyle: upHintName } else {})
                 + (if downHint != '' then { swipeDownForegroundStyle: downHintName } else {}),
    }
    + {
      foregroundStyleName:
        [name + 'ForegroundStyle']
        + (if upText != '' then [upBadgeName] else [])
        + (if downText != '' || downImage != '' then [downBadgeName] else []),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, button)
        + (
          if upText != '' then
            { [upBadgeName]: basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, { text: upText } + topBadgeLabelUpParams) }
          else {}
        )
        + (
          if downImage != '' then
            { [downBadgeName]: basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, { systemImageName: downImage } + bottomBadgeLabelDownParams) }
          else if downText != '' then
            { [downBadgeName]: basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, { text: downText } + bottomBadgeLabelDownParams) }
          else {}
        ),
    }
  )
  + (if upHint != '' then { [upHintName]: basicStyle.newAlphabeticButtonHintStyle(isDark) + { text: upHint } } else {})
  + (if downHint != '' then { [downHintName]: basicStyle.newAlphabeticButtonHintStyle(isDark) + { text: downHint } } else {});

// 回车/确定键事件通知（与 T9 九键逻辑一致）：
// 1) returnKeyType 通知：覆盖所有回车类型，刷新常态文字并保持灰色底
// 2) keyboardAction 通知：26 键是英文直接上屏（字母动作为 { symbol: 'a' }），
//    没有 RIME 预编辑，preeditChanged 永远不会命中；因此改为监听字母按键，
//    首次按下字母后锁定蓝色（仅 light 使用）
// 3) 蓝色态前景按 $returnKeyType 取对应白字样式，保证提示词正确
local enterReturnKeyNotification = {
  alphabeticEnterReturnKeyChangedNotification: {
    notificationType: 'returnKeyType',
    returnKeyType: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    backgroundStyle: basicStyle.systemButtonBackgroundStyleName,
    foregroundStyle: 'enterButtonForegroundStyle',
  },
};

local enterBlueLabels = [
  '换行', '前往', 'Google', '加入', 'next',
  'route', '搜索', '发送', 'Yahoo', '完成',
  'emergencyCall', 'continue',
];

local enterBlueTextStyles = {
  ['alphabeticEnterBlueTextStyle' + i]: {
    buttonStyleType: 'text',
    fontSize: 16,
    normalColor: '#FFFFFF',
    highlightColor: '#FFFFFF',
    text: enterBlueLabels[i],
  }
  for i in std.range(0, 11)
};

// 26 键无预编辑：监听 a-z / A-Z 的字母动作，命中后锁定蓝色
local enterBlueChars =
  [std.char(c) for c in std.range(97, 122)] +
  [std.char(c) for c in std.range(65, 90)];

// 蓝色态前景写法（三选一）：
//  'conditions'：12 条 $returnKeyType 条件数组原样写进每个字母通知（最初写法，
//                52 个字母通知合计约 75KB，light 26 键文件约 128KB，切换偏慢）。
//  'anchor'    ：条件数组只完整写一次，其余通知用 YAML 锚点（&/*）引用，
//                解析结果与 conditions 完全相同，文件约减半。
//  'variable'  ：直接使用 blueButtonForegroundStyle（文字为 $returnKeyType），文件最小。
// 注：JavaScript 写法在通知里不生效（实测蓝色块上文字消失），已弃用。
// 实测 variable 与 anchor 均正常，variable 文件最小、26 键与 T9 互切最灵敏，选用 variable。
local enterBlueForegroundMode = 'variable';

// 26 键性能相关开关（排查 26 键 → T9 来回切换卡顿用）：
//  enterBlueOnLetter：浅色模式下首次输入字母后回车锁定蓝色，需要在回车键上挂 52 个字母监听通知。
//                     false 时与深色模式一致：只按输入框类型显示蓝色，不再监听字母。
//  matchT9Height    ：26 键顶部使用与 T9 相同的预编辑区 + 音节栏 + 候选栏，总高度与 T9 一致，
//                     来回切换时键盘不需要改变高度。
local enterBlueOnLetter = true;
// 实测：高度一致后 26 键 ↔ T9 来回切换不再卡顿（卡顿来自切换时键盘高度变化），选用 true。
local matchT9Height = true;
local enterBlueAnchorName = 'enterBlueFg';

local enterBlueForegroundStyleConditions =
  [
    {
      conditionKey: '$returnKeyType',
      conditionValue: [i],
      styleName: 'alphabeticEnterBlueTextStyle' + i,
    }
    for i in std.range(0, 11)
  ];

local enterBlueForegroundStyle =
  if enterBlueForegroundMode == 'variable'
  then basicStyle.blueButtonForegroundStyleName
  else enterBlueForegroundStyleConditions;

// 输出 YAML 文本。anchor 模式下：第一次出现的条件数组加锚点 &enterBlueFg，
// 后面相同的数组全部替换为别名 *enterBlueFg（JSON 本身就是合法的 YAML 流式写法）。
local manifestWithAnchor(content) =
  local text = std.toString(content);
  if enterBlueForegroundMode != 'anchor' then text
  else
    local fragment = std.toString(enterBlueForegroundStyleConditions);
    local alias = '*' + enterBlueAnchorName;
    local replaced = std.strReplace(text, fragment, alias);
    local idx = std.findSubstr(alias, replaced);
    if std.length(idx) == 0 then text
    else
      local i = idx[0];
      local tailStart = i + std.length(alias);
      std.substr(replaced, 0, i)
      + '&' + enterBlueAnchorName + ' ' + fragment
      + std.substr(replaced, tailStart, std.length(replaced) - tailStart);

local enterBlueNotifications = {
  ['alphabeticEnterBlueNotification_' + c]: {
    notificationType: 'keyboardAction',
    notificationKeyboardAction: { symbol: c },
    // 命中后锁定：字母上屏、按键状态变化后仍保持蓝色提醒
    lockedNotificationMatchState: true,
    backgroundStyle: basicStyle.blueButtonBackgroundStyleName,
    foregroundStyle: enterBlueForegroundStyle,
  }
  for c in enterBlueChars
};

local enterBlueNotificationNames =
  ['alphabeticEnterBluePreeditNotification'] +
  ['alphabeticEnterBlueNotification_' + c for c in enterBlueChars];

// 兼容：若某些方案下 26 键仍有预编辑文本，同样锁定蓝色
local enterBluePreeditNotification = {
  alphabeticEnterBluePreeditNotification: {
    notificationType: 'preeditChanged',
    lockedNotificationMatchState: true,
    backgroundStyle: basicStyle.blueButtonBackgroundStyleName,
    foregroundStyle: enterBlueForegroundStyle,
  },
};


// 标准26键布局
local alphabeticKeyboardLayout(addSemicolon=false) = {
  keyboardLayout: [
    {
      HStack: {
        subviews: [
          {
            Cell: params.keyboard.qButton.name,
          },
          {
            Cell: params.keyboard.wButton.name,
          },
          {
            Cell: params.keyboard.eButton.name,
          },
          {
            Cell: params.keyboard.rButton.name,
          },
          {
            Cell: params.keyboard.tButton.name,
          },
          {
            Cell: params.keyboard.yButton.name,
          },
          {
            Cell: params.keyboard.uButton.name,
          },
          {
            Cell: params.keyboard.iButton.name,
          },
          {
            Cell: params.keyboard.oButton.name,
          },
          {
            Cell: params.keyboard.pButton.name,
          },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          {
            Cell: params.keyboard.aButton.name,
          },
          {
            Cell: params.keyboard.sButton.name,
          },
          {
            Cell: params.keyboard.dButton.name,
          },
          {
            Cell: params.keyboard.fButton.name,
          },
          {
            Cell: params.keyboard.gButton.name,
          },
          {
            Cell: params.keyboard.hButton.name,
          },
          {
            Cell: params.keyboard.jButton.name,
          },
          {
            Cell: params.keyboard.kButton.name,
          },
          {
            Cell: params.keyboard.lButton.name,
          },
          (
            if addSemicolon == true then
              {
                Cell: params.keyboard.semicolonButton.name,
              }
            else {}
          ),
        ],
      },
    },
    {
      HStack: {
        subviews: [
          {
            Cell: params.keyboard.shiftButton.name,
          },
          {
            Cell: params.keyboard.zButton.name,
          },
          {
            Cell: params.keyboard.xButton.name,
          },
          {
            Cell: params.keyboard.cButton.name,
          },
          {
            Cell: params.keyboard.vButton.name,
          },
          {
            Cell: params.keyboard.bButton.name,
          },
          {
            Cell: params.keyboard.nButton.name,
          },
          {
            Cell: params.keyboard.mButton.name,
          },
          {
            Cell: params.keyboard.backspaceButton.name,
          },
        ],
      },
    },
    {
      HStack: {
        subviews: [
          {
            Cell: params.keyboard.numericButton.name,
          },
          {
            Cell: params.keyboard.commaButton.name,
          },
          {
            Cell: params.keyboard.spaceButton.name,
          },
          {
            Cell: params.keyboard.t9PinyinButton.name,
          },
          {
            Cell: params.keyboard.enterButton.name,
          },
        ],
      },
    },
  ],
};


local newKeyLayout(isDark=false, isPortrait=true, addSemicolon=true) =
  local keyboardHeight = if isPortrait then params.keyboard.height.iPhone.portrait else params.keyboard.height.iPhone.landscape;
  {
    keyboardHeight: keyboardHeight,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }
  + alphabeticKeyboardLayout(addSemicolon)

  // First Row
  + newSwipeLetterButton(isDark, params.keyboard.qButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.wButton.name,
    isDark,
    params.keyboard.wButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.twoButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.wButton.name + 'ForegroundStyle',
        params.keyboard.twoButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.wButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.twoButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.twoButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.eButton.name,
    isDark,
    params.keyboard.eButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.threeButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.eButton.name + 'ForegroundStyle',
        params.keyboard.threeButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.eButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.threeButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.threeButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.rButton.name,
    isDark,
    params.keyboard.rButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.fourButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.rButton.name + 'ForegroundStyle',
        params.keyboard.fourButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.rButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.fourButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.fourButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.tButton.name,
    isDark,
    params.keyboard.tButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.fiveButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.tButton.name + 'ForegroundStyle',
        params.keyboard.fiveButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.tButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.fiveButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.fiveButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.yButton.name,
    isDark,
    params.keyboard.yButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.sixButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.yButton.name + 'ForegroundStyle',
        params.keyboard.sixButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.yButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.sixButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.sixButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.uButton.name,
    isDark,
    params.keyboard.uButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.sevenButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.uButton.name + 'ForegroundStyle',
        params.keyboard.sevenButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.uButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.sevenButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.sevenButton)

  + basicStyle.newAlphabeticButton(
    params.keyboard.iButton.name,
    isDark,
    params.keyboard.iButton.params {
      hintStyle: hintStyle.hintStyle {
        swipeUpForegroundStyle: params.keyboard.eightButton.name + 'SwipeUpHintForegroundStyle',
      },
    }
    + {
      foregroundStyleName: [
        params.keyboard.iButton.name + 'ForegroundStyle',
        params.keyboard.eightButton.name + 'BadgeForegroundStyle',
      ],
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.iButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.eightButton),
    }
  ) + createSwipeUpHintStyle(isDark, params.keyboard.eightButton)

  + newSwipeLetterButton(isDark, params.keyboard.oButton)

  + newSwipeLetterButton(isDark, params.keyboard.pButton)

  // Second Row
  + newSwipeLetterButton(
    isDark,
    params.keyboard.aButton,
    (
      if addSemicolon == false then
        {
          size:
            { width: '168.75/1125' },
          bounds:
            { width: '111/168.75', alignment: 'right' },
        }
      else {}
    )
  )

  + newSwipeLetterButton(isDark, params.keyboard.sButton)

  + newSwipeLetterButton(isDark, params.keyboard.dButton)

  + newSwipeLetterButton(isDark, params.keyboard.fButton)

  + newSwipeLetterButton(isDark, params.keyboard.gButton)

  + newSwipeLetterButton(isDark, params.keyboard.hButton)

  + newSwipeLetterButton(isDark, params.keyboard.jButton)

  + newSwipeLetterButton(isDark, params.keyboard.kButton)

  + newSwipeLetterButton(
    isDark,
    params.keyboard.lButton,
    (
      if addSemicolon == false then
        {
          size:
            { width: '168.75/1125' },
          bounds:
            { width: '111/168.75', alignment: 'left' },
        }
      else {}
    )
  )

  + (
    if addSemicolon == true then
      basicStyle.newAlphabeticButton(
        params.keyboard.semicolonButton.name,
        isDark,
        params.keyboard.semicolonButton.params {
          hintStyle: hintStyle.hintStyle {
            swipeUpForegroundStyle: params.keyboard.colonButton.name + 'SwipeUpHintForegroundStyle',
          },
        }
        + {
          foregroundStyleName: [
            params.keyboard.semicolonButton.name + 'ForegroundStyle',
            params.keyboard.colonButton.name + 'BadgeForegroundStyle',
          ],
        }
        + {
          foregroundStyle:
            createButtonForegroundStyle(isDark, params.keyboard.semicolonButton)
            + createTopBadgeForegroundStyle(isDark, params.keyboard.colonButton),
        }
      ) + createSwipeUpHintStyle(isDark, params.keyboard.colonButton)
    else {}
  )


  // Third Row

  + basicStyle.newSystemButton(
    params.keyboard.shiftButton.name,
    isDark,
    {
      size:
        { width: { percentage: 0.15 } },
      bounds:
        { width: '151/168.75', alignment: 'left' },
    }
    + params.keyboard.shiftButton.params
    + {
      uppercasedStateForegroundStyle: params.keyboard.shiftButton.name + 'UppercasedForegroundStyle',
    }
    + {
      capsLockedStateForegroundStyle: params.keyboard.shiftButton.name + 'CapsLockedForegroundStyle',
    }
  )
  + {
    [params.keyboard.shiftButton.name + 'UppercasedForegroundStyle']:
      basicStyle.newImageSystemButtonForegroundStyle(isDark, params.keyboard.shiftButton.uppercasedParams),
    [params.keyboard.shiftButton.name + 'CapsLockedForegroundStyle']:
      basicStyle.newImageSystemButtonForegroundStyle(isDark, params.keyboard.shiftButton.capsLockedParams),
  }

  + newSwipeLetterButton(isDark, params.keyboard.zButton)

  + newSwipeLetterButton(isDark, params.keyboard.xButton)


  + newSwipeLetterButton(isDark, params.keyboard.cButton)

  + newSwipeLetterButton(isDark, params.keyboard.vButton)

  + newSwipeLetterButton(isDark, params.keyboard.bButton)

  + newSwipeLetterButton(isDark, params.keyboard.nButton)

  + newSwipeLetterButton(isDark, params.keyboard.mButton)

  + basicStyle.newSystemButton(
    params.keyboard.backspaceButton.name,
    isDark,
    {
      size:
        { width: { percentage: 0.15 } },
      bounds:
        { width: '151/168.75', alignment: 'right' },
    } + params.keyboard.backspaceButton.params,
  )

  // Fourth Row

  // 原 123 键改为 En/中：切换回 T9 拼音键盘（不再切数字键盘）
  + basicStyle.newSystemButton(
    params.keyboard.numericButton.name,
    isDark,
    {
      size:
        { width: { percentage: 0.2 } },
    }
    + params.keyboard.numericButton.params {
      action: { keyboardType: 'pinyin' },
      text: '拼音',
    }
  )


  // 原逗号键改为 #+=：切换到符号键盘
  + basicStyle.newAlphabeticButton(
    params.keyboard.commaButton.name,
    isDark,
    {
      size:
        { width: { percentage: 0.1 } },
    }
    + {
      action: { keyboardType: 'symbolic' },
      text: '#@¥',
      fontSize: 16,
    },
    needHint=false,
  )

  + basicStyle.newAlphabeticButton(
    params.keyboard.spaceButton.name,
    isDark,
    params.keyboard.spaceButton.params,
    needHint=false
  )

  // 原 En/中 键改为输入英文点号；不设上滑 / 下滑
  + newSwipeLetterButton(
    isDark,
    {
      name: params.keyboard.t9PinyinButton.name,
      params: {
        action: { symbol: '.' },
        text: '.',
      },
    },
    {
      size:
        { width: { percentage: 0.1 } },
    }
  )

  + basicStyle.newSystemButton(
    params.keyboard.enterButton.name,
    isDark,
    {
      size:
        { width: { percentage: 0.2 } },
    }
    + params.keyboard.enterButton.params
    + (
      // light：与 T9 九键一致，首次字母输入后锁定蓝色并保持提醒
      // dark：维持原有通知不变
      if isDark || !enterBlueOnLetter then
        {}
      else
        {
          backgroundStyle: basicStyle.systemButtonBackgroundStyleName,
          foregroundStyle: 'enterButtonForegroundStyle',
          notification:
            ['alphabeticEnterReturnKeyChangedNotification']
            + enterBlueNotificationNames,
        }
    )
  )
;

{
  // 生成 YAML 文本（供 main.jsonnet 使用）
  manifest(content): manifestWithAnchor(content),

  new(isDark, isPortrait, addSemicolon=false):
    local insets = if isPortrait then params.keyboard.button.backgroundInsets.iPhone.portrait else params.keyboard.button.backgroundInsets.iPhone.landscape;

    local extraParams = {
      insets: insets,
    };

    preedit.new(isDark)
    + toolbar.new(isDark, {}, matchT9Height, isPortrait)
    + basicStyle.newKeyboardBackgroundStyle(isDark)
    + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newAlphabeticButtonHintStyle(isDark)
    + basicStyle.newSystemButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newBlueButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newBlueButtonForegroundStyle(isDark, params.keyboard.enterButton.params)
    + basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 })
    + newKeyLayout(isDark, isPortrait, addSemicolon)
    + basicStyle.newEnterButtonForegroundStyle(isDark, params.keyboard.enterButton.params)
    + basicStyle.newCommitCandidateForegroundStyle(isDark, { text: '选定' })
    // light 的回车蓝色通知与 T9 九键保持一致；dark 不追加
    + (
      if isDark || !enterBlueOnLetter then
        {}
      else
        enterReturnKeyNotification
        + enterBlueNotifications
        + enterBluePreeditNotification
        + (if enterBlueForegroundMode == 'variable' then {} else enterBlueTextStyles)
    )
    // Notifications
    + basicStyle.returnKeyboardTypeChangedNotification
    + basicStyle.preeditChangedForEnterButtonNotification
    + basicStyle.preeditChangedForSpaceButtonNotification
    // 26 键去掉顶部预编辑区，但保留 40pt 的横向候选词栏（工具栏）：
    // 在 T9 打字中（有未上屏拼音）直接按 ABC 切过来时，候选词显示在候选栏里，
    // 不会再叠到 QWERTY 按键上。
    + (if matchT9Height then {} else { preeditHeight: 0 }),
}
