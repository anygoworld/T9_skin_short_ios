local colors = import '../Constants/Colors.libsonnet';
local keyboardParams = import '../Constants/Keyboard.libsonnet';
local basicStyle = import 'BasicStyle.libsonnet';
local utils = import 'Utils.libsonnet';


local newCandidateStyle(param={}, isDark=false) =
  utils.extractProperties(
    param,
    [
      'insets',
      'indexFontSize',
      'indexFontWeight',
      'textFontSize',
      'textFontWeight',
      'commentFontSize',
      'commentFontWeight',
    ]
  )
  + utils.extractColors(
    param,
    [
      'backgroundColor',
      'separatorColor',
      'highlightBackgroundColor',
      'preferredBackgroundColor',
      'preferredIndexColor',
      'preferredTextColor',
      'preferredCommentColor',
      'indexColor',
      'textColor',
      'commentColor',
    ],
    isDark
  );

local toolbarBackgroundStyleName = basicStyle.keyboardBackgroundStyleName;
local horizontalCandidateBackgroundStyleName = basicStyle.keyboardBackgroundStyleName;
local verticalCandidateBackgroundStyleName = basicStyle.keyboardBackgroundStyleName;

// MARK: - 横排候选字

local horizontalCandidatesCollectionViewName = 'horizontalCandidates';
local expandButtonName = 'expandButton';
local horizontalCandidatesLayout = [
  {
    HStack: {
      subviews: [
        {
          Cell: horizontalCandidatesCollectionViewName,
        },
        {
          Cell: expandButtonName,
        },
      ],
    },
  },
];

// MARK: - T9 拼音音节候选栏（横向）
// 借鉴参考皮肤的做法：在 horizontalCandidatesLayout 里用 VStack 把
// 「音节栏 + 分隔线 + 间隔 + 候选词栏」叠起来，点击音节可筛选候选词。
local t9HorizontalSymbolsName = 't9HorizontalSymbolsCollection';
local t9PinyinDividerName = 't9PinyinDivider';
local t9PinyinDividerSpacerName = 't9PinyinDividerSpacer';
local t9PinyinRowStyleName = 't9PinyinRowStyle';
local t9HorizontalCandidatesRowStyleName = 't9HorizontalCandidatesRowStyle';
local t9PinyinDividerRowStyleName = 't9PinyinDividerRowStyle';
local t9PinyinDividerSpacerRowStyleName = 't9PinyinDividerSpacerRowStyle';
local t9PinyinExpandedDividerSpacerRowStyleName = 't9PinyinExpandedDividerSpacerRowStyle';
// 纵向候选展开态继续复用横向 T9 音节集合，保持展开前后的筛选栏一致。

local t9PinyinBarLayout = [
  {
    VStack: {
      subviews: [
        {
          HStack: {
            style: t9PinyinRowStyleName,
            subviews: [{ Cell: t9HorizontalSymbolsName }],
          },
        },
        {
          HStack: {
            style: t9PinyinDividerRowStyleName,
            subviews: [{ Cell: t9PinyinDividerName }],
          },
        },
        {
          HStack: {
            style: t9PinyinDividerSpacerRowStyleName,
            subviews: [{ Cell: t9PinyinDividerSpacerName }],
          },
        },
        {
          HStack: {
            style: t9HorizontalCandidatesRowStyleName,
            subviews: [
              { Cell: horizontalCandidatesCollectionViewName },
              { Cell: expandButtonName },
            ],
          },
        },
      ],
    },
  },
];

local newT9PinyinBar(isDark=false, isPortrait=false) = {
  // 音节栏集合
  [t9HorizontalSymbolsName]: {
    type: 't9HorizontalSymbols',
    // 集合本身也明确锁定高度，避免纵向候选展开时被父级布局压缩。
    size: { height: 29.5 },
    backgroundStyle: toolbarBackgroundStyleName,
    cellStyle: 't9PinyinCellStyle',
    insets: { top: 2, left: 4, bottom: 2, right: 4 },
    interCellSpacing: 36,
    maxColumns: 7,
  },
  t9PinyinCellStyle: {
    backgroundStyle: 't9PinyinCellBackgroundStyle',
    foregroundStyle: 't9PinyinCellForegroundStyle',
    insets: { left: 24, right: 24 },
  },
  t9PinyinCellBackgroundStyle: utils.newGeometryStyle({
    normalColor: { light: '#ffffff00', dark: '#00000000' },
    highlightColor: colors.labelColor.quaternary,
    cornerRadius: 6,
  }, isDark),
  t9PinyinCellForegroundStyle: utils.newTextStyle({
    normalColor: colors.labelColor.primary,
    highlightColor: colors.labelColor.primary,
    fontSize: 20,
  }, isDark),
  // 分隔线
  [t9PinyinDividerName]: {
    action: 'none',
    backgroundStyle: 't9PinyinDividerBackgroundStyle',
  },
  t9PinyinDividerBackgroundStyle: utils.newGeometryStyle({
    normalColor: colors.separatorColor,
    highlightColor: colors.separatorColor,
  }, isDark),
  [t9PinyinDividerSpacerName]: {
    action: 'none',
    backgroundStyle: 't9PinyinDividerSpacerBackgroundStyle',
  },
  t9PinyinDividerSpacerBackgroundStyle: utils.newGeometryStyle({
    normalColor: { light: '#ffffff00', dark: '#00000000' },
    highlightColor: { light: '#ffffff00', dark: '#00000000' },
  }, isDark),
  // 行高
  // 音节栏常态与展开态固定为相同高度；恢复紧凑的 29.5 pt，避免挤压横向候选词栏。
  // 横向候选词栏独立固定为 40 pt，两个区域不再争抢高度。
  [t9PinyinRowStyleName]: { size: { height: 29.5 } },
  [t9HorizontalCandidatesRowStyleName]: { size: { height: 40 } },
  [t9PinyinDividerRowStyleName]: { size: { height: 0.5 } },
  [t9PinyinDividerSpacerRowStyleName]: { size: { height: 4 } },
  // 展开态缩小分隔线与纵向候选词之间的留白。
  [t9PinyinExpandedDividerSpacerRowStyleName]: { size: { height: 1 } },
};

