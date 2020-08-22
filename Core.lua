--[[ Globals ]]--

SLASH_CEPGP1 = "/CEPGP";
SLASH_CEPGP2 = "/cep";

CEPGP_Info = {
	DistTarget =				"",
	Mode =						"guild",	
		
	Active = 					{false, false},	--	Active state, queried for current raid
	Debug =						false,
	ElvUI =						false,
	IgnoreUpdates = 			false,
	ImportingTraffic = 			false,
	Initialised =				false,
	Language =					GetDefaultLanguage("player"),
	OverwriteLog =				false,
	Polling = 					false,
	RecordExists =				false,
	Rescan = 					false,
	SharingTraffic = 			false,
	SyncInProgress = 			false,
	VerboseLogging = 			false,
	VersionNotified = 			false,
		
	LastImport = 				time(),
	LastUpdate = 				GetTime(),
	TrafficScope = 				1,
	
	Attendance =				{
		SelectedSnapshot =		nil,
	},
	Backups =					{
		ConfirmRestore =		false,
	},
	BossEPFrames =				{
		[1] = CEPGP_EP_options_mc,
		[2] = CEPGP_EP_options_bwl,
		[3] = CEPGP_EP_options_zg,
		[4] = CEPGP_EP_options_aq20,
		[5] = CEPGP_EP_options_aq40,
		[6] = CEPGP_EP_options_naxx,
		[7] = CEPGP_EP_options_worldboss
	},
	ClassColours = 				{
		["DRUID"] = 			{	
			r = 1,	
			g = 0.49,	
			b = 0.04,	
			colorStr = "#FF7D0A"
		},	
		["HUNTER"] = 			{	
			r = 0.67,	
			g = 0.83,	
			b = 0.45,	
			colorStr = "#A9D271"
		},	
		["MAGE"] = 				{	
			r = 0.25,	
			g = 0.78,	
			b = 0.92,	
			colorStr = "#40C7EB"
		},	
		["PALADIN"] = 			{	
			r = 0.96,	
			g = 0.55,	
			b = 0.73,	
			colorStr = "#F58CBA"
		},	
		["PRIEST"] = 			{	
			r = 1,	
			g = 1,	
			b = 1,	
			colorStr = "#FFFFFF"
		},	
		["ROGUE"] = 			{	
			r = 1,	
			g = 0.96,	
			b = 0.41,	
			colorStr = "#FFF569"
		},	
		["SHAMAN"] = 			{	
			r = 0,	
			g = 0.44,	
			b = 0.87,	
			colorStr = "#0070DE"
		},	
		["WARLOCK"] = 			{	
			r = 0.53,	
			g = 0.53,	
			b = 0.93,	
			colorStr = "#8787ED"
		},	
		["WARRIOR"] = 			{	
			r = 0.78,	
			g = 0.61,	
			b = 0.43,	
			colorStr = "#C79C6E"
		}	
	},		
	CoreFrames =				{
		[1] = CEPGP_guild,
		[2] = CEPGP_raid,
		[3] = CEPGP_loot,
		[4] = CEPGP_distribute,
		[5] = CEPGP_context_popup
	},
	Guild =						{
		Roster =				{
		},
	},	
	LastRun = 					{
		DistSB =				0,
		GuildSB = 				0,
		LogSB =					0,
		RaidSB = 				0,
		TrafficSB = 			0,
		VersionSB = 			0,
		ItemCall = 				time()
	},
	Logs = 						{
	},
	Loot =						{
		AwardGP =				false,
		Distributing =			false,
		DistributionID =		"",		--	The equippable slot ID (i.e. INVTYPE_HEAD or INVTYPE_LEGS) type: string
		DistEquipSlot =			0,
		GiveWithEPGP =			false,	--	Flags whether an item is being or not
		GUID =					"",
		ItemsTable =			{
		},
		QueuedAnnouncement =	nil,
		QueuedAward = 			nil,
		AwardRate =				1,
		Respondants =			0,
		SlotNum =				0,		-- ID of the slot in the loot table
			
	},	
	LootSchema = 				{
	},	
	MessageStack =				{
	},	
	Override =					{
		ConfirmOverwrite =		false,
	},
	Plugins =					{
	},
	Raid =						{
		Roster =				{
		},
	},
	RosterStack = 				{
	},	
	Sorting = 					{	--	Sorting index, reverse
		Attendance = 			{1, false},
		Guild = 				{4, false},
		Loot = 					{4, false},
		Raid = 					{4, false},
		Standby = 				{1, false},
		Version = 				{1, false},
	},	
	Traffic =					{
		ConfirmClear =			false,
		ImportEntries =			{
			
		},
	},
	Version = 					{
		Number =				"1.12.26",
		Build =					"Alpha 4",
		List =					{
		},
		ListSearch =			"GUILD",
	}
};	

CEPGP = {};

local L = CEPGP_Locale:GetLocale("CEPGP")
local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)

