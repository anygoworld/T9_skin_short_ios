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
// 纵向候选展开态继续复用横向 T9 音节集合，保持展开前后的筛选栏一致。

// 防跳动：常态（横向候选）与展开态（纵向候选）的顶部「音节栏 + 分隔线 + 间隔」
// 必须使用完全相同的容器内边距和行高，切换时音节栏才不会被压缩或上下错位。
//  - 两种状态的容器 insets 统一为 0（原先常态有 top 8 / bottom 1 / left 3，展开态没有，
//    导致常态 74pt 的行高总和被塞进 65pt 的可用高度里而被等比压缩）。
//  - 两种状态共用同一组行样式，不再区分 Expanded 版本。
//  - 常态各行高度之和恰好等于 toolbarHeight，不再发生压缩。
local t9PinyinBarMetrics = {
  // 实机对比 34/36/38/40/42 后选定 36 pt
  pinyinRowHeight: 36,
  dividerHeight: 0.5,
  dividerSpacerHeight: 1.5,
  candidatesRowHeight: 40,
};
local t9PinyinBarTotalHeight =
  t9PinyinBarMetrics.pinyinRowHeight + t9PinyinBarMetrics.dividerHeight
  + t9PinyinBarMetrics.dividerSpacerHeight + t9PinyinBarMetrics.candidatesRowHeight;
local t9PinyinBarContainerInsets = { top: 0, left: 0, bottom: 0, right: 0 };

// 音节栏（mi ni m n o …）的间距参数。
// 注意：实测（2026-11）元书的 t9HorizontalSymbols 音节栏不读取皮肤里的间距、宽度、
// 字号等设置，以下参数及 t9PinyinCellStyle / t9PinyinCellForegroundStyle 修改后均无效果，
// 音节间距由元书内部决定。保留这些值以便元书日后开放配置时直接调整。
//  interCellSpacing：相邻两个音节之间的空隙
//  cellPaddingX    ：每个音节文字左右的留白
//  maxColumns      ：一屏最多显示的音节个数
local t9PinyinSymbolSpacing = {
  interCellSpacing: 36,
  cellPaddingX: 24,
  maxColumns: 7,
};

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
    backgroundStyle: toolbarBackgroundStyleName,
    cellStyle: 't9PinyinCellStyle',
    insets: { top: 2, left: 4, bottom: 2, right: 4 },
    interCellSpacing: t9PinyinSymbolSpacing.interCellSpacing,
    maxColumns: t9PinyinSymbolSpacing.maxColumns,
  },
  t9PinyinCellStyle: {
    backgroundStyle: 't9PinyinCellBackgroundStyle',
    foregroundStyle: 't9PinyinCellForegroundStyle',
    insets: { left: t9PinyinSymbolSpacing.cellPaddingX, right: t9PinyinSymbolSpacing.cellPaddingX },
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
  // 音节栏、分隔线、间隔在常态与展开态共用同一组样式，保证切换时位置与高度完全一致。
  // 常态四行之和 = toolbarHeight，不会被压缩。
  [t9PinyinRowStyleName]: { size: { height: t9PinyinBarMetrics.pinyinRowHeight } },
  [t9PinyinDividerRowStyleName]: { size: { height: t9PinyinBarMetrics.dividerHeight } },
  [t9PinyinDividerSpacerRowStyleName]: { size: { height: t9PinyinBarMetrics.dividerSpacerHeight } },
  [t9HorizontalCandidatesRowStyleName]: { size: { height: t9PinyinBarMetrics.candidatesRowHeight } },
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
// 顶部三行与常态完全相同（同一组样式），展开/收起时音节栏不跳动。
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
            style: t9PinyinDividerSpacerRowStyleName,
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
    // T9 拼音键盘需要更高的工具栏，容纳音节候选栏 + 分隔线 + 间隔 + 候选词栏；
    // 高度直接取各行之和，保证常态下各行不被压缩。
    toolbarHeight: if withT9PinyinBar then t9PinyinBarTotalHeight else keyboardParams.toolbar.height,
    toolbarStyle: utils.newBackgroundStyle(style=toolbarBackgroundStyleName),
    toolbarLayout: {},
    horizontalCandidatesStyle:
      (if withT9PinyinBar
       then { insets: t9PinyinBarContainerInsets }
       else utils.extractProperties(keyboardParams.horizontalCandidateStyle + params, ['insets']))
      {
        backgroundStyle: horizontalCandidateBackgroundStyleName,
      },
    horizontalCandidatesLayout: if withT9PinyinBar then t9PinyinBarLayout else horizontalCandidatesLayout,
    verticalCandidatesStyle:
      // T9 展开态与常态使用同一套容器内边距，顶部音节栏位置保持一致
      (if withT9PinyinBar
       then { insets: t9PinyinBarContainerInsets }
       else utils.extractProperties(keyboardParams.verticalCandidateStyle + params, ['insets']))
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