local newHorizontalCandidatesCollectionView(isDark=false) = {
  [horizontalCandidatesCollectionViewName]: {
    type: 'horizontalCandidates',
    candidateStyle: 'horizontalCandidateStyle',
  },
  horizontalCandidateStyle: newCandidateStyle(keyboardParams.candidateStyle, isDark),
};

local newExpandButton(isDark) = {
  [expandButtonName]:
    {
      size: { width: 44 },
      action: { shortcut: '#candidatesBarStateToggle' },
    }
    + utils.newForegroundStyle(style=expandButtonName + 'ForegroundStyle'),
  [expandButtonName + 'ForegroundStyle']:
    utils.newSystemImageStyle(keyboardParams.horizontalCandidateStyle.expandButton, isDark),
};


// MARK: - 纵排候选字

local verticalCandidateCollectionViewName = 'verticalCandidates';
local verticalLastRowStyleName = 'verticalLastRowStyle';
local verticalCandidatePageUpButtonStyleName = 'verticalPageUpButtonStyle';
local verticalCandidatePageDownButtonStyleName = 'verticalPageDownButtonStyle';
local verticalCandidateReturnButtonStyleName = 'verticalReturnButtonStyle';
local verticalCandidateBackspaceButtonStyleName = 'verticalBackspaceButtonStyle';

local verticalCandidatesLayout = [
  {
    HStack: {
      subviews: [
        {
          Cell: verticalCandidateCollectionViewName,
        },
      ],
    },
  },
  {
    HStack: {
      style: verticalLastRowStyleName,
      subviews: [
        {
          Cell: verticalCandidatePageUpButtonStyleName,
        },
        {
          Cell: verticalCandidatePageDownButtonStyleName,
        },
        {
          Cell: verticalCandidateReturnButtonStyleName,
        },
        {
          Cell: verticalCandidateBackspaceButtonStyleName,
        },
      ],
    },
  },
];

// T9 纵向候选展开态：顶部保留横向拼音音节栏，下方显示纵向候选词与底部功能键。
local t9PinyinBarVerticalCandidatesLayout = [
  {
    VStack: {
      subviews: [
        {
          HStack: {
            style: t9PinyinRowStyleName,
            subviews: [{ Cell: t9HorizontalSymbolsName }],
          },
        },
        {
          HStack: {
            style: t9PinyinDividerRowStyleName,
            subviews: [{ Cell: t9PinyinDividerName }],
          },
        },
        {
          HStack: {
            style: t9PinyinExpandedDividerSpacerRowStyleName,
            subviews: [{ Cell: t9PinyinDividerSpacerName }],
          },
        },
        {
          HStack: {
            subviews: [
              { Cell: verticalCandidateCollectionViewName },
            ],
          },
        },
        {
          HStack: {
            style: verticalLastRowStyleName,
            subviews: [
              { Cell: verticalCandidatePageUpButtonStyleName },
              { Cell: verticalCandidatePageDownButtonStyleName },
              { Cell: verticalCandidateReturnButtonStyleName },
              { Cell: verticalCandidateBackspaceButtonStyleName },
            ],
          },
        },
      ],
    },
  },
];


local newVerticalCandidateCollectionStyle(isDark) = {
  [verticalCandidateCollectionViewName]:
    {
      type: 'verticalCandidates',
      insets: keyboardParams.verticalCandidateStyle.candidateCollectionStyle.insets,
      maxRows: keyboardParams.verticalCandidateStyle.candidateCollectionStyle.maxRows,
      maxColumns: keyboardParams.verticalCandidateStyle.candidateCollectionStyle.maxColumns,
      candidateStyle: 'verticalCandidateStyle',
    } +
    utils.extractColors(
      keyboardParams.verticalCandidateStyle.candidateCollectionStyle,
      [
        'separatorColor',
      ],
      isDark
    ),
  verticalCandidateStyle: newCandidateStyle(keyboardParams.candidateStyle { insets: { left: 6, right: 6, top: 4, bottom: 4 } }, isDark),
};