--[[ EVENT AND COMMAND HANDLER ]]--
function CEPGP_OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17)
	
	local function isLootKeyword()
		for i = 1, 4 do
			if string.lower(arg1) == string.lower(CEPGP.Loot.GUI.Buttons[i][4]) then
				return true;
			end
		end
		for _, v in pairs(CEPGP.Loot.ExtraKeywords.Keywords) do
			for key, _ in pairs(v) do
				if string.lower(arg1) == string.lower(key) then
					return true;
				end
			end
		end
		return false;
	end
	
	if event == "ADDON_LOADED" and arg1 == "CEPGP" then --arg1 = addon name
		local success, failMsg = pcall(function()
			CEPGP_initialise();
			CEPGP_initMinimapIcon();
			return;
		end);
		
		C_Timer.After(6, function()
			if not success then
				CEPGP_print("Addon failed to initialise!", true);
				CEPGP_print(failMsg);
			end
		end);
		
	elseif event == "GUILD_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
		CEPGP_rosterUpdate(event);
		return;
	
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		local id, success = arg1, arg2;
		if success then
			CEPGP_updateOverride(id);
		end
		return;
		
	elseif event == "PARTY_LOOT_METHOD_CHANGED" or event == "PLAYER_ROLES_ASSIGNED" then
		if GetLootMethod() == "master" and IsInRaid() and (CEPGP_isML() == 0 or CEPGP_Info.Debug) and not CEPGP_Info.Active[2] then
			_G["CEPGP_confirmation"]:Show();
		else
			_G["CEPGP_confirmation"]:Hide();
		end
		
		if GetLootMethod() ~= "master" or not IsInRaid() or CEPGP_isML() ~= 0 then
			CEPGP_Info.Active[1] = false;
			CEPGP_Info.Active[2] = false;	--	Whenever the loot method, loot master or group type is changed, this will enable the check again
		end
		
		return;
		
	elseif event == "CHAT_MSG_BN_WHISPER" then
		local sender = arg2;
		if not UnitInRaid("player") then return; end
		for i = 1, BNGetNumFriends() do
			local _, accName, _, _, name = BNGetFriendInfo(i);
			local inRaid = false;
			for x = 1, GetNumGroupMembers() do
				if CEPGP_Info.Raid.Roster[x][1] == name then
					inRaid = true;
					break;
				end
			end
			if sender == accName then --Behaves the same way for both Battle Tag and RealID friends
				if string.lower(arg1) == string.lower(CEPGP.Standby.Keyword) then
					if (CEPGP.Standby.Manual and CEPGP.Standby.AcceptWhispers) and
						not CEPGP_tContains(CEPGP.Standby.Roster, name) and not inRaid and CEPGP_Info.Guild.Roster[name] then
						CEPGP_addToStandby(name);
					end
				elseif (isLootKeyword() and CEPGP_Info.Loot.Distributing) or
						(string.lower(arg1) == "!info" or string.lower(arg1) == "!infoguild" or
						string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass") then
						CEPGP_handleComms("CHAT_MSG_WHISPER", arg1, name);
				end
				return;
			end
		end
		return;
	
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == string.lower(CEPGP.Standby.Keyword) and CEPGP.Standby.Manual and CEPGP.Standby.AcceptWhispers then	
		if not CEPGP_tContains(CEPGP.Standby.Roster, arg5)
		and not CEPGP_tContains(CEPGP_Info.Raid.Roster, arg5, true)
		and CEPGP_Info.Guild.Roster[arg5] then
			CEPGP_addToStandby(arg5);
		end
		return;
			
	elseif (event == "CHAT_MSG_WHISPER" and isLootKeyword() and CEPGP_Info.Loot.Distributing) or
		(event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "!info") or
		(event == "CHAT_MSG_WHISPER" and (string.lower(arg1) == "!infoguild" or string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass")) then
			--	arg1 - message | arg5 - sender
			CEPGP_handleComms(event, arg1, arg5);
			return;
	
	elseif (event == "CHAT_MSG_ADDON") or (event == "CHAT_MSG_ADDON_LOGGED") then
		if (arg1 == "CEPGP")then
			local message = arg2;
			local channel = arg3;
			local player = arg5;
			CEPGP_IncAddonMsg(message, arg5, arg3);
		end
		return;
	end
	
	if CEPGP_Info.Active[1] or CEPGP_Info.Debug then --EPGP and loot distribution related 
		--	An encounter has been defeated
		local function handleEncounter(event, arg1, arg5)
			
			if event == "ENCOUNTER_END" and arg5 == 1 then
				local id = tonumber(arg1);
				local name = CEPGP_EncounterInfo.ID[id];
				if name then
					if CEPGP.EP.AutoAward[name] and tonumber(CEPGP.EP.BossEP[name]) > 0 then
						CEPGP_handleCombat(name);
					end
				end
				return;
			end
		end
		
		local success, failMsg = pcall(handleEncounter, event, arg1, arg5);
		
		if not success then
			CEPGP_print("Failed to award GP for encounter!", true);
			CEPGP_print(failMsg, true);
		end
		
		if (event == "LOOT_OPENED" or event == "LOOT_CLOSED" or event == "LOOT_SLOT_CLEARED") then
			CEPGP_handleLoot(event, arg1, arg2);
		end
	end
	
end

function SlashCmdList.CEPGP(msg, editbox)
	msg = string.lower(msg);
	
	if msg == "" then
		CEPGP_print("Classic EPGP Usage");
		CEPGP_print("|cFF80FF80show|r - |cFFFF8080Manually shows the CEPGP window|r");
		CEPGP_print("|cFF80FF80version|r - |cFFFF8080Checks the version of the addon everyone in your raid is running|r");
		CEPGP_print("|cFF80FF80options or config|r - |cFFFF8080Opens the configuration menu for CEPGP|r");
		CEPGP_print("|cFF80FF80traffic|r - |cFFFF8080Opens the CEPGP traffic window|r");
		CEPGP_print("|cFF80FF80changelog|r - |cFFFF8080Shows the latest changelog|r");
	
	elseif msg == "show" or msg == "open" then
		CEPGP_populateFrame();
		ShowUIPanel(CEPGP_frame);
		CEPGP_toggleFrame("");
		CEPGP_updateGuild();
	
	elseif msg == "options" or msg == "opt" or msg == "config" or msg == "conf" then
		InterfaceOptionsFrame_Show();
		InterfaceOptionsFrame_OpenToCategory("Classic EPGP");
		
	elseif msg == "change" or msg == "changelog" then
		ShowUIPanel(CEPGP_changelog);
		
	elseif msg == "traffic" then
		ShowUIPanel(CEPGP_traffic);
	
	elseif msg == "version" or msg == "ver" then
		CEPGP_Info.Version.List = {};
		CEPGP_Info.Version.ListSearch = "GUILD";
		CEPGP_SendAddonMsg("version-check", "GUILD");
		for i = 1, GetNumGuildMembers() do
			local name, _, _, _, class, _, _, _, online, _, classFileName = GetGuildRosterInfo(i);
			name = Ambiguate(name, "all");
			if online then
				CEPGP_Info.Version.List[name] = CEPGP_Info.Version.List[name] or {
					[1] = "Addon not enabled",
					[2] = class,
					[3] = classFileName,
				};
			else
				CEPGP_Info.Version.List[name] = {
					[1] = "Offline",
					[2] = class,
					[3] = classFileName
				};
			end
		end
		ShowUIPanel(CEPGP_version);
		if CEPGP_version:IsVisible() then
			CEPGP_UpdateVersionScrollBar();
		end
		
	elseif msg == "debugmode" then
		CEPGP_Info.Debug = not CEPGP_Info.Debug;
		if CEPGP_Info.Debug then
			CEPGP_print("Debug Mode Enabled");
		else
			CEPGP_print("Debug Mode Disabled");
		end
	
	elseif msg == "log" then
		CEPGP_log:Show();
		
	elseif msg == "debug" then
		CEPGP_debuginfo:Show();
	
	else
		CEPGP_print("|cFF80FF80" .. msg .. "|r |cFFFF8080is not a valid request. Type /CEPGP to check addon usage|r", true);
	end
end

function CEPGP_initMinimapIcon()
    if LDB then
        local MinimapBtn = LDB:NewDataObject("CEPGP", {
            type = "launcher",
			text = "CEPGP",
            icon = "Interface\\AddOns\\CEPGP\\Icons\\icon",
            OnClick = function(self, button)
				if button == "LeftButton" then
					CEPGP_frame:Show();
				elseif button == "RightButton" then
					InterfaceOptionsFrame_Show();
					InterfaceOptionsFrame_OpenToCategory("Classic EPGP");
				end
			end,
			OnEnter = function(self)
				local text = "|c00FFC100Classic EPGP\nVersion: " .. CEPGP_Info.Version.Number .. " " .. CEPGP_Info.Version.Build .. "|r\n\nLeft Click: Show the main CEPGP window\nRight Click: Open the CEPGP configuration";
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
				GameTooltip:SetText(text);
			end,
			OnLeave = function()
				GameTooltip:Hide();
			end
        });
        if LDBIcon then
            LDBIcon:Register("CEPGP", MinimapBtn, CEPGP.Minimap);
        end
    end
end

function CEPGP_toggleMinimapButton()
	CEPGP.Minimap.hide = not CEPGP.Minimap.hide;
	if CEPGP.Minimap.hide then
		LDBIcon:Hide("CEPGP")
	else
		LDBIcon:Show("CEPGP");
	end
end

--[[ LOOT COUNCIL FUNCTIONS ]]--

function CEPGP_RaidAssistLootClosed()
	HideUIPanel(CEPGP_distribute_popup);
	HideUIPanel(CEPGP_distributing_button);
	HideUIPanel(CEPGP_loot_distributing);
	HideUIPanel(CEPGP_frame);
	CEPGP_distribute_item_tex:SetBackdrop(nil);
	_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() end);
	_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() end);
	CEPGP_UpdateLootScrollBar();
end

function CEPGP_RaidAssistLootDist(link, gp, raidwide) --raidwide refers to whether or not the ML would like everyone in the raid to be able to see the distribution window
	if ((UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and CEPGP_isML() ~= 0) or raidwide then --Only returns true if the unit is raid ASSIST, not raid leader
		ShowUIPanel(CEPGP_distributing_button);
		CEPGP_UpdateLootScrollBar();
		local name, iString, _, _, _, _, _, _, slot, tex = GetItemInfo(CEPGP_Info.Loot.DistributionID);
		CEPGP_Info.Loot.DistEquipSlot = slot;
		if not name and CEPGP_itemExists(CEPGP_Info.Loot.DistributionID) then
			local item = Item:CreateFromItemID(tonumber(CEPGP_Info.Loot.DistributionID));
			item:ContinueOnItemLoad(function()
				name, iString, _, _, _, _, _, _, slot, tex = GetItemInfo(CEPGP_Info.Loot.DistributionID);	
				_G["CEPGP_distribute_item_name"]:SetText(link);
				if iString then
					_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function()
																			GameTooltip:SetOwner(_G["CEPGP_distribute_item_tex"], "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(iString)
																			GameTooltip:Show()
																		end);
					_G["CEPGP_distribute_item_texture"]:SetTexture(tex);
					_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString) end);
				else
					_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() end);
					_G["CEPGP_distribute_item_texture"]:SetTexture(nil);
				end
				_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
				_G["CEPGP_distribute_GP_value"]:SetText(gp);				
			end);
		else
			_G["CEPGP_distribute_item_name"]:SetText(link);
			if iString then
				_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function()
																		GameTooltip:SetOwner(_G["CEPGP_distribute_item_tex"], "ANCHOR_TOPLEFT") GameTooltip:SetHyperlink(iString)
																		GameTooltip:Show()
																	end);
				_G["CEPGP_distribute_item_texture"]:SetTexture(tex);
				_G["CEPGP_distribute_item_name_frame"]:SetScript('OnClick', function() SetItemRef(iString) end);
			else
				_G["CEPGP_distribute_item_tex"]:SetScript('OnEnter', function() end);
				_G["CEPGP_distribute_item_texture"]:SetTexture(nil);
			end
			_G["CEPGP_distribute_item_tex"]:SetScript('OnLeave', function() GameTooltip:Hide() end);
			_G["CEPGP_distribute_GP_value"]:SetText(gp);
		end
	end
	
	if raidwide and CEPGP.Loot.AutoShow then
		ShowUIPanel(CEPGP_frame);
		CEPGP_toggleFrame("CEPGP_distribute");
	end
