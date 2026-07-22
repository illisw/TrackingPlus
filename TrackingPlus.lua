-- Author      : ron
-- Create Date : 4/16/2010 12:48:00 PM
local ADDON_TAG = "TrackingPlus"

--[[
@todo
- [DONE (needs translations)] add localization support
- [DONE] add profile support
- [DONE] add option to set how long before it switches to next tracking type
- [DONE] add checks for player in combat
- [DONE] add check for player casting
- add support for holding a key to temporarily suspend cycling (i.e. shift)
- setup keybinding support
-- add keybind for switching direction of cycle

- add support for setting times for each tracking mode individually (stay 2 secs on fish, 3 secs on mining, etc.)
-- have a checkbox (allow specifying times individually)

- when populating drop down widgets, don't add types that are currently selected in other drop downs
- when user learns new tracking abilities, refresh everything appropriately
- [DONE] when user has socketing UI open, suspend cycling

========
Options
========
- when fishing pole equipped, what should tracking type be set to? (fishing [only if fishing buddy is disabled], cycle, suspend cycling)
- custom time limit for each type?
- [DONE] stop cycling when in cities?
- [DONE (backend not yet implemented)] stop cycling when on taxi? 
--]]

TrackingPlus = LibStub("AceAddon-3.0"):NewAddon(ADDON_TAG,
	"AceConsole-3.0",
	"AceHook-3.0",
	"AceTimer-3.0",
	"AceEvent-3.0")
	
_G[ADDON_TAG] = TrackingPlus

