-- Create Date : 4/23/2010 3:56:28 PM
-- English Language File
local ADDON_TAG = "TrackingPlus"

local debug = false
--[===[@debug@
debug = true
--@end-debug@]===]

local L = LibStub("AceLocale-3.0"):NewLocale(ADDON_TAG, "enUS", true, debug)
if L then

L["ADDON_DISABLED"] = "Tracking Plus is now disabled."
L["ADDON_ENABLED"] = "Tracking Plus is now enabled."
L["ADDON_NAME"] = "Tracking Plus"
L["GROUP_MODES_DESC"] = "Setup the tracking modes cycle."
L["GROUP_MODES_NAME"] = "Tracking"
L["GROUP_SWITCHES_DESC"] = "Automatically pause cycling when certain events or siutations occur."
L["GROUP_SWITCHES_NAME"] = "Exceptions"
L["MODECOUNT_DESC"] = "Specify the maximum number of tracking modes that should be cycled through."
L["MODECOUNT_NAME"] = "Tracking Mode Count"
L["MODESELECT_NAME"] = "Tracking Mode"
L["MODESLIST_DESC"] = "Select which tracking modes you wish to cycle through."
L["MODESLIST_NAME"] = "Tracking Modes"
L["OPTIONS_DESC"] = "Toggle Tracking Plus options window."
L["OPTIONS_NAME"] = "Options"
L["PROFILES"] = "Profiles"
L["SUSPEND_AUCTION_DESC"] = "Suspend tracker mode cycle while auction window is open."
L["SUSPEND_AUCTION_NAME"] = "Auction Pause"
L["SUSPEND_CITIES_DESC"] = "Suspend tracker mode cycle while in cities."
L["SUSPEND_CITIES_NAME"] = "City Pause"
L["SUSPEND_FLYING_DESC"] = "Check to have tracker mode cycle only while flying.  Overrides value for 'Mounted Only'."
L["SUSPEND_FLYING_NAME"] = "Flying Only"
L["SUSPEND_INSTANCES_DESC"] = "Suspend tracker mode cycle while in dungeons."
L["SUSPEND_INSTANCES_NAME"] = "Instance Pause"
L["SUSPEND_SOCKETING_DESC"] = "Suspend tracker mode cycle while item socketing window is open."
L["SUSPEND_SOCKETING_NAME"] = "Item Socketing Pause"
L["SUSPEND_TAXI_DESC"] = "Suspend tracker mode cycle while using flight points."
L["SUSPEND_TAXI_NAME"] = "Taxi Pause"
L["SUSPEND_TRADE_DESC"] = "Suspend tracker mode cycle while trade window is open."
L["SUSPEND_TRADE_NAME"] = "Trade Pause"
L["SUSPEND_TRADESKILL_DESC"] = "Suspend tracker mode cycle while a tradeskill window is open."
L["SUSPEND_TRADESKILL_NAME"] = "Tradeskill Pause"
L["SUSPEND_UNMOUNTED_DESC"] = "Check to have tracker mode cycle only while mounted.  This includes flying mounts."
L["SUSPEND_UNMOUNTED_NAME"] = "Mounted Only"
L["SWITCHDELAY_DESC"] = "The amount of time before the next tracking method is selected, in seconds."
L["SWITCHDELAY_NAME"] = "Tracking Switch Delay"
L["TOGGLE_COMBAT_DESC"] = "Suspend tracker mode cycle during combat.  Strongly recommended to leave this option enabled, as automatically cycling between tracking modes during combat will often interfere with using your abilities."
L["TOGGLE_COMBAT_NAME"] = "Combat Pause"
L["TOGGLE_DESC"] = "Toggle the enabled state of the Tracking Plus addon."
L["TOGGLE_FISHING_DESC"] = "Suspend tracker mode cycle while fishing."
L["TOGGLE_FISHING_NAME"] = "Fishing Pause"
L["TOGGLE_NAME"] = "Cycling Enabled"
L["UPDATING_MAX_MODES"] = "Setting maximum number of tracking modes for cycle to "


