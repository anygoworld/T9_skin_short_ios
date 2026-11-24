local fonts = import '../Constants/Fonts.libsonnet';
local params = import '../Constants/Keyboard.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local preedit = import 'Preedit.libsonnet';
local toolbar = import 'Toolbar.libsonnet';
local utils = import 'Utils.libsonnet';

// 上滑角标（数字）：键面正上方居中
local topBadgeLabelUpParams = {
  center: {
    x: 0.5,
    y: 0.2,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

// 下滑提示（行首 / 复制 …）：键面正下方居中，与上方角标对称
local bottomLabelDownParams = {
  center: {
    x: 0.5,
    y: 0.8,
  },
  fontSize: fonts.iPhone.button.doubleLabelSmallFontSize,
};

local createTopBadgeForegroundStyle(isDark, params={}) = {
  [params.name + 'BadgeForegroundStyle']:
    basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, params.params + topBadgeLabelUpParams),
};

// 有 swipeDownText（文字）或 swipeDownSystemImageName（图标）时才把下滑提示样式加进 foregroundStyle
// （没有下滑功能的键不显示下方小字）
local hasSwipeDownLabel(p) =
  std.objectHas(p, 'swipeDownText') || std.objectHas(p, 'swipeDownSystemImageName');

local swipeDownLabelStyleNames(button) =
  if hasSwipeDownLabel(button.params) then [button.name + 'SwipeDownForegroundStyle'] else [];

// 生成下滑提示样式：优先用图标（如 Tab），否则用文字
local createSwipeDownLabelForegroundStyle(isDark, params={}) =
  if hasSwipeDownLabel(params.params) then {
    [params.name + 'SwipeDownForegroundStyle']:
      basicStyle.newAlphabeticButtonSwipeForegroundStyle(
        isDark,
        (
          if std.objectHas(params.params, 'swipeDownSystemImageName') then
            { systemImageName: params.params.swipeDownSystemImageName }
          else
            { text: params.params.swipeDownText }
        )
        + bottomLabelDownParams
      ),
  } else {};

local createButtonForegroundStyle(isDark, params={}) = {
  [params.name + 'ForegroundStyle']:
    basicStyle.newAlphabeticButtonForegroundStyle(isDark, params.params),
};

// T9 “1”键在打字（有预编辑）时切换为“分隔”：发送 1 交由九键方案做分词
local t9OneButtonPreeditStyles(isDark) = {
  t9OneButtonPreeditNotification: {
    notificationType: 'preeditChanged',
    // 打字态只保留“分隔”，不设置上滑/下滑动作
    action: { character: '1' },
    backgroundStyle: basicStyle.alphabeticButtonBackgroundStyleName,
    foregroundStyle: 't9OneButtonPreeditForegroundStyle',
  },
  t9OneButtonPreeditForegroundStyle:
    basicStyle.newAlphabeticButtonForegroundStyle(isDark, {
      text: '分隔',
      fontSize: fonts.t9ButtonTextFontSize,
    }),
};

// T9 回车/确定键事件通知（参考第三方皮肤思路）：
// 1) returnKeyType 通知：覆盖所有回车类型，负责刷新常态文字
// 2) preeditChanged 通知：命中后锁定为蓝色（仅 light 使用）
// 3) 蓝色态前景用「按 $returnKeyType 分条件的样式数组」，保证每种输入框类型提示词正确
local t9EnterReturnKeyNotification = {
  t9EnterReturnKeyChangedNotification: {
    notificationType: 'returnKeyType',
    returnKeyType: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    backgroundStyle: 'systemButtonBackgroundStyle',
    foregroundStyle: 'enterButtonForegroundStyle',
  },
};

local t9EnterBlueLabels = [
  '换行', '前往', 'Google', '加入', 'next',
  'route', '搜索', '发送', 'Yahoo', '完成',
  'emergencyCall', 'continue',
];

local t9EnterBlueTextStyles = {
  ['t9EnterBlueTextStyle' + i]: {
    buttonStyleType: 'text',
    fontSize: 16,
    normalColor: '#FFFFFF',
    highlightColor: '#FFFFFF',
    text: t9EnterBlueLabels[i],
  }
  for i in std.range(0, 11)
};

local t9EnterBlueNotification = {
  t9EnterBlueNotification: {
    notificationType: 'preeditChanged',
    // 命中后锁定，预编辑清空也不恢复（一直保留蓝色提醒）
    lockedNotificationMatchState: true,
    backgroundStyle: 'blueButtonBackgroundStyle',
    foregroundStyle: [
      {
        conditionKey: '$returnKeyType',
        conditionValue: [i],
        styleName: 't9EnterBlueTextStyle' + i,
      }
      for i in std.range(0, 11)
    ],
  },
};

// 窄 VStack 宽度样式
local narrowVStackStyle = {
  local this = self,
  name: 'narrowVStackStyle',
  style: {
    [this.name]: {
      size: {
        width: { percentage: 0.17 },
      },
    },
  },
};

// 宽 VStack 宽度样式（单个标准键宽）
local wideVStackStyle = {
  local this = self,
  name: 'wideVStackStyle',
  style: {
    [this.name]: {
      size: {
        width: { percentage: 0.22 },
      },
    },
  },
};

// 双宽 VStack 宽度样式（两个标准键宽，用于让空格键横跨两列）
local doubleWideVStackStyle = {
  local this = self,
  name: 'doubleWideVStackStyle',
  style: {
    [this.name]: {
      size: {
        width: { percentage: 0.44 },
      },
    },
  },
};

// 跨两行合并单元格的高度（占键盘高度的 2/4）
local doubleRowSize = { size: { height: '2/4' } };

// 图 1 九宫格布局：5 列 × 4 行
//   列1(窄)  : 123 / #@¥ / ABC(跨两行)
//   列2      : 1 / 4 / 7 / 0
//   列3~4(双宽): 2 3 / 5 6 / 8 9 / 空格(跨两列)
//   列5(窄)  : 退格 / 重输 / 换行(跨两行)
local alphabeticKeyboardLayout = {
  keyboardLayout: [
    {
      VStack: {
        style: narrowVStackStyle.name,
        subviews: [
          {
            Cell: params.keyboard.numericButton.name,
          },
          {
            Cell: params.keyboard.symbolicButton.name,
          },
          {
            Cell: params.keyboard.alphabeticButton.name,
          },
        ],
      },
    },
    {
      VStack: {
        style: wideVStackStyle.name,
        subviews: [
          {
            Cell: params.keyboard.t9OneButton.name,
          },
          {
            Cell: params.keyboard.t9FourButton.name,
          },
          {
            Cell: params.keyboard.t9SevenButton.name,
          },
          {
            Cell: params.keyboard.t9ZeroButton.name,
          },
        ],
      },
    },
    {
      VStack: {
        style: doubleWideVStackStyle.name,
        subviews: [
          {
            HStack: {
              subviews: [
                {
                  Cell: params.keyboard.t9TwoButton.name,
                },
                {
                  Cell: params.keyboard.t9ThreeButton.name,
                },
              ],
            },
          },
          {
            HStack: {
              subviews: [
                {
                  Cell: params.keyboard.t9FiveButton.name,
                },
                {
                  Cell: params.keyboard.t9SixButton.name,
                },
              ],
            },
          },
          {
            HStack: {
              subviews: [
                {
                  Cell: params.keyboard.t9EightButton.name,
                },
                {
                  Cell: params.keyboard.t9NineButton.name,
                },
              ],
            },
          },
          {
            HStack: {
              subviews: [
                {
                  Cell: params.keyboard.spaceButton.name,
                },
              ],
            },
          },
        ],
      },
    },
    {
      VStack: {
        style: narrowVStackStyle.name,
        subviews: [
          {
            Cell: params.keyboard.backspaceButton.name,
          },
          {
            Cell: params.keyboard.t9RestInputButton.name,
          },
          {
            Cell: params.keyboard.enterButton.name,
          },
        ],
      },
    },
  ],
};


local newKeyLayout(isDark=false, isPortrait=false) =

  local keyboardHeight = if isPortrait then params.keyboard.height.iPhone.portrait else params.keyboard.height.iPhone.landscape;

  {
    keyboardHeight: keyboardHeight,
    keyboardStyle: utils.newBackgroundStyle(style=basicStyle.keyboardBackgroundStyleName),
  }

  + alphabeticKeyboardLayout

  + {
    // 集合视图定义
    [params.keyboard.t9SymbolsCollection.name]: {

    } + params.keyboard.t9SymbolsCollection.params,
  }

  + basicStyle.newAlphabeticButton(
    params.keyboard.t9OneButton.name,
    isDark,
    params.keyboard.t9OneButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9OneButton.name + 'ForegroundStyle',
        params.keyboard.oneButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9OneButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9OneButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.oneButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9OneButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9TwoButton.name,
    isDark,
    params.keyboard.t9TwoButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9TwoButton.name + 'ForegroundStyle',
        params.keyboard.twoButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9TwoButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9TwoButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.twoButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9TwoButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9ThreeButton.name,
    isDark,
    params.keyboard.t9ThreeButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9ThreeButton.name + 'ForegroundStyle',
        params.keyboard.threeButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9ThreeButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9ThreeButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.threeButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9ThreeButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9FourButton.name,
    isDark,
    params.keyboard.t9FourButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9FourButton.name + 'ForegroundStyle',
        params.keyboard.fourButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9FourButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9FourButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.fourButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9FourButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9FiveButton.name,
    isDark,
    params.keyboard.t9FiveButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9FiveButton.name + 'ForegroundStyle',
        params.keyboard.fiveButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9FiveButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9FiveButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.fiveButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9FiveButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9SixButton.name,
    isDark,
    params.keyboard.t9SixButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9SixButton.name + 'ForegroundStyle',
        params.keyboard.sixButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9SixButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9SixButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.sixButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9SixButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9SevenButton.name,
    isDark,
    params.keyboard.t9SevenButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9SevenButton.name + 'ForegroundStyle',
        params.keyboard.sevenButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9SevenButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9SevenButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.sevenButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9SevenButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9EightButton.name,
    isDark,
    params.keyboard.t9EightButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9EightButton.name + 'ForegroundStyle',
        params.keyboard.eightButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9EightButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9EightButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.eightButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9EightButton),
    },
    needHint=false
  )
  + basicStyle.newAlphabeticButton(
    params.keyboard.t9NineButton.name,
    isDark,
    params.keyboard.t9NineButton.params
    {
      foregroundStyleName: [
        params.keyboard.t9NineButton.name + 'ForegroundStyle',
        params.keyboard.nineButton.name + 'BadgeForegroundStyle',
      ] + swipeDownLabelStyleNames(params.keyboard.t9NineButton),
    }
    + {
      foregroundStyle:
        createButtonForegroundStyle(isDark, params.keyboard.t9NineButton)
        + createTopBadgeForegroundStyle(isDark, params.keyboard.nineButton)
        + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9NineButton),
    },
    needHint=false
  )

  // 0 键使用与空格键一致的字母键背景色，统一风格
  + basicStyle.newSystemButton(
    params.keyboard.t9ZeroButton.name,
    isDark,
    {
      backgroundStyle: basicStyle.alphabeticButtonBackgroundStyleName,
    } + params.keyboard.t9ZeroButton.params
  )

  + basicStyle.newSystemButton(
    params.keyboard.symbolicButton.name,
    isDark,
    {
      size: { height: '1/4' },
    } + params.keyboard.symbolicButton.params
  )

  + basicStyle.newSystemButton(
    params.keyboard.numericButton.name,
    isDark,
    params.keyboard.numericButton.params
  )

  + basicStyle.newAlphabeticButton(
    params.keyboard.spaceButton.name,
    isDark,
    params.keyboard.spaceButton.params,
    needHint=false
  )

  // 删除键：上滑清空、下滑撤销，键面正上方 / 正下方显示提示（只用于九键）
  + basicStyle.newSystemButton(
    params.keyboard.t9BackspaceButton.name,
    isDark,
    params.keyboard.t9BackspaceButton.params {
      foregroundStyle: [
        params.keyboard.t9BackspaceButton.name + 'ForegroundStyle',
        params.keyboard.t9BackspaceButton.name + 'SwipeUpForegroundStyle',
        params.keyboard.t9BackspaceButton.name + 'SwipeDownForegroundStyle',
      ],
    },
  )
  + {
    [params.keyboard.t9BackspaceButton.name + 'SwipeUpForegroundStyle']:
      basicStyle.newAlphabeticButtonSwipeForegroundStyle(isDark, { text: params.keyboard.t9BackspaceButton.params.swipeUpText } + topBadgeLabelUpParams),
  }
  + createSwipeDownLabelForegroundStyle(isDark, params.keyboard.t9BackspaceButton)

  // ABC：跨第 3、4 行的合并单元格
  + basicStyle.newSystemButton(
    params.keyboard.alphabeticButton.name,
    isDark,
    doubleRowSize + params.keyboard.alphabeticButton.params,
  )

  + basicStyle.newSystemButton(
    params.keyboard.t9RestInputButton.name,
    isDark,
    params.keyboard.t9RestInputButton.params,
  )

  // 换行：跨第 3、4 行的合并单元格
  // 常态灰色；light 模式下有拼音输入后锁定蓝色，dark 保持原色；文字均随 $returnKeyType 变化
  + basicStyle.newSystemButton(
    params.keyboard.enterButton.name,
    isDark,
    doubleRowSize
    + params.keyboard.enterButton.params
    + {
      backgroundStyle: basicStyle.systemButtonBackgroundStyleName,
      foregroundStyle: 'enterButtonForegroundStyle',
      notification: if isDark
        then ['t9EnterReturnKeyChangedNotification']
        else ['t9EnterReturnKeyChangedNotification', 't9EnterBlueNotification'],
    }
  );