local TP = TrackingPlus
local ace_config = LibStub("AceConfig-3.0")
local ace_reg = LibStub("AceConfigRegistry-3.0")
local ace_config_dlg = LibStub("AceConfigDialog-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale(ADDON_TAG, true)
local LBZ = LibStub("LibBabble-Zone-3.0"):GetLookupTable()
local bDebugMode = false
local CurrentCyclePosition = 0
local ADDON_NAME = L["ADDON_NAME"]

-- State variables
local playerEnteredWorldCalled = false
local cachedMainHandSlotId;

TP.TP_STATE_TABLE = {}

--[[
	copied from a blizzard file; not all were needed, but wanted to leave here as reference
local tconcat, tinsert, tsort, tremove = table.concat, table.insert, table.sort, table.remove
local strmatch, format = string.match, string.format
local assert, loadstring, error = assert, loadstring, error
local pairs, next, select, type, unpack = pairs, next, select, type, unpack
local rawset, tostring = rawset, tostring
local math_min, math_max, math_floor = math.min, math.max, math.floor
--]]
local tinsert = table.insert
local strmatch, strformat, strlower, strupper = string.match, string.format, string.lower, string.upper
local pairs, next, type = pairs, next, type
local tostring = tostring

local CityZoneText = {
	"Orgrimmar", "Undercity", "Thunder Bluff", "Silvermoon City",
	"Stormwind City", "Ironforge", "Darnassus", "The Exodar",
	"Shattrath City", "Dalaran",
	"Booty Bay", "Everlook", "Gadgetzan", "Ratchet",
}
local InstanceZoneText = {
	EasternKingdoms = {
		"Blackrock Depths", "Blackwing Lair", "The Deadmines", "Gnomeregan", "Karazhan", "Lower Blackrock Spire", "Magisters' Terrace", "Molten Core",
		"Scarlet Monastery", "Scholomance", "Shadowfang Keep", "The Stockade", "Stratholme", "Sunwell Plateau", "The Temple of Atal'Hakkar", "Uldaman",
		"Upper Blackrock Spire", "Zul'Aman", "Zul'Gurub",
	},
	Kalimdor = {
		"Hyjal Summit", "Blackfathom Deeps", "The Culling of Stratholme", "Dire Maul", "Maraudon", "Onyxia's Lair", "Ragefire Chasm", "Razorfen Downs",
		"Razorfen Kraul", "Ruins of Ahn'Qiraj", "Temple of Ahn'Qiraj", "Wailing Caverns", "Zul'Farrak",
		"Old Hillsbrad Foothills", "The Black Morass",
	},
	Outlands = {
		"The Arcatraz", "Auchenai Crypts", "Black Temple", "The Blood Furnace", "The Botanica", "Gruul's Lair", "Hellfire Ramparts", "Magtheridon's Lair", "Mana-Tombs",
		"The Mechanar", "Serpentshrine Cavern", "Sethekk Halls", "Shadow Labyrinth", "The Shattered Halls", "The Slave Pens", "The Steamvault", "The Eye", "The Underbog",
	},
	Northrend = {
		"Ahn'kahet: The Old Kingdom", "Azjol-Nerub", "Drak'Tharon Keep", "The Eye of Eternity", "The Forge of Souls", "Gundrak", "Halls of Lightning", "Halls of Reflection",
		"Halls of Stone", "The Oculus", "Pit of Saron", "The Nexus", "Trial of the Champion", "Utgarde Keep", "Utgarde Pinnacle", "The Violet Hold",
		"Icecrown Citadel", "Naxxramas", "The Obsidian Sanctum", "Trial of the Crusader", "Ulduar", "Vault of Archavon",
	},
}

local dprint = function(str) end
local dprintf = function(str,...) end
local function EnableDebugPrint()
	dprint = function(str)
		TP.Print(str)
	end
	dprintf = function(str, ...)
		TP.Print(strformat(str, ...))
	end
end
local function DisableDebugPrint()
	dprint = function(str) end
	dprintf = function(str) end
end
function t_print(str)
	TP.Print(str)
end
function t_printf(str, ...)
	TP.Print(strformat(str, ...))
end

--[[
	info.options = the options table
	info[0] = slash command
	info[1] = first group name
	info[#info] = current option name
	info.arg
	info.handler
	info.type
	info.option = current option
	info.uiType
	info.uiName
	
	Currently inherited are: set, get, func, confirm, validate, disabled, hidden
]]--

-- simple wrapper for informing Ace3 that something has changed which requires the ConfigTableChange notification
-- to be fired
local function NotifyOptionChanged()
	ace_reg:NotifyChange(ADDON_TAG)

-- no need for timer to queue until next frame; Ace is already doing this
--	if not TP.notifyOptionChangeTimerHandle then
--		TP.notifyOptionChangeTimerHandle = TP:ScheduleTimer("OnTimer_NotifyOptionChanged", 0.00001)
--	end
end

local TP_ACE_OPTS = {
	name = ADDON_TAG,
	handler	= TrackingPlus,
	type = "group",
	args = {
		config = {
			order = 0,
			name = L["OPTIONS_NAME"],
			desc = L["OPTIONS_DESC"],
			type = "execute",
			func = function()
				TrackingPlus:ACE_ToggleTrackingCyclerConfig()
			end,
			guiHidden = true,
		},
		toggle = {
			type = "toggle",
			name = L["TOGGLE_NAME"],
			desc = L["TOGGLE_DESC"],
			order = 1,
			get = "ACE_IsTrackingCyclerEnabled",
			set = "ACE_ToggleTrackingCycler",
		},
		cycle_switch_delay = {
			type = "range",
			name = L["SWITCHDELAY_NAME"],
			desc = L["SWITCHDELAY_DESC"],
			order = 2,
			get = "ACE_GetCyclePeriod",
			set = "ACE_SetCyclePeriod",
			min = 1, max = 30, step = 1,
		},
		options_header = {
			type = "header",
			name = L["OPTIONS_NAME"],
			order = 10,
		},
		switches = {
			type = "group",
			name = L["GROUP_SWITCHES_NAME"],
			desc = L["GROUP_SWITCHES_DESC"],
			order = 15,
			args = {
				suspend_cycle_cities = {
					type = "toggle",
					name = L["SUSPEND_CITIES_NAME"],
					desc = L["SUSPEND_CITIES_DESC"],
					order = 30,
					get = function(info)
						return TP.db.profile.Suspend_InCities
					end,
					set = function(info, value)
						TP.db.profile.Suspend_InCities = value
					end,
				},
				suspend_cycle_instances = {
					type = "toggle",
					name = L["SUSPEND_INSTANCES_NAME"],
					desc = L["SUSPEND_INSTANCES_DESC"],
					order = 31,
					get = function(info)
						return TP.db.profile.Suspend_InInstances
					end,
					set = function(info, value)
						TP.db.profile.Suspend_InInstances = value
					end,
				},
				suspend_cycle_taxies = {
					type = "toggle",
					name = L["SUSPEND_TAXI_NAME"],
					desc = L["SUSPEND_TAXI_DESC"],
					order = 32,
					get = function(info)
						return TP.db.profile.Suspend_UsingTaxi
					end,
					set = function(info, value)
						TP.db.profile.Suspend_UsingTaxi = value
					end,
					disabled = true,
				},
				suspend_cycle_fishing = {
					type = "toggle",
					name = L["TOGGLE_FISHING_NAME"],
					desc = L["TOGGLE_FISHING_DESC"],
					order = 35,
					get = function(info)
						return TP.db.profile.Suspend_Fishing
					end,
					set = function(info, value)
						TP.db.profile.Suspend_Fishing = value
					end,
				},
				suspend_cycle_combat = {
					type = "toggle",
					name = L["TOGGLE_COMBAT_NAME"],
					desc = L["TOGGLE_COMBAT_DESC"],
					order = 36,
					get = function(info)
						return TP.db.profile.Suspend_InCombat
					end,
					set = function(info, value)
						TP.db.profile.Suspend_InCombat = value
					end,
				},
				suspend_cycle_tradeskill = {
					type = "toggle",
					name = L["SUSPEND_TRADESKILL_NAME"],
					desc = L["SUSPEND_TRADESKILL_DESC"],
					order = 32,
					get = function(info)
						return TP.db.profile.Suspend_TradeskillUI
					end,
					set = function(info, value)
						TP.db.profile.Suspend_TradeskillUI = value
					end,
					disabled = true,
				},
				suspend_cycle_socketing = {
					type = "toggle",
					name = L["SUSPEND_SOCKETING_NAME"],
					desc = L["SUSPEND_SOCKETING_DESC"],
					order = 32,
					get = function(info)
						return TP.db.profile.Suspend_SocketingUI
					end,
					set = function(info, value)
						TP.db.profile.Suspend_SocketingUI = value
					end,
				},
				suspend_cycle_auction = {
					type = "toggle",
					name = L["SUSPEND_AUCTION_NAME"],
					desc = L["SUSPEND_AUCTION_DESC"],
					order = 33,
					get = function(info)
						return TP.db.profile.Suspend_AuctionUI
					end,
					set = function(info, value)
						TP.db.profile.Suspend_AuctionUI = value
					end,
					disabled = true,
				},
				suspend_cycle_trade = {
					type = "toggle",
					name = L["SUSPEND_TRADE_NAME"],
					desc = L["SUSPEND_TRADE_DESC"],
					order = 34,
					get = function(info)
						return TP.db.profile.Suspend_TradeUI
					end,
					set = function(info, value)
						TP.db.profile.Suspend_TradeUI = value
					end,
					disabled = true,
				},
				suspend_unmounted = {
					type = "toggle",
					name = L["SUSPEND_UNMOUNTED_NAME"],
					desc = L["SUSPEND_UNMOUNTED_DESC"],
					order = 35,
					get = function(info)
						return TP.db.profile.Suspend_Unmounted
					end,
					set = function(info,value)
						TP.db.profile.Suspend_Unmounted = value
					end,
				},
				suspend_unflying = {
					type = "toggle",
					name = L["SUSPEND_FLYING_NAME"],
					desc = L["SUSPEND_FLYING_DESC"],
					order = 35,
					get = function(info)
						return TP.db.profile.Suspend_Unflying
					end,
					set = function(info,value)
						TP.db.profile.Suspend_Unflying = value
					end,
				},
			},
		},
		tracker_selection = {
			type = "group",
			name = L["GROUP_MODES_NAME"],
			desc = L["GROUP_MODES_DESC"],
			order = 50,
--			inline = true,
			args = {
				trackercount = {
					type = "range",
					name = L["MODECOUNT_NAME"],
					desc = L["MODECOUNT_DESC"],
					order = 10,
					get = "ACE_GetWatchedTrackerCount",
					set = "ACE_SetWatchedTrackerCount",
					min = 2, max = 20, step = 1,
					--@todo hook into max available modes
				},
				trackingtypes = {
					type = "group",
					name = L["MODESLIST_NAME"],
					desc = L["MODESLIST_DESC"],
					order = 20,
					inline = true,
					cmdHidden = true,
					get = "ACE_GetTrackingType",
					set = "ACE_SetTrackingType",
					args = {
						tracker_1 = {
							type = "select",
							name = L["MODESELECT_NAME"] .. "1",
							order = 1,
							values = "ACE_GetTrackingModeValues",
							arg = "1",
						},
						tracker_2 = {
							type = "select",
							name = L["MODESELECT_NAME"] .. "2",
							order = 2,
							values = "ACE_GetTrackingModeValues",
							arg = "2",
						},
					},
				},
			}
		},
		check_condition = {
			order = 100,
			name = "verify condition",
			type = "input",
			set = "debug_checkcondition",
			get = false,
			hidden = true,
		},
		toggledebug = {
			order = 101,
			name = "toggle debug",
			type = "execute",
			hidden = true,
			func = function()
				if bDebugMode then
					bDebugMode = false
					DisableDebugPrint();
				else
					bDebugMode = true
					EnableDebugPrint();
				end
			end,
		},
		options = {
		-- silent alias for "config" command
			order = 102,
			name = "options_alias",
			type = "execute",
			func = function()
				if ace_config_dlg.OpenFrames[ADDON_TAG] then
					ace_config_dlg:Close(ADDON_TAG)
				else
					ace_config_dlg:Open(ADDON_TAG)
				end
			end,
			hidden = true,
		},
		-- silent aliases for toggle command
		--[[
		disable = {
			order = 103,
			name = "toggle_disable",
			type = "toggle",
			set = function()
		--]]
	},
}


--[[================================================================================
	ACE methods
	============================================================================--]]
function TrackingPlus:OnInitialize()
	-- register options; this will register the options table with both AceConfigRegistry & AceConfigCmd
	ace_config:RegisterOptionsTable(ADDON_TAG, TP_ACE_OPTS, {"trackingplus","tplus"})
	
	-- add the main options page for this addon to the blizzard interface menu, under the addons tab
	self.optionsFrames = {}
	self.optionsFrames.Main = ace_config_dlg:AddToBlizOptions(ADDON_TAG, L["ADDON_NAME"])
	self.config_dlg = ace_config_dlg
	
	-- Database
	local defaults = {
		profile = {
			TrackingCyclerEnabled = true,
			TrackingModeCycle = { 1, 2 },
			MaxModesInCycle = 2,
			TrackingCyclePeriod = 3,
			Suspend_InCities = true,
			Suspend_InInstances = false,
			Suspend_UsingTaxi = false,
			Suspend_Fishing = false,
			Suspend_InCombat = true,
			Suspend_TradeskillUI = false,
			Suspend_SocketingUI = false,
			Suspend_AuctionUI = false,
			Suspend_TradeUI = true,
			Suspend_Unflying = false,
			Suspend_Unmounted = false,			
		},
	}
	
	-- create proxy for interacting with persistent data
	self.db = LibStub("AceDB-3.0"):New(ADDON_TAG .. "DB", defaults, true)
	self:RegisterProfileCallbacks()

	ace_config:RegisterOptionsTable(ADDON_TAG .. "-Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))
	self:RebuildTrackingModeSelectionPage()
	
	-- this adds the "Profiles" entry as a child of the main addon options panel
	self.optionsFrames.Profiles = ace_config_dlg:AddToBlizOptions(ADDON_TAG .. "-Profiles", L["PROFILES"], L["ADDON_NAME"])
end

function TrackingPlus:OnEnable()
--	t_print("TrackingPlus:OnEnable - cycleTimer:" .. tostring(self.cycleTimer))
	self:UpdateWidgetRanges();
	self:RegisterEvents();
	self:RegisterHooks();
	
	-- schedule repeating timer
	self:RefreshCycleTimer()
end

function TrackingPlus:OnDisable()
--	t_print("TrackingPlus:OnDisable - cycleTimer:" .. tostring(self.cycleTimer))
	self:CancelAllTimers()
	self:UnregisterAll()
end

--[[================================================================================
	Profile functions
	============================================================================--]]

-- Fires when a new profile is created, usually used to apply custom defaults that cannot be handled through AceDB.
function TrackingPlus:OnNewProfile(db, profile)
end

-- Fires after changing the profile.
function TrackingPlus:OnProfileChanged(db, newProfile)
	dprint("TrackingPlus:OnProfileChanged - db:" .. tostring(db) .. " newProfile:" .. tostring(newProfile))
	self:RebuildTrackingModeSelectionPage()
	self:RefreshCycleTimer()
end

-- Fires after a profile has been deleted.
function TrackingPlus:OnProfileDeleted(db, profile)
end

-- Fires after a profile has been copied into the current active profile.
function TrackingPlus:OnProfileCopied(db, sourceProfile)
	dprint("TrackingPlus:OnProfileCopied - db:" .. tostring(db) .. " Profile:" .. tostring(db.profile) .. "  sourceProfile:" .. tostring(sourceProfile))
	self:RebuildTrackingModeSelectionPage()
	self:RefreshCycleTimer()
end

-- Fires after the current profile has been reset.
function TrackingPlus:OnProfileReset(db)
	--self.Print("TrackingPlus:OnProfileReset - db:" .. tostring(db) .. " Profile:" .. tostring(db.profile))
	self:RebuildTrackingModeSelectionPage()
	self:RefreshCycleTimer()
end

-- Fires after the whole database has been reset. (Note: OnProfileReset will fire as well)
function TrackingPlus:OnDatabaseReset(db)
end

-- Fires before changing the profile.
function TrackingPlus:OnProfileShutdown(db)
end

-- Fires when logging out, just before the database is about to be cleaned of all AceDB metadata.
function TrackingPlus:OnDatabaseShutdown(db)
end

--[[================================================================================
	Event Handlers
	============================================================================--]]
-- Handler for PLAYER_ENTERING_WORLD event
function TrackingPlus:OnPlayerEnteringWorld()
--	t_print("TrackingPlus:OnPlayerEnteringWorld - current value of tracking var:" .. tostring(playerEnteredWorldCalled) .. "   timer handle:" .. tostring(self.cycleTimer))
	playerEnteredWorldCalled = true
	self:SynchronizeCycleConditions();
end

-- Handler for ZONE_CHANGED & ZONE_CHANGED_NEW_AREA event
function TrackingPlus:OnZoneChanged()
	self:TriggerZoneUpdateTimer()
end

--- Handler for the PLAYER_EQUIPMENT_CHANGED event.
--- Receives a notification that one or more of the player's equipped items has changed.
--
-- @paramsig	string, int, int
--
-- @param	event				the name of the event that is being handled (in this case, PLAYER_EQUIPMENT_CHANGED)
-- @param	itemSlot			numeric identifier corresponding to the equipment slot that was updated
--								(@see http://www.wowwiki.com/InventorySlots)
-- @param	isEquippingItem		as far as I can tell, this is 1 when an item is being equipped or swapped, 0 if the item is simply removed
function TrackingPlus:OnPlayerEquipmentChanged(event, itemSlot, isEquippingItem)
	-- we only care if the slot that changed corresponds to the main-hand weapon
	if not cachedMainHandSlotId then
		cachedMainHandSlotId = GetInventorySlotInfo("MainHandSlot");
	end
	if itemSlot == cachedMainHandSlotId then
		self:UpdatePlayerFishingStatus()
	end
end

--[[================================================================================
	Minimap Button
	============================================================================--]]
function MiniMapTrackingPlusDropDown_OnLoad(contextmenu_frame)
	TP.MinimapTrackingButtonDropDown = contextmenu_frame
end

-- Wrapper for calling the set function for "suspend cycle" options; signature needed
-- by ACE and the UIDropDown* code is slightly different, so this function reformats the
-- parameters into something that is consumable by the ACE-friendly setter
-- up 
-- @paramsig	frame, string, func, bool
function CycleSwitchMenuItemWrapper(menu_button, setting_id, setter, current_value)
	if menu_button and setter and type(setter) == "function" then
		setter(menu_button, current_value)
		NotifyOptionChanged()
	end
end

-- Simple helper for adding a 
function UIDropDownMenu_AddSeparator(showEmptyLine, width)
	local info = UIDropDownMenu_CreateInfo()
	info.isTitle = true
	info.text = ""

	if not showEmptyLine then
		if not width or width < 0 then
			width = 15
		end	
		for i=1,width do
			info.text = info.text .. "-"
		end
	end
	UIDropDownMenu_AddButton(info)
end

-- Wrapper for appending a new context menu item; allows easily adding a separator line following the item
local function AddDropDownMenuItem(info, separator)
	UIDropDownMenu_AddButton(info)
	if separator then
		UIDropDownMenu_AddSeparator(true)
	end
end

-- Populates the context menu with options and short-cuts for this addon that are of interest to the user
function MiniMapTrackingPlusDropDown_PopulateMenuItems( contextmenu_frame, level, info_table )
	-- no need to worry about memory churn becauses UIDropDownMenu_CreateInfo handles that for us
	-- overall toggle
	local info  = UIDropDownMenu_CreateInfo()
	info.text = TP_ACE_OPTS.args.toggle.name
	info.tooltipTitle = TP_ACE_OPTS.args.toggle.name
	info.tooltipText = TP_ACE_OPTS.args.toggle.desc
	info.checked = TrackingPlus.MiniMapDropDown_IsTrackingCyclerEnabled
	info.func = TrackingPlus.MiniMapDropDown_SetTrackingCyclerEnabled
	AddDropDownMenuItem(info)
	
	-- easily open options page
	info = UIDropDownMenu_CreateInfo()
	info.text = TP_ACE_OPTS.args.config.name .. "..."	-- use ... to indicate that clicking will open a dialog
	info.tooltipTitle = TP_ACE_OPTS.args.config.name
	info.tooltipText = TP_ACE_OPTS.args.config.desc
	info.func = TP_ACE_OPTS.args.options.func
	AddDropDownMenuItem(info, true)
	
	for id, option in pairs(TP_ACE_OPTS.args.switches.args) do
		info = UIDropDownMenu_CreateInfo()
		info.text = option.name
		info.tooltipTitle = option.name
		info.tooltipText = option.desc
		info.checked = not option.disabled and option.get
		info.func = CycleSwitchMenuItemWrapper
			info.arg1 = id
			info.arg2 = option.set
		info.disabled = option.disabled
		info.keepShownOnClick = true
		AddDropDownMenuItem(info)
	end
end

function TrackingPlus:OnMinimapTrackingButtonClicked(sourceWidget, buttonName, isDown)	
	-- Call the original function if the user didn't click the right-mouse-button
	if buttonName ~= "RightButton" or isDown then
		self.hooks[sourceWidget].OnClick(sourceWidget, buttonName, isDown)
	else
		-- display our context menu
		ToggleDropDownMenu(1, nil, MiniMapTrackingPlusDropDown, "MiniMapTracking", 0, -5);
		PlaySound("igMainMenuOptionCheckBoxOn");
	end
end


--[[================================================================================
	Utility / general use
	============================================================================--]]
	
function TrackingPlus:RegisterProfileCallbacks()
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileCopied")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
	
	-- might not need these
	--[[
	self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
	self.db.RegisterCallback(self, "OnDatabaseReset", "OnDatabaseReset")
	self.db.RegisterCallback(self, "OnProfileDeleted", "OnProfileDeleted")
	self.db.RegisterCallback(self, "OnProfileShutdown", "OnProfileShutdown")
	self.db.RegisterCallback(self, "OnDatabaseShutdown", "OnDatabaseShutdown")	
	--]]
end

function TrackingPlus:RegisterEvents()
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnteringWorld")
	-- fishing
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "OnPlayerEquipmentChanged")
	-- in city or instance
	self:RegisterEvent("ZONE_CHANGED", "OnZoneChanged")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChanged")

	-- looting
	self.RegisterEvent(TP.TP_STATE_TABLE.Looting, "LOOT_OPENED", "OnActivate")
	self.RegisterEvent(TP.TP_STATE_TABLE.Looting, "LOOT_CLOSED", "OnDeactivate")
	-- tradeskill UI
--	self.RegisterEvent(TP.TP_STATE_TABLE.TradeskillUI, "TRADE_SKILL_SHOW", "OnActivate" )
--	self.RegisterEvent(TP.TP_STATE_TABLE.TradeskillUI, "TRADE_SKILL_CLOSE", "OnDeactivate")
	-- trade open
	self.RegisterEvent(TP.TP_STATE_TABLE.TradeUI, "TRADE_CLOSED", "OnDeactivate")
	-- item socketing UI
	self.RegisterEvent(TP.TP_STATE_TABLE.SocketInfoUI, "SOCKET_INFO_UPDATE", "OnActivate")
	self.RegisterEvent(TP.TP_STATE_TABLE.SocketInfoUI, "SOCKET_INFO_CLOSE", "OnDeactivate")
	-- auction house UI
--	self.RegisterEvent(TP.TP_STATE_TABLE.AuctionUI, "AUCTION_HOUSE_SHOW", "OnActivate")
--	self.RegisterEvent(TP.TP_STATE_TABLE.AuctionUI, "AUCTION_HOUSE_CLOSED", "OnDeactivate")
	-- combat
	self.RegisterEvent(TP.TP_STATE_TABLE.Combat, "PLAYER_REGEN_DISABLED", "OnActivate")
	self.RegisterEvent(TP.TP_STATE_TABLE.Combat, "PLAYER_REGEN_ENABLED", "OnDeactivate")

--@todo	
--	self.RegisterEvent("??TAXI_OPENED", "OnBeginTaxi")
--	self.RegisterEvent("??TAXI_ENDED", "OnFinishTaxi")
end

function TrackingPlus:UnregisterAll()
	self:UnhookAll()
	
	self.UnregisterEvent(TP.TP_STATE_TABLE.Looting, "LOOT_OPENED")
	self.UnregisterEvent(TP.TP_STATE_TABLE.Looting, "LOOT_CLOSED")

--	self.UnregisterEvent(TP.TP_STATE_TABLE.TradeskillUI,"TRADE_SKILL_SHOW")
--	self.UnregisterEvent(TP.TP_STATE_TABLE.TradeskillUI,"TRADE_SKILL_CLOSE")

	self.UnregisterEvent(TP.TP_STATE_TABLE.TradeUI,"TRADE_CLOSED")

	self.UnregisterEvent(TP.TP_STATE_TABLE.SocketInfoUI, "SOCKET_INFO_UPDATE")
	self.UnregisterEvent(TP.TP_STATE_TABLE.SocketInfoUI, "SOCKET_INFO_CLOSE")

--	self.UnregisterEvent(TP.TP_STATE_TABLE.AuctionUI, "AUCTION_HOUSE_SHOW")
--	self.UnregisterEvent(TP.TP_STATE_TABLE.AuctionUI, "AUCTION_HOUSE_CLOSED")

	self.UnregisterEvent(self, "PLAYER_EQUIPMENT_CHANGED")

	self.UnregisterEvent(TP.TP_STATE_TABLE.Combat, "PLAYER_REGEN_DISABLED")
	self.UnregisterEvent(TP.TP_STATE_TABLE.Combat, "PLAYER_REGEN_ENABLED")

	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:UnregisterEvent("ZONE_CHANGED")
	self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
end

function TrackingPlus:RegisterHooks()
	self:HookMinimapButton()
end

-- Enable right-clicking the minimap tracking button, and set that input to cause our context menu to appear
function TrackingPlus:HookMinimapButton()
	-- by default, the tracking button's OnClick event is only triggered by left mouse button.
	-- (I wish there was a way to determine which input buttons the widget is currently registered for)
	MiniMapTrackingButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	self:RawHookScript(MiniMapTrackingButton, "OnClick", "OnMinimapTrackingButtonClicked")
	
	-- populate the dropdown's list of options
	UIDropDownMenu_Initialize(TP.MinimapTrackingButtonDropDown, MiniMapTrackingPlusDropDown_PopulateMenuItems, "MENU");
end


-- Sets appropriate limits on all settings widgets
function TrackingPlus:UpdateWidgetRanges()
	-- update the "number of tracking modes to cycle" slider with the actual maximum number of tracking modes available
	local max_available_tracking_modes = GetNumTrackingTypes();
	TP_ACE_OPTS.args.tracker_selection.args.trackercount.max = max_available_tracking_modes;
	
	--@todo more?
end

local function IsTrackingOnCooldown()
	local isGCDActive = false
	-- more restrictive than required; some tracking types (racials, class abilities vs gathering, etc. have seperate cooldowns)	
	for i = 1, GetNumTrackingTypes() do
		local tracking_spell_name=GetTrackingInfo(i)
		local cdStart, cdDuration, spellIsActive = GetSpellCooldown(tracking_spell_name)
		if cdStart and cdStart ~= 0 and spellIsActive then
			isGCDActive = true
			break
		end
	end
	
	return isGCDActive
end

--[[================================================================================
	Player state switches / conditionals
	============================================================================--]]

do
	local tbl = {
		IsActiveStateReversed=false
	}
	function tbl:IsActiveState()
		return self.IsActive;
	end
	function tbl:OnActivate()
--t_printf("OnActivate setting value of IsActive to TRUE (current value:%s) - [%s]", tostring(self.IsActive), tostring(self))
		self.IsActive = true;
	end
	function tbl:OnDeactivate()
--t_printf("OnDeactivate setting value of IsActive to FALSE (current value:%s) - [%s]", tostring(self.IsActive), tostring(self))
		self.IsActive = false
	end
	function tbl:IsEnabled()
		return true
	end
	function tbl:AllowsCycling()
		return (not self:IsEnabled()) or (not self:IsActiveState() and not self.IsActiveStateReversed) or (self:IsActiveState() and self.IsActiveStateReversed)
	end
	
	function CreateEventHandlerTable(IsEnabled_Override, IsActiveState_Override, IsActiveState_Reversed)
		return {
			IsActive = false,
			IsActiveStateReversed=IsActiveState_Reversed==true,
			IsActiveState = IsActiveState_Override or tbl.IsActiveState,
			OnActivate = tbl.OnActivate,
			OnDeactivate = tbl.OnDeactivate,
			-- this function is what's used to determine if this state should be considered at all when deciding whether tracker cycling is allowed
			IsEnabled = IsEnabled_Override or tbl.IsEnabled,
			AllowsCycling = tbl.AllowsCycling,
		}
	end
	
	TP.TP_STATE_TABLE = {
		Looting			= CreateEventHandlerTable(),
		Fishing			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_fishing.get),
		TradeskillUI	= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_tradeskill.get),
		TradeUI			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_trade.get),
		SocketInfoUI	= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_socketing.get),
		AuctionUI		= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_auction.get),
		Combat			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_combat.get, InCombatLockdown),
		City			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_cities.get),
		Instance		= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_instances.get),
		Taxi			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_cycle_taxies.get),
		Mounted			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_unmounted.get,IsMounted,true),
		Flying			= CreateEventHandlerTable(TP_ACE_OPTS.args.switches.args.suspend_unflying.get,IsFlying,true),
	}
