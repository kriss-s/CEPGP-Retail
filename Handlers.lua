local L = CEPGP_Locale:GetLocale("CEPGP")

function CEPGP_handleComms(event, arg1, arg2, response, lootGUID)
	--	arg1 - message | arg2 - sender
	if arg1 then
		response = CEPGP_getLabelIndex(CEPGP_getResponse(arg1));
	end
	response = tonumber(response);
	--if not response then response = arg1; end
	if not response and (arg1 ~= "!info" and arg1 ~= "!infoclass" and arg1 ~= "!infoguild" and arg1 ~= "!inforaid") then
		response = arg1;
	end
	local reason = CEPGP_response_buttons[response] and CEPGP_response_buttons[response][2] or CEPGP_Info.LootSchema[response] or CEPGP_getResponse(CEPGP_getResponseIndex(response));
	local index = CEPGP_getIndex(arg2);

	if event == "CHAT_MSG_WHISPER" and response then
		if (lootGUID ~= CEPGP_Info.Loot.GUID and lootGUID ~= "") and not arg1 then return; end
		local roll = math.ceil(math.random(1,100));
		
		if CEPGP.Loot.ResolveRolls then
			local function checkRoll(name)
				for k, v in pairs(CEPGP_Info.Loot.ItemsTable) do
					if k ~= name then
						if v[4] then
							if v[4] == roll then
								roll = math.ceil(math.random(1,100));
								checkRoll(name);
								return false;
							end
						end
					end
				end
				return true;
			end
			checkRoll(arg2);
		end
		
		if not CEPGP_Info.Loot.Distributing then return; end
		for name, _ in pairs(CEPGP_Info.Loot.ItemsTable) do
			if name == arg2 then return; end
		end
		CEPGP_Info.LootRespondants = CEPGP_Info.LootRespondants + 1;
		if CEPGP_Info.Debug then
			CEPGP_print(arg2 .. " registered (" .. CEPGP_keyword .. ")");
		end
		local _, _, _, _, _, _, _, _, slot = GetItemInfo(CEPGP_Info.Loot.DistributionID);
		if not slot and CEPGP_itemExists(CEPGP_Info.Loot.DistributionID) then
			local item = Item:CreateFromItemID(CEPGP_Info.Loot.DistributionID);
			item:ContinueOnItemLoad(function()
				local _, _, _, _, _, _, _, _, slot = GetItemInfo(CEPGP_Info.Loot.DistributionID)
				local EP, GP = nil;
				local inGuild = false;
				if CEPGP_Info.Guild.Roster[arg2] then 
					EP, GP = CEPGP_getEPGP(arg2, index);
					class = CEPGP_Info.Guild.Roster[arg2][2];
					inGuild = true;
				elseif index then
					EP, GP = CEPGP_getEPGP(arg2, index);
					class = select(5, GetGuildRosterInfo(index));
					inGuild = true; 
				end
				if CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or (CEPGP_show_passes and response == 6) or response < 6 then
					CEPGP_SendAddonMsg(arg2..";distslot;"..CEPGP_Info.Loot.DistEquipSlot, "RAID");
				end
				if inGuild and not CEPGP_suppress_announcements then
					if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) and not CEPGP.Loot.DelayResponses then	-- 5 means they're not using the addon or they're using an outdated version that doesn't support responses
						if CEPGP.Loot.RollAnnounce then
							CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (" .. math.floor((EP/GP)*100)/100 .. " PR) (Rolled " .. roll .. ")", CEPGP.LootChannel);
						else
							CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (" .. math.floor((EP/GP)*100)/100 .. " PR)", CEPGP.LootChannel);
						end
					end
				elseif not CEPGP_suppress_announcements then
					local total = GetNumGroupMembers();
					for i = 1, total do
						if arg2 == GetRaidRosterInfo(i) then
							_, _, _, _, class = GetRaidRosterInfo(i);
						end
					end
					if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) and not CEPGP.Loot.DelayResponses then
						if CEPGP.Loot.RollAnnounce then
							CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member) (Rolled " .. roll .. ")", CEPGP.LootChannel);
						else
							CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member)", CEPGP.LootChannel);
						end
					end
				end
				if CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or (CEPGP_show_passes and response == 6) or response < 6 then --If you are the master looter
					CEPGP_addResponse(arg2, response, roll);
				end
				CEPGP_UpdateLootScrollBar(true);
			end);
		else

			local EP, GP = nil;
			local inGuild = false;
			if CEPGP_Info.Guild.Roster[arg2] then 
					local index = CEPGP_getIndex(arg2);
					EP, GP = CEPGP_getEPGP(arg2, index);
					class = CEPGP_Info.Guild.Roster[arg2][2];
					inGuild = true;
				else
					local index = CEPGP_getIndex(arg2);
					if index then
						EP, GP = CEPGP_getEPGP(arg2, index);
						class = select(5, GetGuildRosterInfo(index));
						inGuild = true; 
					end
				end
			if CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or (CEPGP_show_passes and response == 6) or response < 6 then
				CEPGP_SendAddonMsg(arg2..";distslot;"..CEPGP_Info.Loot.DistEquipSlot, "RAID");
			end
			if inGuild and not CEPGP_suppress_announcements then
				if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) and not CEPGP.Loot.DelayResponses then
					if CEPGP.Loot.RollAnnounce then
						CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (" .. math.floor((EP/GP)*100)/100 .. " PR) (Rolled " .. roll .. ")", CEPGP.LootChannel);
					else
						CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (" .. math.floor((EP/GP)*100)/100 .. " PR)", CEPGP.LootChannel);
					end
				end
			elseif not CEPGP_suppress_announcements then
				local total = GetNumGroupMembers();
				for i = 1, total do
					if arg2 == GetRaidRosterInfo(i) then
						_, _, _, _, class = GetRaidRosterInfo(i);
					end
				end
				if (CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or response < 5) and not CEPGP.Loot.DelayResponses then
					if CEPGP.Loot.RollAnnounce then
						CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member) (Rolled " .. roll .. ")", CEPGP.LootChannel);
					else
						CEPGP_sendChatMessage(arg2 .. " (" .. class .. ") needs (" .. reason .. "). (Non-guild member)", CEPGP.LootChannel);
					end
				end
			end
			if CEPGP_getResponse(arg1) or CEPGP_getResponseIndex(arg1) or (CEPGP_show_passes and response == 6) or response < 6 then
				CEPGP_addResponse(arg2, response, roll);
			end
			CEPGP_UpdateLootScrollBar(true);
		end
		
	elseif event == "CHAT_MSG_WHISPER" and string.lower(arg1) == "!info" then
		if CEPGP_getGuildInfo(arg2) ~= nil then
			local index = CEPGP_getIndex(arg2);
			EP, GP = CEPGP_getEPGP(arg2, index);
			if not CEPGP_Info.Version.List[arg2] then
				SendChatMessage("EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "WHISPER", CEPGP_Info.Language, arg2);
			else
				CEPGP_SendAddonMsg("!info;" .. arg2 .. ";EPGP Standings - EP: " .. EP .. " / GP: " .. GP .. " / PR: " .. math.floor((EP/GP)*100)/100, "GUILD");
			end
		end
	elseif event == "CHAT_MSG_WHISPER" and (string.lower(arg1) == "!infoguild" or string.lower(arg1) == "!inforaid" or string.lower(arg1) == "!infoclass") then
		if CEPGP_getGuildInfo(arg2) ~= nil then
			local target = arg2;
			sRoster = {};
			CEPGP_updateGuild();
			local gRoster = {};
			local rRoster = {};
			local name, _, class, oNote, EP, GP;
			for i = 1, GetNumGuildMembers() do
				gRoster[i] = {};
				name , _, _, _, class = GetGuildRosterInfo(i);
				EP, GP = CEPGP_getEPGP(name, i);
				if string.find(name, "-") then
					name = string.sub(name, 0, string.find(name, "-")-1);
				end
				gRoster[i] = {
					[1] = name,
					[2] = EP,
					[3] = GP,
					[4] = math.floor((EP/GP)*100)/100,
					[5] = class
				};
			end
			if string.lower(arg1) == "!infoguild" then	--	Need to show EP, GP, PR and PR position
				local roster = {};
				for k, v in pairs(CEPGP_Info.Guild.Roster) do
					local EP, GP = CEPGP_getEPGP(k, v[1]);
					local PR = math.floor((EP/GP)*100)/100;
					local entry = {
						[1] = k,
						[2] = v[1],	--index
						[3] = EP,
						[4] = GP,
						[5] = PR
					};
					
					table.insert(roster, entry);
				end
				
				roster = CEPGP_tSort(roster, 5);
				
				for i = 1, #roster do
					if roster[i][1] == target then
						if not CEPGP_Info.Version.List[target] then
							SendChatMessage("EP: " .. roster[i][3] .. " / GP: " .. roster[i][4] .. " / PR: " .. roster[i][5] .. " / PR rank in guild: #" .. i, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_SendAddonMsg("!info;" .. target .. ";EP: " .. roster[i][3] .. " / GP: " .. roster[i][4] .. " / PR: " .. roster[i][5] .. " / PR rank in raid: #" .. i, "GUILD");
						end
						break;
					end
				end
			elseif string.lower(arg1) == "!inforaid" then
				if not UnitInRaid("player") then return; end
			
				local roster = CEPGP_Info.Raid.Roster;
				
				roster = CEPGP_tSort(roster, 7);
				
				for i = 1, #roster do
					if roster[i][1] == target then
						if not CEPGP_Info.Version.List[target] then
							SendChatMessage("EP: " .. roster[i][5] .. " / GP: " .. roster[i][6] .. " / PR: " .. roster[i][7] .. " / PR rank in guild: #" .. i, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_SendAddonMsg("!info;" .. target .. ";EP: " .. roster[i][5] .. " / GP: " .. roster[i][6] .. " / PR: " .. roster[i][7] .. " / PR rank in raid: #" .. i, "GUILD");
						end
						break;
					end
				end
				
			elseif string.lower(arg1) == "!infoclass" then
				
				if not UnitInRaid("player") then return; end
				
				local roster = {};
				local class;
				
				for index, v in ipairs(CEPGP_Info.Raid.Roster) do
					if v[1] == target then
						class = v[2];
						break;
					end
				end
				
				if not class then
					CEPGP_print(target .. " is not in the raid group");
					return;
				end
				
				for index, v in ipairs(CEPGP_Info.Raid.Roster) do
					if v[2] == class then
						table.insert(roster, v);
					end
				end
				
				roster = CEPGP_tSort(roster, 7);
				
				for i = 1, #roster do
					if roster[i][1] == target then
						if not CEPGP_Info.Version.List[target] then
							SendChatMessage("EP: " .. roster[i][5] .. " / GP: " .. roster[i][6] .. " / PR: " .. roster[i][7] .. " / PR rank among " .. class .. "s in raid: #" .. i, "WHISPER", CEPGP_Info.Language, target);
						else
							CEPGP_SendAddonMsg("!info;" .. target .. ";EP: " .. roster[i][5] .. " / GP: " .. roster[i][6] .. " / PR: " .. roster[i][7] .. " / PR rank among " .. class .. "s in raid: #" .. i, "GUILD");
						end
						break;
					end
				end
			end
		end
	end
end

function CEPGP_handleCombat(name)
	if (((GetLootMethod() == "master" and CEPGP_isML() == 0) or (GetLootMethod() == "group" and UnitIsGroupLeader("player"))) and CEPGP_ntgetn(CEPGP_Info.Guild.Roster) > 0) or CEPGP_Info.Debug then
		local localName = L[name];
		local EP = EPVALS[name];
		local plurals = name == "The Four Horsemen" or name == "The Silithid Royalty" or name == "The Twin Emperors";
		local message = format(L["%s " .. (plurals and "have" or "has") .. " been defeated! %d EP has been awarded to the raid"], localName, EP);
		local callback = function()
			local function awardEP(localName, EP, message)
				CEPGP_AddRaidEP(EP, message, localName);
			end
			
			local success, failMsg = pcall(awardEP, localName, EP, message);
			
			if not success then
				CEPGP_print("Failed to award raid EP for " .. name, true);
				CEPGP_print(failMsg);
			end
			
			local function awardStandbyEP(localName, EP)
				if STANDBYEP and tonumber(STANDBYPERCENT) > 0 then
					CEPGP_addStandbyEP(EP*(tonumber(STANDBYPERCENT)/100), localName);
				end
			end
			
			success, failMsg = pcall(awardStandbyEP, localName, EP);
			
			if not success then
				CEPGP_print("Failed to award standby EP for " .. name, true);
				CEPGP_print(failMsg);
			end
		end
		
		if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < (GetNumGuildMembers() - CEPGP_Info.NumExcluded) and CEPGP_Info.Polling then
			table.insert(CEPGP_Info.RosterStack, callback);
		else
			callback();
		end
		
		CEPGP_UpdateStandbyScrollBar();
	end
end

function CEPGP_handleLoot(event, arg1, arg2)
	if event == "LOOT_CLOSED" then
		if CEPGP_isML() == 0 then
			CEPGP_SendAddonMsg("LootClosed;", "RAID");
		end
		CEPGP_Info.Loot.DistributionID = nil;
		CEPGP_Info.Loot.Distributing = false;
		CEPGP_toggleGPEdit(true);
		CEPGP_Info.IgnoreUpdates = false;
		_G["CEPGP_distributing_button"]:Hide();
		if CEPGP_Info.Mode == "loot" then
			CEPGP_cleanTable();
			if CEPGP_isML() == 0 then
				if CEPGP.Loot.RaidVisibility[2] then
					CEPGP_SendAddonMsg("RaidAssistLootClosed;", "RAID");
				elseif CEPGP.Loot.RaidVisibility[1] then
					CEPGP_messageGroup("RaidAssistLootClosed", "assists");
				end
			end
			HideUIPanel(CEPGP_frame);
		end
		HideUIPanel(CEPGP_distribute_popup);
		--HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_loot);
		HideUIPanel(CEPGP_distribute);
		HideUIPanel(CEPGP_loot_distributing);
		HideUIPanel(CEPGP_button_loot_dist);
		HideUIPanel(CEPGP_roll_award_confirm);
		if UnitInRaid("player") then
			CEPGP_toggleFrame(CEPGP_raid);
		elseif GetGuildRosterInfo(1) then
			CEPGP_toggleFrame(CEPGP_guild);
		else
			HideUIPanel(CEPGP_frame);
			if CEPGP_isML() == 0 then
				CEPGP_distributing_button:Hide();
			end
		end
		
		if CEPGP_distribute:IsVisible() == 1 then
			HideUIPanel(CEPGP_distribute);
			ShowUIPanel(CEPGP_loot);
			CEPGP_UpdateLootScrollBar();
		end
		
	elseif event == "LOOT_OPENED" and (UnitInRaid("player") or CEPGP_Info.Debug) then
		CEPGP_Info.IgnoreUpdates = true;	--	Prevents the CEPGP roster from rebuilding while distributing loot
		CEPGP_LootFrame_Update();
		ShowUIPanel(CEPGP_button_loot_dist);

	elseif event == "LOOT_SLOT_CLEARED" then
		if CEPGP_Info.Loot.Distributing and arg1 == CEPGP_Info.Loot.SlotID then --Confirms that an item is currently being distributed and that the item taken is the one in question
			
			if CEPGP_isML() == 0 then
				if CEPGP.Loot.RaidVisibility[2] then
					CEPGP_SendAddonMsg("RaidAssistLootClosed;", "RAID");
				elseif CEPGP.Loot.RaidVisibility[1] then
					CEPGP_messageGroup("RaidAssistLootClosed", "assists");
				end
				CEPGP_SendAddonMsg("LootClosed;", "RAID");
			end
			
			local player = CEPGP_Info.DistTarget;
			local award = CEPGP_Info.Loot.GiveWithEPGP;
			local rate = CEPGP_Info.Loot.AwardRate;
			local id = CEPGP_Info.Loot.DistributionID;
			local link = select(2, GetItemInfo(id));
			local gpValue = tonumber(_G["CEPGP_distribute_GP_value"]:GetText());
			local itemName = _G["CEPGP_distribute_item_name"]:GetText()
			local response = CEPGP_distribute_popup:GetAttribute("responseName");
			local distGP = CEPGP_Info.Loot.AwardGP;
			local tStamp = time();
			
			CEPGP_Info.DistTarget = "";
			CEPGP_Info.Loot.Distributing = false;
			CEPGP_distribute_popup:Hide();
			CEPGP_roll_award_confirm:Hide();
			CEPGP_distribute:Hide();
			_G["CEPGP_distributing_button"]:Hide();
			CEPGP_loot:Show();
			CEPGP_toggleGPEdit(true);
			
			local callback = function()				
				if player ~= "" and award then
					if response == "" then response = nil; end
					
					if distGP then
						if response then
							local message = "Awarded " .. itemName .. " to ".. player .. " for " .. gpValue*rate .. " GP (" .. response .. ")";
							SendChatMessage(message, CHANNEL, CEPGP_Info.Language);
						else
							local message = "Awarded " .. itemName .. " to ".. player .. " for " .. gpValue*rate .. " GP";
							SendChatMessage(message, CHANNEL, CEPGP_Info.Language);
						end
						CEPGP_addGP(player, gpValue*rate, id, link, nil, response);
					else
						if CEPGP_Info.Guild.Roster[player] then
							local index = CEPGP_Info.Guild.Roster[player][1];
							local EP, GP = CEPGP_getEPGP(player, index);
							if response then
								if response == "Highest Roll (Free)" then
									SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free (Highest Roll)", CHANNEL, CEPGP_Info.Language);
									CEPGP_addTraffic(player, UnitName("player"), response, EP, EP, GP, GP, id, tStamp);
								else
									SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free", CHANNEL, CEPGP_Info.Language);
									CEPGP_addTraffic(player, UnitName("player"), "Given for Free", EP, EP, GP, GP, id, tStamp);
								end
							else
								SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free", CHANNEL, CEPGP_Info.Language);
								CEPGP_addTraffic(player, UnitName("player"), "Given for Free", EP, EP, GP, GP, id, tStamp);
							end
						else
							local index = CEPGP_getIndex(player);
							if index then
								SendChatMessage("Awarded " .. itemName .. " to ".. player .. " for free (Exclusion List)", CHANNEL, CEPGP_Info.Language);
								CEPGP_addTraffic(player, UnitName("player"), "Given for Free (Exclusion List)", nil, nil, nil, nil, id, tStamp);
							end
						end
					end
					
				else
					SendChatMessage(itemName .. " has been distributed without EPGP", CHANNEL, CEPGP_Info.Language);
					CEPGP_addTraffic("", UnitName("player"), "Manually Awarded", "", "", "", "", id, tStamp);
				end
			end;
			if CEPGP_ntgetn(CEPGP_Info.Guild.Roster) < (GetNumGuildMembers() - CEPGP_Info.NumExcluded) and CEPGP_Info.Polling then
				table.insert(CEPGP_Info.RosterStack, callback);
			else
				callback();
			end
		end
		
		CEPGP_LootFrame_Update();
	end	
end