local extraParams = {
  insets: params.keyboard.button.backgroundInsets.iPhone.landscape,
};

{
  new(isDark, isPortrait):
    local insets = if isPortrait then params.keyboard.button.backgroundInsets.iPhone.portrait else params.keyboard.button.backgroundInsets.iPhone.landscape;

    local extraParams = {
      insets: insets,
    };

    preedit.new(isDark)
    + toolbar.new(isDark, {}, true, isPortrait)
    + narrowVStackStyle.style
    + wideVStackStyle.style
    + doubleWideVStackStyle.style
    + basicStyle.newKeyboardBackgroundStyle(isDark)
    + basicStyle.newAlphabeticButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newAlphabeticButtonHintStyle(isDark)
    + basicStyle.newSystemButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newBlueButtonBackgroundStyle(isDark, extraParams)
    + basicStyle.newBlueButtonForegroundStyle(isDark, params.keyboard.enterButton.params)
    + basicStyle.newAlphabeticHintBackgroundStyle(isDark, { cornerRadius: 10 })
    + newKeyLayout(isDark, isPortrait)
    + t9OneButtonPreeditStyles(isDark)
    + t9EnterReturnKeyNotification
    + t9EnterBlueNotification
    + t9EnterBlueTextStyles
    + basicStyle.newEnterButtonForegroundStyle(isDark, params.keyboard.enterButton.params)
    + basicStyle.newCommitCandidateForegroundStyle(isDark, { text: '选定' })
    // Notifications
    + basicStyle.returnKeyboardTypeChangedNotification
    + basicStyle.preeditChangedForEnterButtonNotification
    + basicStyle.preeditChangedForSpaceButtonNotification,

}
