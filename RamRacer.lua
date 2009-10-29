--[[
IMPORTANT EVENTS:

Brewfest Prize Token:
event="CHAT_MSG_LOOT"
arg1="You create: ||cff1eff00||Hitem:37829:0:0:0:0:0:0:904900864:80||h[Brewfest Prize Token]||h||rx2."
arg7=0
arg8=0

Portable Brewfest Keg
arg1="You receive item: ||cffffffff||Hitem:33797:0:0:0:0:0:0:1915698176:80||h[Portable Brewfest Keg]||h||r."
arg7=0
arg8=0

Ram Racing Reins
event="CHAT_MSG_LOOT"
arg1="You create: ||cffffffff||Hitem:33306:0:0:0:0:0:0:1176514688:80||h[Ram Racing Reins]||h||r."
arg7=0
arg8=0
]]



local L = setmetatable({}, {__index=function(t,i) return i end})
local defaults, defaultsPC, db, dbpc = {}, {}

local function Print(...) print("|cFF33FF99RamRacer|r:", ...) end
local debugf = tekDebug and tekDebug:GetFrame("RamRacer")
local function Debug(...) if debugf then debugf:AddMessage(string.join(", ", tostringall(...))) end end

local trackerActive = nil
local totalCoins = 0
local startTime 

local f = CreateFrame("frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("ADDON_LOADED")

function f:ADDON_LOADED(event, addon)
	if addon:lower() ~= "ramracer" then return end

	RamRacerDB, RamRacerDBPC = setmetatable(RamRacerDB or {}, {__index = defaults}), setmetatable(RamRacerDBPC or {}, {__index = defaultsPC})
	db, dbpc = RamRacerDB, RamRacerDBPC

	-- Do anything you need to do after addon has loaded

	LibStub("tekKonfig-AboutPanel").new(nil, "RamRacer") -- Make first arg nil if no parent config panel

	self:UnregisterEvent("ADDON_LOADED")
	self.ADDON_LOADED = nil

	if IsLoggedIn() then self:PLAYER_LOGIN() else self:RegisterEvent("PLAYER_LOGIN") end
end


function f:PLAYER_LOGIN()
	self:RegisterEvent("PLAYER_LOGOUT")

	self:RegisterEvent("CHAT_MSG_LOOT")
	self:RegisterEvent("GOSSIP_SHOW")

	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function f:PLAYER_LOGOUT()
	for i,v in pairs(defaults) do if db[i] == v then db[i] = nil end end
	for i,v in pairs(defaultsPC) do if dbpc[i] == v then dbpc[i] = nil end end
end

local function GetLootedItemInfo(msg)
	local loot = string.gsub(LOOT_ITEM_PUSHED_SELF, "%%s%.","")
	local create = string.gsub(LOOT_ITEM_CREATED_SELF, "%%s%.", "")

	if string.match(msg,loot) or string.match(msg, create) then
		local itemId, amount = string.match(msg, "item:(%d+).*|rx?([0-9]*)")
		if itemId then
			itemId = tonumber(itemId)
			local count = nil
			local found = false
			if amount == "" or amount == nil then count = 1 else count = tonumber(amount) end  
			Debug("Found", msg, itemId, amount)
		end
		return itemId, count
	else
		Debug("Not found", msg)
	end
end

function f:CHAT_MSG_LOOT(event, msg)
	local itemId, count = GetLootedItemInfo(msg)
	if itemId and trackerActive and itemId==37829 then
		totalCoins = totalCoins + count
	end
end

StaticPopupDialogs["RAMRACER_CONFIRM"] = {
  text = "Start ram racing tracker and begin the event?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function()
		trackerActive = true
		startTime = time()
		f:RegisterEvent("PLAYER_AURAS_CHANGED")
		SelectGossipOption(1)
  end,
  timeout = 0,
  whileDead = false,
  hideOnEscape = true,
}

function f:GOSSIP_SHOW()
	local target = UnitName("target")
	local option = GetGossipOptions()
	if target=="Neill Ramstein" and option=="I'm ready to work for you today!  Give me the good stuff!" then
		StaticPopup_Show("RAMRACER_CONFIRM")
	end
end

function f:PLAYER_AURAS_CHANGED()
	local index = 1
	local found = nil

	-- Scan for the ram buff
	local name = UnitBuff("player", index)
	while name ~= nil do
		if name=="Rental Raxing Ram" then found = true end
		index = index + 1
		name = UnitBuff("player", index)
	end

	if found and not hasBuff  then
		-- We're on the ram now
		hasBuff = true
	end

	if hasBuff and not found then
		-- We lost the ram! Game over!
		-- stop the tracker and print the results
		trackerActive = false
		f:UnregisterEvent("PLAYER_AURAS_CHANGED")
		local elapsedTime = difftime(time(), startTime)

		Print("DONE! You got " .. totalCoins .. " coins in " .. elapsedTime .. "seconds")
	end
end

--[[
SLASH_RAMRACER1 = "/rr"
SLASH_RAMRACER2 = "/ramracer"
SlashCmdList.RAMRACER = function(msg)
	-- Do crap here
end

local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("RamRacer") or ldb:NewDataObject("RamRacer", {type = "launcher", icon = "Interface\\Icons\\Spell_Nature_GroundingTotem"})
dataobj.OnClick = SlashCmdList.RAMRACER
]]