end

--[[ ADD EPGP FUNCTIONS ]]--

function CEPGP_AddRaidEP(amount, msg, encounter)
	amount = math.floor(amount);
	local function callback()
		local success, failMsg = pcall(function()
			local total = GetNumGroupMembers();
			CEPGP_Info.IgnoreUpdates = true;
			CEPGP_SendAddonMsg("?IgnoreUpdates;true");
			
			local roster = {};
			
			for _, v in pairs(CEPGP_Info.Raid.Roster) do
				roster[v[1]] = "";
			end
			
			local function update()
				if msg ~= "" and msg ~= nil or encounter then
					if encounter then -- a boss was killed
						CEPGP_addTraffic("Raid", UnitName("player"), "Add Raid EP +" .. amount .. " - " .. encounter, "", "", "", "", "", time());
						CEPGP_sendChatMessage(msg, CEPGP.Channel);
					else -- EP was manually given, could be either positive or negative, and a message was written
						if tonumber(amount) <= 0 then
							CEPGP_addTraffic("Raid", UnitName("player"), "Subtract Raid EP -" .. amount .. " (" .. msg .. ")", "", "", "", "", "", time());
							CEPGP_sendChatMessage(amount .. " EP taken from all raid members (" .. msg .. ")", CEPGP.Channel);
						else
							CEPGP_addTraffic("Raid", UnitName("player"), "Add Raid EP +" .. amount .. " (" .. msg .. ")", "", "", "", "", "", time());
							CEPGP_sendChatMessage(amount .. " EP awarded to all raid members (" .. msg .. ")", CEPGP.Channel);
						end
					end
				else -- no message was written
					if tonumber(amount) <= 0 then
						amount = string.sub(amount, 2, string.len(amount));
						CEPGP_addTraffic("Raid", UnitName("player"), "Subtract Raid EP -" .. amount, "", "", "", "", "", time());
						CEPGP_sendChatMessage(amount .. " EP taken from all raid members", CEPGP.Channel);
					else
						CEPGP_addTraffic("Raid", UnitName("player"), "Add Raid EP +" .. amount, "", "", "", "", "", time());
						CEPGP_sendChatMessage(amount .. " EP awarded to all raid members", CEPGP.Channel);
					end
				end
				if _G["CEPGP_traffic"]:IsVisible() then
					CEPGP_UpdateTrafficScrollBar();
				end
				C_Timer.After(2, function()
					CEPGP_Info.IgnoreUpdates = false;
					CEPGP_SendAddonMsg("?IgnoreUpdates;false");
					CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
				end);
			end
			
			local i = 0;
			local mains = {};
			C_Timer.NewTicker(0.0001, function()
				i = i + 1;
				local name = GetRaidRosterInfo(i);
				local EP, GP, EPB;
				if CEPGP_Info.Guild.Roster[name] then
					local index = CEPGP_getIndex(name);
					local main = CEPGP_getMain(name);
					
					if main then
						for v, _ in pairs(mains) do
							if v == main then
								return;
							end
						end
						
						if not roster[main] then
							mains[main] = name;
						end
					else
						EP, GP = CEPGP_getEPGP(name, index);
						EPB = EP;
						EP = math.max(math.floor(EP + amount), 0);
						GP = math.max(math.floor(GP), CEPGP.GP.Min);
						GuildRosterSetOfficerNote(index, EP .. "," .. GP);
						if CEPGP.Alt.Links[name] and not mains[name] then
							mains[name] = {};
						end
					end
				end
				if i == total then
					C_Timer.After(2, function()
						for main, alt in pairs(mains) do
							if #mains[main] == 0 then
								CEPGP_syncAltStandings(main);
							else
								CEPGP_addAltEPGP(amount, 0, alt, main);
							end
						end
					end);
					update();
				end
			end, total);
		end);
		
		if not success then
			CEPGP_print("A problem was encountered while awarding EP to the raid", true);
			CEPGP_print(failMsg, true);
		end
	end
	
	if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Polling then
		CEPGP_print("Scanning guild roster. Raid EP will be applied soon.");
		if encounter then
			CEPGP_Info.RosterStack["BossEP"] = callback;
		else
			CEPGP_Info.RosterStack["RaidEP"] = callback;
		end
	else
		callback();
	end
