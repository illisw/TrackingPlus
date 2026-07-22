-- Create Date : 4/23/2010 4:00:01 PM
-- French Language File
local ADDON_TAG = "TrackingPlus"

local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_TAG, "frFR")
if L then

L["ADDON_DISABLED"] = "Tracking Plus is now disabled." -- Requires localization
L["ADDON_ENABLED"] = "Tracking Plus is now enabled." -- Requires localization
L["ADDON_NAME"] = "Tracking Plus" -- Requires localization
L["GROUP_MODES_DESC"] = "Setup the tracking modes cycle." -- Requires localization
L["GROUP_MODES_NAME"] = "Tracking" -- Requires localization
L["GROUP_SWITCHES_DESC"] = "Automatically pause cycling when certain events or siutations occur." -- Requires localization
L["GROUP_SWITCHES_NAME"] = "Exceptions" -- Requires localization
L["MODECOUNT_DESC"] = "Specify the maximum number of tracking modes that should be cycled through." -- Requires localization
L["MODECOUNT_NAME"] = "Tracking Mode Count" -- Requires localization
L["MODESELECT_NAME"] = "Tracking Mode" -- Requires localization
L["MODESLIST_DESC"] = "Select which tracking modes you wish to cycle through." -- Requires localization
L["MODESLIST_NAME"] = "Tracking Modes" -- Requires localization
L["OPTIONS_DESC"] = "Toggle Tracking Plus options window." -- Requires localization
L["OPTIONS_NAME"] = "Options" -- Requires localization
L["PROFILES"] = "Profiles" -- Requires localization
L["SUSPEND_AUCTION_DESC"] = "Suspend tracker mode cycle while auction window is open." -- Requires localization
L["SUSPEND_AUCTION_NAME"] = "Auction Pause" -- Requires localization
L["SUSPEND_CITIES_DESC"] = "Suspend tracker mode cycle while in cities." -- Requires localization
L["SUSPEND_CITIES_NAME"] = "City Pause" -- Requires localization
L["SUSPEND_FLYING_DESC"] = "Check to have tracker mode cycle only while flying.  Overrides value for 'Mounted Only'." -- Requires localization
L["SUSPEND_FLYING_NAME"] = "Flying Only" -- Requires localization
L["SUSPEND_INSTANCES_DESC"] = "Suspend tracker mode cycle while in dungeons." -- Requires localization
L["SUSPEND_INSTANCES_NAME"] = "Instance Pause" -- Requires localization
L["SUSPEND_SOCKETING_DESC"] = "Suspend tracker mode cycle while item socketing window is open." -- Requires localization
L["SUSPEND_SOCKETING_NAME"] = "Item Socketing Pause" -- Requires localization
L["SUSPEND_TAXI_DESC"] = "Suspend tracker mode cycle while using flight points." -- Requires localization
L["SUSPEND_TAXI_NAME"] = "Taxi Pause" -- Requires localization
L["SUSPEND_TRADE_DESC"] = "Suspend tracker mode cycle while trade window is open." -- Requires localization
L["SUSPEND_TRADE_NAME"] = "Trade Pause" -- Requires localization
L["SUSPEND_TRADESKILL_DESC"] = "Suspend tracker mode cycle while a tradeskill window is open." -- Requires localization
L["SUSPEND_TRADESKILL_NAME"] = "Tradeskill Pause" -- Requires localization
L["SUSPEND_UNMOUNTED_DESC"] = "Check to have tracker mode cycle only while mounted.  This includes flying mounts." -- Requires localization
L["SUSPEND_UNMOUNTED_NAME"] = "Mounted Only" -- Requires localization
L["SWITCHDELAY_DESC"] = "The amount of time before the next tracking method is selected, in seconds." -- Requires localization
L["SWITCHDELAY_NAME"] = "Tracking Switch Delay" -- Requires localization
L["TOGGLE_COMBAT_DESC"] = "Suspend tracker mode cycle during combat.  Strongly recommended to leave this option enabled, as automatically cycling between tracking modes during combat will often interfere with using your abilities." -- Requires localization
L["TOGGLE_COMBAT_NAME"] = "Combat Pause" -- Requires localization
L["TOGGLE_DESC"] = "Toggle the enabled state of the Tracking Plus addon." -- Requires localization
L["TOGGLE_FISHING_DESC"] = "Suspend tracker mode cycle while fishing." -- Requires localization
L["TOGGLE_FISHING_NAME"] = "Fishing Pause" -- Requires localization
L["TOGGLE_NAME"] = "Cycling Enabled" -- Requires localization
L["UPDATING_MAX_MODES"] = "Setting maximum number of tracking modes for cycle to " -- Requires localization


end

