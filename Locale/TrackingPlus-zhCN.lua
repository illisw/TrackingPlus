-- Chinese Language File
local ADDON_TAG = "TrackingPlus"

local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_TAG, "zhCN")
if L then

L["ADDON_DISABLED"] = "Tracking Plus 当前已禁用."
L["ADDON_ENABLED"] = "Tracking Plus 当前已启用用."
L["ADDON_NAME"] = "Tracking Plus"
L["GROUP_MODES_DESC"] = "设置追踪循环模式，"
L["GROUP_MODES_NAME"] = "追踪"
L["GROUP_SWITCHES_DESC"] = "当特定时间或突发情况时自动暂停追踪切换。"
L["GROUP_SWITCHES_NAME"] = "排除"
L["MODECOUNT_DESC"] = "设置需要切换追踪的追踪类型的最大数量。"
L["MODECOUNT_NAME"] = "追踪类型数量"
L["MODESELECT_NAME"] = "追踪类型"
L["MODESLIST_DESC"] = "选择你要切换的追踪类型。"
L["MODESLIST_NAME"] = "追踪类型"
L["OPTIONS_DESC"] = "打开 Tracking Plus 选项窗口。"
L["OPTIONS_NAME"] = "选项"
L["PROFILES"] = "配置文件"
L["SUSPEND_AUCTION_DESC"] = "当拍卖行窗口打开时暂停。"
L["SUSPEND_AUCTION_NAME"] = "拍卖时暂停"
L["SUSPEND_CITIES_DESC"] = "当在主城时暂停。"
L["SUSPEND_CITIES_NAME"] = "在主城时暂停"
L["SUSPEND_FLYING_DESC"] = "Check to have tracker mode cycle only while flying.  Overrides value for 'Mounted Only'." -- Requires localization
L["SUSPEND_FLYING_NAME"] = "Flying Only" -- Requires localization
L["SUSPEND_INSTANCES_DESC"] = "当在副本时暂停。"
L["SUSPEND_INSTANCES_NAME"] = "在副本时暂停"
L["SUSPEND_SOCKETING_DESC"] = "当物品镶嵌宝石窗口打开时暂停。"
L["SUSPEND_SOCKETING_NAME"] = "物品插宝石时暂停"
L["SUSPEND_TAXI_DESC"] = "当使用飞行点时暂停。"
L["SUSPEND_TAXI_NAME"] = "飞行时暂停"
L["SUSPEND_TRADE_DESC"] = "当交易窗口打开时暂停"
L["SUSPEND_TRADE_NAME"] = "交易时暂停"
L["SUSPEND_TRADESKILL_DESC"] = "当商业技能窗口打开时暂停。"
L["SUSPEND_TRADESKILL_NAME"] = "商业技能时暂停"
L["SUSPEND_UNMOUNTED_DESC"] = "Check to have tracker mode cycle only while mounted.  This includes flying mounts." -- Requires localization
L["SUSPEND_UNMOUNTED_NAME"] = "Mounted Only" -- Requires localization
L["SWITCHDELAY_DESC"] = "切换追踪类型的时间的间隔,单位为秒。"
L["SWITCHDELAY_NAME"] = "追踪类型切换间隔"
L["TOGGLE_COMBAT_DESC"] = "当战斗中暂停。强烈推荐开启这个选项。"
L["TOGGLE_COMBAT_NAME"] = "战斗中暂停"
L["TOGGLE_DESC"] = "开启或关闭 Tracking Plus 插件的启用状态。"
L["TOGGLE_FISHING_DESC"] = "当钓鱼时暂停。"
L["TOGGLE_FISHING_NAME"] = "钓鱼时暂停"
L["TOGGLE_NAME"] = "开启/关闭 Tracking Plus" -- Needs review
L["UPDATING_MAX_MODES"] = "设置最大追踪切换类型数量为"


end