end

function CEPGP_addGuildEP(amount, msg)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	
	local success, failMsg = pcall(function()
		local EP, GP = nil;
		amount = math.floor(amount);
		local function update()
			if tonumber(amount) <= 0 then
				amount = string.sub(amount, 2, string.len(amount));
				if msg ~= "" and msg ~= nil then
					CEPGP_sendChatMessage(amount .. " EP taken from all guild members (" .. msg .. ")", CEPGP.Channel);
					CEPGP_addTraffic("Guild", UnitName("player"), "Subtract Guild EP -" .. amount .. " (" .. msg .. ")", "", "", "", "", "", time());
				else
					CEPGP_sendChatMessage(amount .. " EP taken from all guild members", CEPGP.Channel);
					CEPGP_addTraffic("Guild", UnitName("player"), "Subtract Guild EP -" .. amount, "", "", "", "", "", time());
				end
			else
				if msg ~= "" and msg ~= nil then
					CEPGP_sendChatMessage(amount .. " EP awarded to all guild members (" .. msg .. ")", CEPGP.Channel);
					CEPGP_addTraffic("Guild", UnitName("player"), "Add Guild EP +" .. amount .. " (" .. msg .. ")", "", "", "", "", "", time());
				else
					CEPGP_sendChatMessage(amount .. " EP awarded to all guild members", CEPGP.Channel);
					CEPGP_addTraffic("Guild", UnitName("player"), "Add Guild EP +" .. amount, "", "", "", "", "", time());
				end
			end
			if _G["CEPGP_traffic"]:IsVisible() then
				CEPGP_UpdateTrafficScrollBar();
			end
			C_Timer.After(2, function()
				CEPGP_Info.IgnoreUpdates = false;
				CEPGP_SendAddonMsg("?IgnoreUpdates;false");
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			end);
		end

		CEPGP_Info.IgnoreUpdates = true;
		CEPGP_SendAddonMsg("?IgnoreUpdates;true");
		local temp = {};
		local mains = {};
		for k, _ in pairs(CEPGP_Info.Guild.Roster) do
			table.insert(temp, k);
		end
		local i = 0;
		C_Timer.After(0.1, function()
			C_Timer.NewTicker(0.0001, function()
				i = i + 1;
				local name = temp[i];
				if CEPGP_Info.Guild.Roster[name][9] then return; end
				local main = CEPGP_getMain(name);
				
				if main then
					for _, v in ipairs(mains) do
						if v == main then
							return;
						end
					end
					
					table.insert(mains, main);
				else
					local index = CEPGP_getIndex(name);
					
					EP, GP = CEPGP_getEPGP(name, index);
					EP = math.max(math.floor(EP + amount), 0);
					GP = math.max(math.floor(GP), CEPGP.GP.Min);
					
					if index then
						if main then
							CEPGP_addAltEPGP(amount, 0, name, main);
						else
							GuildRosterSetOfficerNote(index, EP .. "," .. GP);
							C_Timer.After(1, function()
								CEPGP_syncAltStandings(player);
							end);
						end
					end
				end
				if i == #temp then
					C_Timer.After(2, function()
						for _, name in ipairs(mains) do
							CEPGP_syncAltStandings(name);
						end
					end);
					update();
				end
			end, #temp);
		end);
	end);
	if not success then
		CEPGP_print("A problem was encountered while awarding EP to the raid", true);
		CEPGP_print(failMsg, true);
	end
end

function CEPGP_addStandbyEP(amount, boss, msg)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	
	local function callback()
		local success, failMsg = pcall(function()
			local function update()
				if tonumber(amount) > 0 then
					CEPGP_addTraffic("Guild", UnitName("player"), "Standby EP +" .. amount);
				elseif tonumber(amount) < 0 then
					CEPGP_addTraffic("Guild", UnitName("player"), "Standby EP " .. amount);
				end
				if _G["CEPGP_traffic"]:IsVisible() then
					CEPGP_UpdateTrafficScrollBar();
				end
				if _G["CEPGP_standby_options"]:IsVisible() then
					CEPGP_UpdateStandbyScrollBar();
				end
				C_Timer.After(2, function()
					CEPGP_Info.IgnoreUpdates = false;
					CEPGP_SendAddonMsg("?IgnoreUpdates;false");
					CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
				end);
			end
			
			CEPGP_Info.IgnoreUpdates = true;
			CEPGP_SendAddonMsg("?IgnoreUpdates;true");
			
			local i = 0;
			local mains = {};
			
			local roster = {};
			local standbyRoster = {};
			
			for index, data in ipairs(CEPGP.Standby.Roster) do
				standbyRoster[index] = data;
			end
			for _, v in pairs(CEPGP_Info.Raid.Roster) do
				roster[v[1]] = "";
			end
			
			C_Timer.After(0.1, function()
				if CEPGP.Standby.ByRank then
					local inRaid = false;
					C_Timer.NewTicker(0.0001, function()
						i = i + 1;
						local name = standbyRoster[i];
						if CEPGP_Info.Guild.Roster[name][9] then return; end
						inRaid = false;
						
						if roster[name] then
							inRaid = true;
						end
						
						for _, data in ipairs(standbyRoster) do
							if roster[data[1]] then		--	character name
								inRaid = true;
								break;
							end
						end
						
						if not inRaid then
							local main = CEPGP_getMain(name);
							if main then
								if not roster[main] and not mains[main] then
									mains[main] = name;
								end
							else
								local index = CEPGP_getIndex(name);
								local _, rank, rankIndex, _, _, _, _, _, online = GetGuildRosterInfo(index);
								local EP,GP = CEPGP_getEPGP(name, index);
								
								EP = math.max(math.floor(EP + amount), 0);
								GP = math.max(math.floor(GP), CEPGP.GP.Min);
									
								for i = 1, #CEPGP.Standby.Ranks do
									if CEPGP.Standby.Ranks[i][1] == rank then
										if CEPGP.Standby.Ranks[i][2] == true and (online or CEPGP.Standby.Offline) then
											if main then
												CEPGP_addAltEPGP(amount, 0, name, main);
											else
												GuildRosterSetOfficerNote(index, EP .. "," .. GP);
											end
											if boss then
												CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP for encounter " .. boss, "GUILD");
											elseif msg ~= "" and msg ~= nil then
												if tonumber(amount) > 0 then
													CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP - "..msg, "GUILD");
												elseif tonumber(amount) < 0 then
													CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";"..amount.." standby EP has been taken from you - "..msg, "GUILD");
												end
											else
												if tonumber(amount) > 0 then
													CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP", "GUILD");
												elseif tonumber(amount) < 0 then
													CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";"..amount.." standby EP has been taken from you", "GUILD");
												end
											end
										end
									end
								end
							end
						end
						if i == #standbyRoster then
							C_Timer.After(2, function()
								for main, alt in pairs(mains) do
									if #mains[main] == 0 then
										CEPGP_syncAltStandings(main);
									else
										CEPGP_addAltEPGP(amount, 0, alt, main);
									end
								end
							end);
							update();
						end
					end, #temp);
					
				elseif CEPGP.Standby.Manual and #standbyRoster > 0 then
					C_Timer.NewTicker(0.0001, function()
						i = i + 1;
						local name = standbyRoster[i][1];
						if CEPGP_Info.Guild.Roster[name][9] then return; end
						local main = CEPGP_getMain(name);
						local index = CEPGP_getIndex(name);
						local online = select(9, GetGuildRosterInfo(index));
						
						if online or CEPGP.Standby.Offline then
							local EP,GP = CEPGP_getEPGP(name, index);				
							if main then
								if not roster[main] and not mains[main] then
									mains[main] = name;
								end
							else
								EP = math.max(math.floor(EP + amount), 0);
								GP = math.max(math.floor(GP), CEPGP.GP.Min);
								GuildRosterSetOfficerNote(index, EP .. "," .. GP);
							end
							
							if boss then
								CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP for encounter " .. boss, "GUILD");
							elseif msg ~= "" and msg ~= nil then
								if tonumber(amount) > 0 then
									CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP - "..msg, "GUILD");
								elseif tonumber(amount) < 0 then
									CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";"..amount.." standby EP has been taken from you - "..msg, "GUILD");
								end
							else
								if tonumber(amount) > 0 then
									CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";You have been awarded "..amount.." standby EP", "GUILD");
								elseif tonumber(amount) < 0 then
									CEPGP_SendAddonMsg("CEPGP.Standby.Enabled;"..name..";"..amount.." standby EP has been taken from you", "GUILD");
								end
							end
						end
						if i == #standbyRoster then
							C_Timer.After(2, function()
								for main, alt in pairs(mains) do
									if #mains[main] == 0 then
										CEPGP_syncAltStandings(main);
									else
										CEPGP_addAltEPGP(amount, 0, alt, main);
									end
								end
							end);
							update();
						end
					end, #standbyRoster);
				end
			end);
		end);
		
		if not success then
			CEPGP_print("A problem was encountered while awarding EP to the standby list", true);
			CEPGP_print(failMsg);
		end
	end
	
	
	
	if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Polling then
		CEPGP_print("Scanning guild roster. Standby EP will be applied soon.");
		CEPGP_Info.RosterStack["StandbyEP"] = callback;
	else
		callback();
	end