local verticalLastRowStyle = {
  [verticalLastRowStyleName]:
    {
      size: { height: keyboardParams.verticalCandidateStyle.bottomRowHeight },
    },
};

local newVerticalCandidatePageUpButtonStyle(isDark) = {
  [verticalCandidatePageUpButtonStyleName]:
    utils.newBackgroundStyle(style=basicStyle.systemButtonBackgroundStyleName)
    + utils.newForegroundStyle(style=verticalCandidatePageUpButtonStyleName + 'ForegroundStyle')
    + {
      action: keyboardParams.verticalCandidateStyle.pageUpButton.action,
    },
  [verticalCandidatePageUpButtonStyleName + 'ForegroundStyle']:
    utils.newSystemImageStyle(keyboardParams.verticalCandidateStyle.pageUpButton, isDark),
};

local newVerticalCandidatePageDownButtonStyle(isDark) = {
  [verticalCandidatePageDownButtonStyleName]:
    utils.newBackgroundStyle(style=basicStyle.systemButtonBackgroundStyleName)
    + utils.newForegroundStyle(style=verticalCandidatePageDownButtonStyleName + 'ForegroundStyle')
    + {
      action: keyboardParams.verticalCandidateStyle.pageDownButton.action,
    },
  [verticalCandidatePageDownButtonStyleName + 'ForegroundStyle']:
    utils.newSystemImageStyle(keyboardParams.verticalCandidateStyle.pageDownButton, isDark),
};


local newVerticalCandidateReturnButtonStyle(isDark) = {
  [verticalCandidateReturnButtonStyleName]:
    utils.newBackgroundStyle(style=basicStyle.systemButtonBackgroundStyleName)
    + utils.newForegroundStyle(style=verticalCandidateReturnButtonStyleName + 'ForegroundStyle')
    + {
      action: keyboardParams.verticalCandidateStyle.returnButton.action,
    },
  [verticalCandidateReturnButtonStyleName + 'ForegroundStyle']:
    utils.newSystemImageStyle(keyboardParams.verticalCandidateStyle.returnButton, isDark),
};


local newVerticalCandidateBackspaceButtonStyle(isDark) = {
  [verticalCandidateBackspaceButtonStyleName]:
    utils.newBackgroundStyle(style=basicStyle.systemButtonBackgroundStyleName)
    + utils.newForegroundStyle(style=verticalCandidateBackspaceButtonStyleName + 'ForegroundStyle')
    + {
      action: 'backspace',
    },
  [verticalCandidateBackspaceButtonStyleName + 'ForegroundStyle']:
    utils.newSystemImageStyle(
      {
        systemImageName: 'delete.left',
        normalColor: colors.toolbarButtonForegroundColor,
        highlightColor: colors.toolbarButtonHighlightedForegroundColor,
        fontSize: keyboardParams.verticalCandidateStyle.pageUpButton.fontSize,
      },
      isDark
    ),
};


local newToolbar(isDark=false, params={}, withT9PinyinBar=false, isPortrait=false) =
  {
    // T9 拼音键盘需要更高的工具栏，容纳音节候选栏 + 分隔线 + 间隔 + 候选词栏
    toolbarHeight: keyboardParams.toolbar.height + (if withT9PinyinBar then 34 else 0),
    toolbarStyle: utils.newBackgroundStyle(style=toolbarBackgroundStyleName),
    toolbarLayout: {},
    horizontalCandidatesStyle:
      utils.extractProperties(keyboardParams.horizontalCandidateStyle + params, ['insets'])
      {
        backgroundStyle: horizontalCandidateBackgroundStyleName,
      },
    horizontalCandidatesLayout: if withT9PinyinBar then t9PinyinBarLayout else horizontalCandidatesLayout,
    verticalCandidatesStyle:
      utils.extractProperties(keyboardParams.verticalCandidateStyle + params, ['insets'])
      {
        backgroundStyle: verticalCandidateBackgroundStyleName,
      },
    verticalCandidatesLayout: if withT9PinyinBar then t9PinyinBarVerticalCandidatesLayout else verticalCandidatesLayout,
    candidateContextMenu: [
      // TODO: 长按候选字菜单
      // {
      //   name: '空格',
      //   action: 'space',
      // },
    ],
  }
  + newHorizontalCandidatesCollectionView(isDark)
  + newExpandButton(isDark)
  + (if withT9PinyinBar then newT9PinyinBar(isDark, isPortrait) else {})
  + newVerticalCandidateCollectionStyle(isDark)
  + verticalLastRowStyle
  + newVerticalCandidatePageUpButtonStyle(isDark)
  + newVerticalCandidatePageDownButtonStyle(isDark)
  + newVerticalCandidateReturnButtonStyle(isDark)
  + newVerticalCandidateBackspaceButtonStyle(isDark);

// 导出
{
  new: newToolbar,
}