end

-- determines if tracking mode cycling is currently allowed, player not dead, not in combat, etc.
local function IsAllowedToCycleTracking()
	local isAllowed = true
	if not playerEnteredWorldCalled then
		-- player hasn't entered world yet, not guaranteed to have all information required
		isAllowed = false
	elseif UnitIsDeadOrGhost("player") then
		isAllowed = false
	elseif UnitIsAFK("player") then
		isAllowed = false
	elseif UnitCastingInfo("player") then
		isAllowed = false
	elseif UnitChannelInfo("player") then
		isAllowed = false
	elseif IsTrackingOnCooldown() then
		isAllowed = false
	else -- state-dependent checks
					-- not looting or allow cycling while looting, etc.
		isAllowed = TP.TP_STATE_TABLE.Looting:AllowsCycling() and
					TP.TP_STATE_TABLE.TradeskillUI:AllowsCycling() and
					TP.TP_STATE_TABLE.TradeUI:AllowsCycling() and
					TP.TP_STATE_TABLE.SocketInfoUI:AllowsCycling() and
					TP.TP_STATE_TABLE.AuctionUI:AllowsCycling() and
					TP.TP_STATE_TABLE.Fishing:AllowsCycling() and
					TP.TP_STATE_TABLE.Combat:AllowsCycling() and
					TP.TP_STATE_TABLE.City:AllowsCycling() and
					TP.TP_STATE_TABLE.Instance:AllowsCycling() and
					TP.TP_STATE_TABLE.Taxi:AllowsCycling() and
					TP.TP_STATE_TABLE.Mounted:AllowsCycling() and
					TP.TP_STATE_TABLE.Flying:AllowsCycling();
	end
	return isAllowed