end

function CEPGP_addGP(player, amount, itemID, itemLink, msg, response)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	local EP, GP = nil;
	local GPB, GPA;
	
	local success, failMsg = pcall(function()
		amount = math.floor(amount);
		if CEPGP_Info.Guild.Roster[player] then
			local index = CEPGP_getIndex(player);
			local main = CEPGP_getMain(player);
			
			EP, GP = CEPGP_getEPGP(player, index);
			GPB = GP;
			
			GP = math.max(math.floor(GP + amount), CEPGP.GP.Min + amount);
			EP = math.max(math.floor(EP), 0);		
			
			if main then
				CEPGP_addAltEPGP(0, amount, player, main);
				if CEPGP.Alt.BlockAwards then
					if itemID then
						CEPGP_addTraffic(player, UnitName("player"), "Awarded for free (Alt)", nil, nil, nil, nil, itemID);
						return;
					else
						CEPGP_print("Cannot award GP directly to " .. player .. " because they are an alt and you have blocked alt EPGP modifications", true);
						return;
					end
				end
			else
				GuildRosterSetOfficerNote(index, EP .. "," .. GP);
				C_Timer.After(1, function()
					CEPGP_syncAltStandings(player);
				end);
			end
			if not itemID then
				if tonumber(amount) < 0 then -- Number is negative
					amount = string.sub(amount, 2, string.len(amount));
					if msg ~= "" and msg ~= nil then
						CEPGP_sendChatMessage(amount .. " GP taken from " .. player .. " (" .. msg .. ")", CEPGP.Channel);
						CEPGP_addTraffic(player, UnitName("player"), "Subtract GP -" .. amount .. " (" .. msg .. ")", EP, EP, GPB, GP);
					else
						CEPGP_sendChatMessage(amount .. " GP taken from " .. player, CEPGP.Channel);
						CEPGP_addTraffic(player, UnitName("player"), "Subtract GP -" .. amount, EP, EP, GPB, GP);
					end
				else -- Number is positive
					if msg ~= "" and msg ~= nil then
						CEPGP_sendChatMessage(amount .. " GP added to " .. player .. " (" .. msg .. ")", CEPGP.Channel);
						CEPGP_addTraffic(player, UnitName("player"), "Add GP +" .. amount .. " (" .. msg .. ")", EP, EP, GPB, GP);
					else
						CEPGP_sendChatMessage(amount .. " GP added to " .. player, CEPGP.Channel);
						CEPGP_addTraffic(player, UnitName("player"), "Add GP +" .. amount, EP, EP, GPB, GP);
					end
				end
			else -- If an item is associated with the message then the number cannot be negative
				if not itemLink then
					_, itemLink = GetItemInfo(tonumber(itemID));
				end
				if response then
					CEPGP_addTraffic(player, UnitName("player"), "Add GP " .. amount .. " (" .. response .. ")", EP, EP, GPB, GP, itemID);
				else
					CEPGP_addTraffic(player, UnitName("player"), "Add GP " .. amount, EP, EP, GPB, GP, itemID);
				end
			end
			CEPGP_UpdateTrafficScrollBar();
		else
			local index = CEPGP_getIndex(player);
			if index then
				CEPGP_addTraffic(player, UnitName("player"), "Awarded for free (Exclusion List)", nil, nil, nil, nil, itemID);
			else
				CEPGP_print(player .. " not found in guild roster - no GP given");
				CEPGP_print("If this was a mistake, you can manually award them GP via the CEPGP guild menu");
			end
		end
	end);
	
	if not success then
		CEPGP_print("A problem was encountered while awarding GP", true);
		CEPGP_print(failMsg, true);
	end