--[===[@debug@
L["ADDON_NAME"]			= "Tracking Plus"
L["PROFILES"]			= "Profiles"

-- Options
L["OPTIONS_NAME"]			= "Options"
L["OPTIONS_DESC"]			= "Toggle Tracking Plus options window."
L["TOGGLE_NAME"]			= "Cycling Enabled"
L["TOGGLE_DESC"]			= "Toggle the enabled state of the Tracking Plus addon."
L["GROUP_SWITCHES_NAME"]	= "Exceptions"
L["GROUP_SWITCHES_DESC"]	= "Automatically pause cycling when certain events or siutations occur."

L["SUSPEND_CITIES_NAME"]	= "City Pause"
L["SUSPEND_CITIES_DESC"]	= "Suspend tracker mode cycle while in cities."
L["SUSPEND_INSTANCES_NAME"]	= "Instance Pause"
L["SUSPEND_INSTANCES_DESC"]	= "Suspend tracker mode cycle while in dungeons."
L["SUSPEND_TAXI_NAME"]		= "Taxi Pause"
L["SUSPEND_TAXI_DESC"]		= "Suspend tracker mode cycle while using flight points."
L["TOGGLE_FISHING_NAME"]	= "Fishing Pause"
L["TOGGLE_FISHING_DESC"]	= "Suspend tracker mode cycle while fishing."
L["TOGGLE_COMBAT_NAME"]		= "Combat Pause"
L["TOGGLE_COMBAT_DESC"]		= "Suspend tracker mode cycle during combat.  Strongly recommended to leave this option enabled, as automatically cycling between tracking modes during combat will often interfere with using your abilities."

L["SUSPEND_TRADESKILL_NAME"]= "Tradeskill Pause"
L["SUSPEND_TRADESKILL_DESC"]= "Suspend tracker mode cycle while a tradeskill window is open."
L["SUSPEND_SOCKETING_NAME"]	= "Item Socketing Pause"
L["SUSPEND_SOCKETING_DESC"]	= "Suspend tracker mode cycle while item socketing window is open."
L["SUSPEND_AUCTION_NAME"]	= "Auction Pause"
L["SUSPEND_AUCTION_DESC"]	= "Suspend tracker mode cycle while auction window is open."
L["SUSPEND_TRADE_NAME"]		= "Trade Pause"
L["SUSPEND_TRADE_DESC"]		= "Suspend tracker mode cycle while trade window is open."
L["SUSPEND_UNMOUNTED_NAME"]	= "Mounted Only"
L["SUSPEND_UNMOUNTED_DESC"]	= "Check to have tracker mode cycle only while mounted.  This includes flying mounts."
L["SUSPEND_FLYING_NAME"]	= "Flying Only"
L["SUSPEND_FLYING_DESC"]	= "Check to have tracker mode cycle only while flying.  Overrides value for 'Mounted Only'"


L["GROUP_MODES_NAME"]	= "Tracking"
L["GROUP_MODES_DESC"]	= "Setup the tracking modes cycle."
L["MODECOUNT_NAME"]		= "Tracking Mode Count"
L["MODECOUNT_DESC"]		= "Specify the maximum number of tracking modes that should be cycled through."
L["SWITCHDELAY_NAME"]	= "Tracking Switch Delay"
L["SWITCHDELAY_DESC"]	= "The amount of time before the next tracking method is selected, in seconds."
L["MODESLIST_NAME"]		= "Tracking Modes"
L["MODESLIST_DESC"]		= "Select which tracking modes you wish to cycle through."
L["MODESELECT_NAME"]	= "Tracking Mode"

-- Feedback messages
L["ADDON_ENABLED"]		= "Tracking Plus is now enabled."
L["ADDON_DISABLED"]		= "Tracking Plus is now disabled."
L["UPDATING_MAX_MODES"]	= "Setting maximum number of tracking modes for cycle to "
--@end-debug@]===]

end