end

-- this method is called something has occurred which might result in the rules for whether or not to cycle to no longer be valid
function TrackingPlus:SynchronizeCycleConditions()
dprint("=======  TrackingPlus:SynchronizeCycleConditions()  ========")
	-- assume that any events which would have triggered our tracking methods were bypassed, and manually update each switch with the appropriate value
	
	-- city & instance
	self:TriggerZoneUpdateTimer()
	
	-- taxi
	
	-- fishing
	self:UpdatePlayerFishingStatus()
	
	-- combat
	-- not necessary; this is checked each time the addon attempts to switch the tracking mode, anyway
	
	-- tradeskill UI
	
	-- trading UI
	
	-- item socketing UI
	self:UpdateSocketItemStatus();
	
	-- auction house UI
end

function TrackingPlus:IsPlayerInCityZone()
	local isPlayerinCity = false
	
	local strZone, strRealZone, strSubZone = GetZoneText(), GetRealZoneText(), GetSubZoneText()
	for i = 1, #CityZoneText do
		local strCity = LBZ[CityZoneText[i]]
		
		-- some cities only appear as a subzone (e.g. Gadgetzan)
		if strCity == strZone or strCity == strRealZone or strCity == strSubZone then
			-- we are in a city
			isPlayerinCity = true
			break
		end
	end
	