end

function CEPGP_addEP(player, amount, msg)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	
	local success, failMsg = pcall(function()
		amount = math.floor(amount);
		local EP, GP, EPB = nil;
		if CEPGP_Info.Guild.Roster[player] then
			local index = CEPGP_getIndex(player);
			local main = CEPGP_getMain(player);
			
			EP, GP = CEPGP_getEPGP(player, index);
			EPB = EP;
			
			EP = math.max(math.floor(EP + amount), 0);
			GP = math.max(math.floor(GP), CEPGP.GP.Min);
			
			if main then
				if CEPGP.Alt.BlockAwards then
					CEPGP_print("Cannot award EP directly to " .. player .. " because they are an alt and you have blocked alt EPGP modifications", true);
					return;
				end
				CEPGP_addAltEPGP(amount, 0, player, main);
			else
				GuildRosterSetOfficerNote(index, math.floor(EP) .. "," .. GP);
				C_Timer.After(1, function()
					CEPGP_syncAltStandings(player);
				end);
			end
			if tonumber(amount) <= 0 then
				if msg ~= "" and msg ~= nil then
					amount = string.sub(amount, 2, string.len(amount));
					CEPGP_sendChatMessage(amount .. " EP taken from " .. player .. " (" .. msg .. ")", CEPGP.Channel);
					CEPGP_addTraffic(player, UnitName("player"), "Subtract EP -" .. amount .. " (" .. msg .. ")", EPB, EP, GP, GP);
				else
					amount = string.sub(amount, 2, string.len(amount));
					CEPGP_sendChatMessage(amount .. " EP taken from " .. player, CEPGP.Channel);
					CEPGP_addTraffic(player, UnitName("player"), "Subtract EP -" .. amount, EPB, EP, GP, GP);
				end
			else
				if msg ~= "" and msg ~= nil then
					CEPGP_sendChatMessage(amount .. " EP added to " .. player .. " (" .. msg .. ")", CEPGP.Channel);
					CEPGP_addTraffic(player, UnitName("player"), "Add EP +" .. amount .. " (" .. msg ..")", EPB, EP, GP, GP);
				else
					CEPGP_sendChatMessage(amount .. " EP added to " .. player, CEPGP.Channel);
					CEPGP_addTraffic(player, UnitName("player"), "Add EP +" .. amount, EPB, EP, GP, GP);
				end
			end
			CEPGP_UpdateTrafficScrollBar();
		else
			local index = CEPGP_getIndex(player);
			if not index then
				CEPGP_print("Player not found in guild roster.", true);
			end
		end
	end);
	
	if not success then
		CEPGP_print("A problem was encountered while awarding EP", true);
		CEPGP_print(failMsg, true);
	end