--t_printf([[TrackingPlus:IsPlayerInCityZone - strZone:"%s"  strRealZone:"%s"  strSubZone:"%s"  #CityZoneText:%i   isPlayerinCity:%s   isCitySwitchActive:%s]],
--	tostring(strZone), tostring(strRealZone), tostring(strSubZone), #CityZoneText, tostring(isPlayerinCity), tostring(TP.TP_STATE_TABLE.City:IsActiveState()))
	return isPlayerinCity;
end

function TrackingPlus:IsPlayerInInstanceZone()
	local playerInInstance = false
	
	local strZone, strRealZone = GetZoneText(), GetRealZoneText()
	for continent, instanceTable in pairs(InstanceZoneText) do
		for i = 1, #instanceTable do
			local strInstance = LBZ[instanceTable[i]]
			if strInstance == strZone or strInstance == strRealZone then
				playerInInstance = true
				break;
			end
		end
		if playerInInstance then
			break
		end
	end
	
--t_printf([[TrackingPlus:IsPlayerInInstanceZone - strZone:"%s"  strRealZone:"%s"  #InstanceZoneText:%i   playerInInstance:%s   isInstanceSwitchActive:%s]],
--	tostring(strZone), tostring(strRealZone), #InstanceZoneText, tostring(playerInInstance), tostring(TP.TP_STATE_TABLE.Instance:IsActiveState()))
	return playerInInstance;
end

function TrackingPlus:UpdateCityStatus()
	local playerInCity = self:IsPlayerInCityZone()
	local isCitySwitchActive = TP.TP_STATE_TABLE.City:IsActiveState()
	if playerInCity then
		-- if the player is in a city but the "City" switch isn't in the activate state, activate it
		-- this can happen when the player logs in while in a city, perhaps (dunno if we get the zone changed event there)
		if not isCitySwitchActive then
			TP.TP_STATE_TABLE.City:OnActivate()
		end
	elseif isCitySwitchActive then
		-- otherwise, deactivate the "City" switch
		TP.TP_STATE_TABLE.City:OnDeactivate()
	end
end

function TrackingPlus:UpdateInstanceStatus()
	local playerInInstance = self:IsPlayerInInstanceZone()
	local isInstanceSwitchActive = TP.TP_STATE_TABLE.Instance:IsActiveState()
	if playerInInstance then
		if not isInstanceSwitchActive then
			TP.TP_STATE_TABLE.Instance:OnActivate()
		end
	elseif isInstanceSwitchActive then
		TP.TP_STATE_TABLE.Instance:OnDeactivate()
	end
end

function TrackingPlus:UpdateTaxiStatus()
end

function TrackingPlus:UpdateTradeskillUIStatus()
end

function TrackingPlus:UpdateTradeUIStatus()
end


function TrackingPlus:UpdatePlayerFishingStatus()
	-- too bad we can't simply slap IsEquippedItemType in as the IsActiveState_Override for fishing....but (at least for now), I don't have a clean way to assign the IsActiveState handler 
	-- in a way that allows me to also include a parameter value to pass.
	local hasFishingPoleEquipped = IsEquippedItemType("Fishing Poles");
	local isFishingSwitchActive = TP.TP_STATE_TABLE.Fishing:IsActiveState();

	if hasFishingPoleEquipped then
		-- if the player has a fishing pole equipped, and the "Fishing" switch isn't currently in the activated
		-- state, activate it
		if not isFishingSwitchActive then
			TP.TP_STATE_TABLE.Fishing:OnActivate()
		end
		
	elseif isFishingSwitchActive then
		-- otherwise, deactivate the "Fishing" switch, if necessary
		TP.TP_STATE_TABLE.Fishing:OnDeactivate()
	end
end

function TrackingPlus:UpdateSocketItemStatus()
	local socketingItemName = GetSocketItemInfo()
	local isSocketingUIOpen = socketingItemName ~= nil;
	local isSocketUISwitchActive = TP.TP_STATE_TABLE.SocketInfoUI:IsActiveState();
	
	if isSocketingUIOpen then
		-- socket item UI is open
		if not isSocketUISwitchActive then
			-- so make sure we stay in sync with its state
			TP.TP_STATE_TABLE.SocketInfoUI:OnActivate()
		end
	elseif isSocketUISwitchActive then
		-- socket item UI is no longer open but we still have it flagged as such
		TP.TP_STATE_TABLE.SocketInfoUI:OnDeactivate()
	end
end


function TrackingPlus:debug_checkcondition(info, val)
	local lstr_ConditionName = strlower(val)
	if lstr_ConditionName == "looting" then
		self.Print(strformat("Looting Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.Looting:IsEnabled()), tostring(TP.TP_STATE_TABLE.Looting:IsActiveState())))
	elseif lstr_ConditionName == "tradeskill" then
		self.Print(strformat("TradeskillUI Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.TradeskillUI:IsEnabled()), tostring(TP.TP_STATE_TABLE.TradeskillUI:IsActiveState())))
	elseif lstr_ConditionName == "trade" then
		self.Print(strformat("TradeUI Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.TradeUI:IsEnabled()), tostring(TP.TP_STATE_TABLE.TradeUI:IsActiveState())))
	elseif lstr_ConditionName == "socketinfo" then
		self.Print(strformat("SocketItemUI Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.SocketInfoUI:IsEnabled()), tostring(TP.TP_STATE_TABLE.SocketInfoUI:IsActiveState())))
	elseif lstr_ConditionName == "auction" then
		self.Print(strformat("AuctionUI Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.AuctionUI:IsEnabled()), tostring(TP.TP_STATE_TABLE.AuctionUI:IsActiveState())))
	elseif lstr_ConditionName == "fishing" then
		self.Print(strformat("Fishing Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.Fishing:IsEnabled()), tostring(TP.TP_STATE_TABLE.Fishing:IsActiveState())))
	elseif lstr_ConditionName == "combat" then
		self.Print(strformat("Combat Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.Combat.IsEnabled()), tostring(TP.TP_STATE_TABLE.Combat:IsActiveState())))
	elseif lstr_ConditionName == "city" then
		self.Print(strformat("City Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.City.IsEnabled()), tostring(TP.TP_STATE_TABLE.City:IsActiveState())))
	elseif lstr_ConditionName == "instance" then
		self.Print(strformat("Instance Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.Instance.IsEnabled()), tostring(TP.TP_STATE_TABLE.Instance:IsActiveState())))
	elseif lstr_ConditionName == "taxi" then
		self.Print(strformat("Taxi Restriction - IsEnabled:%s,  IsActive:%s", tostring(TP.TP_STATE_TABLE.Taxi.IsEnabled()), tostring(TP.TP_STATE_TABLE.Taxi:IsActiveState())))
	else
		self.Print(strformat([[Unknown condition specified for 'check_condition' command "%s".  Valid values are:]], val));
		self.Print("  looting")
		self.Print("  tradeskill")
		self.Print("  trade")
		self.Print("  socketinfo")
		self.Print("  auction")
		self.Print("  fishing")
		self.Print("  combat")
		self.Print("  city")
		self.Print("  taxi")
		self.Print("")
	end
	
end

-- until I figure out a way to easily (and reliably) determine the length of a table that contains non-numeric keys,
-- use this.......this feels so dirty...
local function GetTableLength(target_table)
	local tablecount = 0
	for _,_ in pairs(target_table) do
		tablecount = tablecount + 1
	end
	return tablecount
end

--[[================================================================================
	Backend for UI hooks
	============================================================================--]]
local function SetTrackingCyclerEnabled(addon,value)
	local shouldRefresh = value ~= addon.db.profile.TrackingCyclerEnabled
	
	addon.db.profile.TrackingCyclerEnabled = value and value == true
	if value and value == true then
		addon.Print(L["ADDON_ENABLED"])
	else
		addon.Print(L["ADDON_DISABLED"])
	end
	addon:RefreshCycleTimer()
	
	return shouldRefresh
end

local function IsTrackingModeCyclingEnabled(addon)
	return addon.db.profile.TrackingCyclerEnabled
end

local function SetWatchedTrackerCount(addon,newCount)
	local shouldRefresh = not addon.db.profile.MaxModesInCycle or addon.db.profile.MaxModesInCycle ~= newCount
	addon.db.profile.MaxModesInCycle = newCount;
	return shouldRefresh
end
	
-- return the number of tracking modes the user wishes to cycle through
local function GetWatchedTrackerCount(addon)
	return addon.db.profile.MaxModesInCycle
end

-- sets the number of seconds to wait before switching to the next tracking mode
local function SetTrackingCyclePeriod(addon, value)
	local shouldRefresh = false
	if value and value > 0 then
		shouldRefresh = addon.db.profile.TrackingCyclePeriod ~= value
		addon.db.profile.TrackingCyclePeriod = value;
	end
	return shouldRefresh
end

-- return the value for the number of seconds to wait before switching to the next tracking mode
local function GetTrackingCyclePeriod(addon)
	return addon.db.profile.TrackingCyclePeriod
end

-- sets the tracking mode to use at a specific position in the cycle
local function SetTrackingModeInCycle(addon,position,tracking_mode)
	--@todo error msg
	if type(position) ~= "number" or position < 1 or position > GetTableLength(addon.db.profile.TrackingModeCycle) + 1 then return nil end
	
	local shouldRefresh = addon.db.profile.TrackingModeCycle[position] ~= tracking_mode
	--@todo verify the value doesn't correspond to an invalid tracking mode
	--@todo change the way this value is stored so that it isn't completely fucked up if the user learns a new profession or something
	
	addon.db.profile.TrackingModeCycle[position] = tracking_mode
	return shouldRefresh
end

-- return the tracking mode that is at the specified position in the rotation
local function GetTrackingModeFromCycle(addon,position)
	dprint("GetTrackingModeFromCycle - position:"..position .."  type:"..type(position) ..
		"  profile cycle length:"..GetTableLength(addon.db.profile.TrackingModeCycle)..
		"  UI cycle length:" .. GetTableLength(TP_ACE_OPTS.args.tracker_selection.args.trackingtypes.args))
	--@todo error msg
	if	type(position) ~= "number" or position < 1 or
		position > GetTableLength(addon.db.profile.TrackingModeCycle) or
		position > GetTableLength(TP_ACE_OPTS.args.tracker_selection.args.trackingtypes.args) then
		return nil
	end
	return addon.db.profile.TrackingModeCycle[position]
end

local function RebuildTrackingChoiceControlsList(addon)
	local available_tracker_types = GetNumTrackingTypes()

	-- check to see how many tracking types the user wants to cycle through
	local desired_watched_trackers = GetWatchedTrackerCount(addon)
	
	-- this needs to be enforced by the UI, but here too in case the config file is hacked manually
	if desired_watched_trackers > available_tracker_types then
		desired_watched_trackers = available_tracker_types
	end
	
	-- cannot have less than 2
	if desired_watched_trackers < 2 then desired_watched_trackers = 2 end

	-- remove all existing drop down menus
	TP_ACE_OPTS.args.tracker_selection.args.trackingtypes.args = {}
	
	-- then create a drop down menu for the number of requested tracking types
	local current_watched_tracker_count = 0
	while current_watched_tracker_count < desired_watched_trackers do
		current_watched_tracker_count = current_watched_tracker_count + 1
		local widget_name = "tracker_" .. current_watched_tracker_count;
		
		TP_ACE_OPTS.args.tracker_selection.args.trackingtypes.args[widget_name] = {
			type = "select",
			name = L["MODESELECT_NAME"] .. tostring(current_watched_tracker_count),
			order = current_watched_tracker_count,
			arg = tostring(current_watched_tracker_count),
			values = "ACE_GetTrackingModeValues",
		}
		
		local configured_tracking_mode = GetTrackingModeFromCycle(addon,current_watched_tracker_count)
		if not configured_tracking_mode then
			-- if we don't have a tracking mode configured for this spot in the rotation, it [should] mean
			-- that this spot was just added to the cycle - so use the default tracking mode
			SetTrackingModeInCycle(addon, current_watched_tracker_count, 1)
		end
	end
	
	
	-- @todo vv
	-- repopulate each combo with ALL of the available tracking types (so that we get the same behavior
	-- when the user makes a change as we do when we select the previously chosen tracking types, with
	-- regards to what happens to that tracking type in the other drop down's lists)
	
	-- for each tracking type the user has chosen to cycle through, go to the next drop-down in the
	-- list, and set the index of the drop-down to that list item.  then go through all other drop-downs
	-- and remove that item from the list (maybe - it might make more sense to do all this with tables
	-- first, then just apply them to the lists, to avoid all the UI code overhead)

	
	dprint("RebuildTrackingChoiceControlsList created " .. desired_watched_trackers ..
			" new entries: " .. current_watched_tracker_count .. "  widget table length:" .. GetTableLength(TP_ACE_OPTS.args.tracker_selection.args.trackingtypes.args))
end

-- return the tracking modes that should populate a particular dropdown
local function PopulateTrackingTypes(addon,widget)
	local tracking_modes = {}
	
	local tracking_mode_count = GetNumTrackingTypes()
	for i = 1, tracking_mode_count do
		tracking_modes[i] = GetTrackingInfo(i)
	end
	
	return tracking_modes
end


function TrackingPlus:RebuildTrackingModeSelectionPage()
	RebuildTrackingChoiceControlsList(self)
end


function TrackingPlus:TriggerZoneUpdateTimer()
	if not self.zoneUpdateTimerHandle or not self:TimeLeft(self.zoneUpdateTimerHandle) then
		self.zoneUpdateTimerHandle = self:ScheduleTimer("OnTimer_VerifyZoneSwitchStates", 5)
	end
end

function TrackingPlus:RefreshCycleTimer()
	dprint("TrackingPlus:RefreshCycleTimer - self.cycleTimer:" .. tostring(self.cycleTimer))
	if self.cycleTimer then
		self:CancelTimer(self.cycleTimer)
	end
	
	-- clear the timer
	self.cycleTimer = nil
	
	if IsTrackingModeCyclingEnabled(self) then
		self:SynchronizeCycleConditions();

		local cyclePeriod = GetTrackingCyclePeriod(self)
		self.cycleTimer = self:ScheduleRepeatingTimer("OnTimer_NextTrackingMode", cyclePeriod)
	end
end

--[[================================================================================
	Options handlers
	============================================================================--]]
-- ACE wrapper for method which opens the standard blizzard add-on config page and attempts to bring our options into view
function TrackingPlus:ACE_ToggleTrackingCyclerConfig()
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Profiles)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrames.Main)
end

-- ACE wrappers for getting & setting the value that controls whether tracking mode cycling is enabled
function TrackingPlus:ACE_IsTrackingCyclerEnabled(info)
	return IsTrackingModeCyclingEnabled(self)
end
function TrackingPlus:ACE_ToggleTrackingCycler(info, input)
	SetTrackingCyclerEnabled(self, input)
end

-- Context menu wrappers for getting & setting the value that controls whether tracking mode cycling is enabled
function TrackingPlus.MiniMapDropDown_IsTrackingCyclerEnabled()
	return IsTrackingModeCyclingEnabled(TP)
end
function TrackingPlus.MiniMapDropDown_SetTrackingCyclerEnabled(menu_button, arg1, arg2, current_value)
--t_printf("TrackingPlus.MiniMapDropDown_SetTrackingCyclerEnabled - arg1:%s[%s] arg2:%s[%s] value:%s[%s]",
--	tostring(arg1), type(arg1), tostring(arg2), type(arg2), tostring(current_value), type(current_value))
	
	--HACK: it seems to me that the blizzard code that calls this function (UIDropDownMenuButton_OnClick) is kind of busted
	-- right now (v3.3.3), assuming I'm not missing something somewhere (and i'm pretty sure i'm not)
	-- if the dropdown menu item has "false" for its keepShownOnClick field, then the logic in UIDropDownMenuButton_OnClick
	-- calls this "setter" function with the current value of whatever setting is hooked to this menu item.  However, if 
	-- the keepShownOnClick field is true for this menu item, then UIDropDownMenuButton_OnClick calls the setter function
	-- with the opposite value (i.e. passes true if current value is false, v/v), which seems to be the desired behavior
	-- anyway, the following line will flip the value
	local new_value = current_value == false
	if SetTrackingCyclerEnabled(TP, new_value) then
		NotifyOptionChanged()
	end
end

function TrackingPlus:ACE_SetWatchedTrackerCount(info, input)
	local needsRefresh = SetWatchedTrackerCount(self, input)

	dprint("TrackingPlus:ACE_SetWatchedTrackerCount - firing change notification?  " .. tostring(needsRefresh) )
	if needsRefresh then
		self:RebuildTrackingModeSelectionPage()
	end
end

function TrackingPlus:ACE_GetWatchedTrackerCount(info)
	return GetWatchedTrackerCount(self)
end

function TrackingPlus:ACE_SetTrackingType(info, input)
	local cycle_index = tonumber(info.arg);
	local tracking_mode = input;
	dprint("TrackingPlus:ACE_SetTrackingType - " .. info[#info] .. ", cycle_index:"..cycle_index..", mode:"..tracking_mode)
	SetTrackingModeInCycle(self,cycle_index,tonumber(input))
end

function TrackingPlus:ACE_GetTrackingType(info)
	local cycle_index = tonumber(info.arg)
	local tracking_mode = GetTrackingModeFromCycle(self, cycle_index)
	dprint("TrackingPlus:GetTrackingType - "..info[#info].." ("..info.arg.."), tracking_mode:"..tostring(tracking_mode))
	return tracking_mode
end

-- Ace proxy for base populate method
function TrackingPlus:ACE_GetTrackingModeValues(info)
	return PopulateTrackingTypes(self, info.option)
end

function TrackingPlus:ACE_GetCyclePeriod(info)
	return GetTrackingCyclePeriod(self)
end

function TrackingPlus:ACE_SetCyclePeriod(info, input)
	local shouldRefresh = SetTrackingCyclePeriod(self, input)
	if shouldRefresh then
		self:RefreshCycleTimer()
	end
end

--[[================================================================================
	Timers
	============================================================================--]]
function TrackingPlus:OnTimer_VerifyZoneSwitchStates()
	self.zoneUpdateTimerHandle = nil;
	
	self:UpdateCityStatus()
	self:UpdateInstanceStatus()
end

-- handler for the repeating timer; switches the tracking mode to the next in the list
function TrackingPlus:OnTimer_NextTrackingMode()
	dprint("TrackingPlus:OnTimer_NextTrackingMode - playerEnteredWorld:" .. tostring(playerEnteredWorldCalled))
	if IsAllowedToCycleTracking(self) then
		CurrentCyclePosition = CurrentCyclePosition + 1
		
		local newTrackingMode = GetTrackingModeFromCycle(self, CurrentCyclePosition)
		if not newTrackingMode then
			-- nil result means we are currently tracking the last mode in the list - start back at 0
			CurrentCyclePosition = 1
			newTrackingMode = GetTrackingModeFromCycle(self, CurrentCyclePosition)
		end
		dprint("   >>  newTrackingMode:" .. tostring(newTrackingMode))
		if newTrackingMode then
			SetTracking(newTrackingMode)
		end
	end
end

-- handler for options refresh requests; on a timer in order to eliminate potential [future] cases where several updates are
-- being performed in a single frame
function TrackingPlus:OnTimer_NotifyOptionChanged()
	ace_reg:NotifyChange(ADDON_TAG)


--[[
/dump TrackingPlus.config_dlg.OpenFrames.TrackingPlus.type
/dump TrackingPlus.config_dlg.OpenFrames["TrackingPlus"].type
TrackingPlus.config_dlg.OpenFrames.TrackingPlus.children[2].events <-- slider
--]]
end

-- ==================================================================================================