end

function CEPGP_decay(amount, msg, decayEP, decayGP, fixed)
	if amount == nil then
		CEPGP_print("Please enter a valid number", 1);
		return;
	end
	
	local function callback()
		local success, failMsg = pcall(function()
			local function update()
				if tonumber(amount) <= 0 then
					amount = string.sub(amount, 2, string.len(amount));
					if msg ~= "" and msg ~= nil then
						if decayEP then
							CEPGP_sendChatMessage("Guild EP inflated by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated EP +" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						elseif decayGP then
							CEPGP_sendChatMessage("Guild GP inflated by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated GP +" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						else
							CEPGP_sendChatMessage("Guild EPGP inflated by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated EPGP +" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						end
					else
						if decayEP then
							CEPGP_sendChatMessage("Guild EP inflated by " .. amount .. (fixed and "" or "%"), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated EP +" .. amount .. (fixed and "" or "%"));
						elseif decayGP then
							CEPGP_sendChatMessage("Guild GP inflated by " .. amount .. (fixed and "" or "%"), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated GP +" .. amount .. (fixed and "" or "%"));
						else
							CEPGP_sendChatMessage("Guild EPGP inflated by " .. amount .. (fixed and "" or "%"), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Inflated EPGP +" .. amount .. (fixed and "" or "%"));
						end
					end
				else
					if msg ~= "" and msg ~= nil then
						if decayEP then
							CEPGP_sendChatMessage("Guild EP decayed by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed EP -" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						elseif decayGP then
							CEPGP_sendChatMessage("Guild GP decayed by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed GP -" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						else
							CEPGP_sendChatMessage("Guild EPGP decayed by " .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")", CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed EPGP -" .. amount .. (fixed and " " or "% ") .. "(" .. msg .. ")");
						end
					else
						if decayEP then
							CEPGP_sendChatMessage("Guild EP decayed by " .. amount .. (fixed and "" or "%"), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed EP -" .. amount .. (fixed and "" or "%"));
						elseif decayGP then
							CEPGP_sendChatMessage("Guild GP decayed by " .. amount .. (fixed and "" or "% "), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed GP -" .. amount .. (fixed and "" or "%"));
						else
							CEPGP_sendChatMessage("Guild EPGP decayed by " .. amount .. (fixed and "" or "%"), CEPGP.Channel);
							CEPGP_addTraffic("Guild", UnitName("player"), "Decayed EPGP -" .. amount .. (fixed and "" or "%"));
						end
					end
				end
				if _G["CEPGP_traffic"]:IsVisible() then
					CEPGP_UpdateTrafficScrollBar();
				end
				C_Timer.After(2, function()
					CEPGP_Info.IgnoreUpdates = false;
					CEPGP_SendAddonMsg("?IgnoreUpdates;false");
					CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
				end);
			end
			
			local EP, GP = nil;
			CEPGP_Info.IgnoreUpdates = true;
			CEPGP_SendAddonMsg("?IgnoreUpdates;true");
			
			local temp = {};
			local i = 0;
			
			for k, _ in pairs(CEPGP_Info.Guild.Roster) do
				table.insert(temp, k);
			end
			
			CEPGP_print("Starting decay. Please wait...");
			C_Timer.After(0.1, function()
				C_Timer.NewTicker(0.0001, function()
					i = i + 1;
					local name = temp[i];
					if CEPGP_Info.Guild.Roster[name][9] then return; end
					local index = CEPGP_getIndex(name);
					local rankIndex = select(3, GetGuildRosterInfo(index));
					local main = CEPGP_getMain(name);
					if not main then
						EP, GP = CEPGP_getEPGP(name, index);
						if decayEP or (not decayEP and not decayGP) then
							if fixed then
								EP = math.max(math.floor(tonumber(EP)-amount), 0);
							else
								EP = math.max(math.floor(tonumber(EP)*(1-(amount/100))), 0);
							end
						end
						if decayGP or (not decayEP and not decayGP) then
							if CEPGP.GP.DecayFactor then
								if fixed then
									GP = math.max(math.floor((tonumber(GP-CEPGP.GP.Min)-amount)+CEPGP.GP.Min), CEPGP.GP.Min);
								else
									GP = math.max(math.floor((tonumber(GP-CEPGP.GP.Min)*(1-(amount/100)))+CEPGP.GP.Min), CEPGP.GP.Min);
								end
							else
								if fixed then
									GP = math.max(math.floor(tonumber(GP)-amount), CEPGP.GP.Min);
								else
									GP = math.max(math.floor((tonumber(GP)*(1-(amount/100)))), CEPGP.GP.Min);
								end
							end
						end
						GuildRosterSetOfficerNote(index, EP .. "," .. GP);
					end
					if i == #temp then
						C_Timer.After(2, function()
							for name, _ in pairs(CEPGP.Alt.Links) do
								CEPGP_syncAltStandings(name);
							end
						end);
						CEPGP_print("Decay has completed");
						update();
					end
				end, #temp);
			end);
		end);
		
		if not success then
			CEPGP_print("A problem was encountered while decaying", true);
			CEPGP_print(failMsg, true);
		end
	end
	
	if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < GetNumGuildMembers() and CEPGP_Info.Polling then
		CEPGP_print("Scanning guild roster. Decay will be applied soon.");
		CEPGP_Info.RosterStack["Decay"] = callback;
	else
		callback();
	end
end

function CEPGP_resetAll(msg)
	
	local success, failMsg = pcall(function()
		local function update()
			if msg ~= "" and msg ~= nil then
				CEPGP_addTraffic("Guild", UnitName("player"), "Cleared EPGP standings (" .. msg .. ")");
				CEPGP_sendChatMessage("All EPGP standings have been cleared! (" .. msg .. ")", CEPGP.Channel);
			else
				CEPGP_addTraffic("Guild", UnitName("player"), "Cleared EPGP standings");
				CEPGP_sendChatMessage("All EPGP standings have been cleared!", CEPGP.Channel);
			end
			C_Timer.After(2, function()
				CEPGP_Info.IgnoreUpdates = false;
				CEPGP_SendAddonMsg("?IgnoreUpdates;false");
				CEPGP_rosterUpdate("GUILD_ROSTER_UPDATE");
			end);
		end
		
		CEPGP_Info.IgnoreUpdates = true;
		CEPGP_SendAddonMsg("?IgnoreUpdates;true");
		
		local i = 0;
		
		C_Timer.After(0.1, function()
			C_Timer.NewTicker(0.0001, function()
				i = i + 1;
				local name = GetGuildRosterInfo(i);
				local rankIndex = select(3, GetGuildRosterInfo(i));
				if CEPGP_Info.Guild.Roster[name][9] then return; end
				GuildRosterSetOfficerNote(i, "0,"..CEPGP.GP.Min);
				if i == GetNumGuildMembers() then
					update();
				end
			end, GetNumGuildMembers());
		end);
	end);
	
	if not success then
		CEPGP_print("A problem was encountered while resetting standings", true);
		CEPGP_print(failMsg, true);
	end
	
end