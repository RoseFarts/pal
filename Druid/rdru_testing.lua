-- Restoration Druid for 8.1 enhanced by jh0nny - 2/2019
-- Restoration Druid for 8.1 by Tacotits - 9/2018 (fixed by laks later, enhanced by jh0nny)
-- Talents: Raid=3133213 Dungeon=1133212
-- Holding Alt = Efflorescence
-- Holding CTRL = Cleanse - mouseover and Battle Ressurrect if mouseover is dead
-- Holding Shift =

local dark_addon = dark_interface
local SB = dark_addon.rotation.spellbooks.druid
local TB = dark_addon.rotation.talentbooks.druid
local DB = dark_addon.rotation.dispellbooks.druid
local DS = dark_addon.rotation.dispellbooks.soothe

local outdoor = IsOutdoors()
local indoor = IsIndoors()
local realmName = GetRealmName()
local race = UnitRace("player")
local x = 0 -- counting seconds in resting
local y = 0 -- counter for opener
local z = 0 -- time in combat
local lftime = 0 -- Timer for Dungeon/Battleground Joining
local photosyn = 0 -- Lifebloom counter

SB.Refreshment = 167152
SB.Drink = 274914
SB.ReplenishmentDebuff = 252753
SB.Regrowth = 8936
SB.SolarWrathResto = 5176
SB.GiftOftheNaaru = 59544
SB.AncestralCall = 274738
SB.LightsJudgement = 255647

local function combat()

-- Dead, Travelform, Resting or Channeling in Combat
if not player.alive or player.buff(SB.TravelForm).exists or player.buff(SB.Refreshment).up or player.buff(SB.Drink).up or player.channeling() then
	return
end

local photosyn = group.count(function (unit)
	return unit.health.percent < 75 and unit.distance < 30
end)

-------------------
-- Fetch Settings--
-------------------
local current_rejuvs = group.count(function (unit)
  return unit.alive and unit.distance < 40 and unit.buff(SB.Rejuvenation).up
end)
local max_rejuvs = dark_addon.settings.fetch('respal_settings_max_rejuvs', 10)
local wildgrowth_percent = dark_addon.settings.fetch('respal_settings_wildgrowth_percent', 80)
local wildgrowth_number = dark_addon.settings.fetch('respal_settings_wildgrowth_number', 3)
local barkskin_percent = dark_addon.settings.fetch('respal_settings_barkskin_percent', 60)
local racial_use = dark_addon.settings.fetch('respal_settings_racial_use.check', true)
local racial_percent = dark_addon.settings.fetch('respal_settings_racial_percent.spin', 50)
local use_healthstone = dark_addon.settings.fetch('respal_settings_use_healthstone.check', true)
local healthstone_percent = dark_addon.settings.fetch('respal_settings_use_healthstone.spin', 25)
local use_healing_potion = dark_addon.settings.fetch('respal_settings_use_healing_potion.check', false)
local ironbark_percent = dark_addon.settings.fetch('respal_settings_ironbark_percent', 66)
local flourish_percent = dark_addon.settings.fetch('respal_settings_flourish_percent', 75)
local trinket_use = dark_addon.settings.fetch('respal_settings_trinket_use.check', true)
local trinkets_percent = dark_addon.settings.fetch('respal_settings_trinket_use.spin', 75)

------------
-- Utility--
------------
-- Self Defensives
if player.castable(SB.Barkskin) and player.health.percent < barkskin_percent then
	return cast(SB.Barkskin, player)
end

-- Innervate and spam costly spells
if player.castable(SB.Innervate) and player.power.mana.percent < 90 then
	return cast(SB.Innervate, player)
end

-- Use Healthstone or BFA Healing Potion
if use_healthstone == true and GetItemCount(5512) >= 1 and GetItemCooldown(5512) == 0 and player.health.percent < healthstone_percent then
	macro('/use Healthstone')
end

if use_healing_potion == true and GetItemCount(152494) >= 1 and GetItemCooldown(152494) == 0 and GetItemCooldown(5512) > 0 and player.health.percent < healthstone_percent then
	macro('/use Coastal Healing Potion')
end


--Trinket Use
if trinket_use == true then
	local GearSlot13 = GetInventoryItemID("player", 13)
	if IsUsableItem(GearSlot13) and GetItemCooldown(GearSlot13) == 0 and tank.health.percent < trinkets_percent and tank.distance < 35 then
		macro('/use [help] 13; [@targettarget] 13')
	end

	local GearSlot14 = GetInventoryItemID("player", 14)
	if IsUsableItem(GearSlot14) and GetItemCooldown(GearSlot14) == 0 and tank.health.percent < trinkets_percent and tank.distance < 35 then
		macro('/use [help] 14; [@targettarget] 14')
	end
end

--------------
-- Modifiers--
--------------
-- Efflorence
if modifier.alt and not lastcast(SB.Efflorescence) then
	return cast(SB.Efflorescence, 'ground')
end

-- Dispel or Battle Rezz mouseover
if modifier.control then
	if mouseover.alive and -spell(SB.NaturesCure) == 0 then
		return cast(SB.NaturesCure, 'mouseover')
		
	elseif not mouseover.alive and -spell(SB.Rebirth) == 0 then
		return cast(SB.Rebirth, 'mouseover')
	end
end

-------------
-- Racials---
-------------
if racial_use == true then
	if race == "Orc" and castable(SB.BloodFury) then
		return cast(SB.BloodFury)
	end
	if race == "Troll" and -spell(SB.Berserking) == 0 and tank.health.percent <= racial_percent then
		return cast(SB.Berserking)
	end
	if race == "Mag'har Orc" and castable(SB.AncestralCall) then
		return cast(SB.AncestralCall)
	end
	if race == "LightforgedDraenei" and castable(SB.LightsJudgement) then
		return cast(SB.LightsJudgement)
	end
	if race == "Draenei" and lowest.castable(SB.GiftOftheNaaru) and lowest.health.effective <= racial_percent then
		return cast(SB.GiftOftheNaaru, lowest)
	end
end

---------------------
-- Healing Rotation--
---------------------
-- Healing Cooldowns
if toggle('cooldowns') then
	-- Ironbark
	if toggle('IronBark', false) then
		if tank.castable(SB.Ironbark) and tank.health.percent < ironbark_percent then
			return cast(SB.Ironbark, tank)
		end
	end
	-- Flourish
	if talent(7, 3) and group.under(flourish_percent, 60, true) or lastcast(SB.Tranquility) and -spell(SB.Flourish) == 0 then
		return cast(SB.Flourish)
	end
	-- Keep Lifebloom on an active tank
	if photosyn >=4 and talent(7,1) then
		if player.castable(SB.Lifebloom) and player.buff(SB.Lifebloom).down and not lastcast(SB.Lifebloom) then
			return cast(SB.Lifebloom, player)
		end
	end
	if photosyn < 4 and talent(7,1) then
		if tank.castable(SB.Lifebloom) and tank.buff(SB.Lifebloom).down and tank.health.percent <= 98 and not lastcast(SB.Lifebloom) then
			return cast(SB.Lifebloom, tank)
		end
	end
	if not talent(7,1) then
		if tank.castable(SB.Lifebloom) and tank.buff(SB.Lifebloom).down and tank.health.percent <= 98 and not lastcast(SB.Lifebloom) then
			return cast(SB.Lifebloom, tank)
		end
	end
	-- Cenarion Ward on cooldown
    if talent(1, 3) and tank.castable(SB.CenarionWard) and tank.buff(SB.CenarionWard).down then
        return cast(SB.CenarionWard, tank)
    end
end

--soothe Enrages
if target.castable(SB.Soothe) then
	for i = 1, 40 do
		local name, _, _, count, debuff_type, _, _, _, _, spell_id = UnitAura("target", i)
		if name and DS[spell_id] then
			print("Soothing " .. name .. " off the target.")
			return cast(SB.Soothe, target)
		end
	end
end

-- Auto-Dispel
if toggle('dispell', false) then
	-- self-cleanse
	if castable(SB.NaturesCure) and player.dispellable(SB.NaturesCure) then
		return cast(SB.NaturesCure, player)
	end
	-- group cleanse
	local unit = group.dispellable(SB.NaturesCure)
	if unit and unit.castable(SB.NaturesCure) then
		return cast(SB.NaturesCure, unit)
	end
end

-- Use Wild Growth
if (lowest.castable(SB.WildGrowth) and group.under(wildgrowth_percent, 30, true) >= wildgrowth_number)
or (player.buff(SB.Innervate).up and lowest.castable(SB.WildGrowth)) and not player.moving then
	return cast(SB.WildGrowth, lowest)
end

-- Use Swiftmend
if tank.castable(SB.Swiftmend) and (tank.buff(SB.Rejuvenation).up or tank.buff(SB.Regrowth).up) and tank.health.percent <= 75 then
	return cast(SB.Swiftmend, tank)
end
if lowest.castable(SB.Swiftmend) and (tank.buff(SB.Rejuvenation).up or tank.buff(SB.Regrowth).up) and lowest.health.percent <= 75 then
	return cast(SB.Swiftmend, lowest)
end

-- Rejuvenation
if tank.castable(SB.Rejuvenation) and tank.buff(SB.Rejuvenation).down and tank.health.percent <= 98 then
	return cast(SB.Rejuvenation, tank)
end
if lowest.castable(SB.Rejuvenation) and lowest.buff(SB.Rejuvenation).down and current_rejuvs <= max_rejuvs and lowest.health.percent <= 95 then
	return cast(SB.Rejuvenation, lowest)
end

-- Use Clearcasting procs
if player.buff(SB.Clearcasting).up and lowest.castable(SB.Regrowth) and lowest.health.percent < 80 and not player.moving then
	return cast(SB.Regrowth, lowest)
end

-- Use Regrowth as an emergency heal.
if not IsInRaid() then
	if (tank.castable(SB.Regrowth) and tank.health.percent <= 70)
	or (player.buff(SB.Innervate).up and tank.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, tank)
	end
	if (lowest.castable(SB.Regrowth) and lowest.health.percent <= 50)
	or (player.buff(SB.Innervate).up and lowest.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, lowest)
	end
end
if IsInRaid() then
	if (tank.castable(SB.Regrowth) and tank.health.percent <= 50)
	or (player.buff(SB.Innervate).up and tank.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, tank)
	end
	if (lowest.castable(SB.Regrowth) and lowest.health.percent <= 40)
	or (player.buff(SB.Innervate).up and lowest.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, lowest)
	end
end

-- Rejuvenation Germination
if talent(7, 2) then
    if tank.castable(SB.Rejuvenation) and tank.buff(SB.Rejuvenation).up and tank.buff(SB.RejuvenationGermination).down and tank.health.percent <= 85 then
        return cast(SB.Rejuvenation, tank)
    end
    if lowest.castable(SB.Rejuvenation) and lowest.buff(SB.Rejuvenation).up and lowest.buff(SB.RejuvenationGermination).down 
	and current_rejuvs <= max_rejuvs and lowest.health.percent < 80 then
        return cast(SB.Rejuvenation, lowest)
    end
end

--------------------
-- Damage Rotation--
--------------------
if toggle('dps', false) and not isCC("target") then
if target.castable(SB.Sunfire) and target.debuff(SB.Sunfire).remains <= 3 and -power.combopoints <= 5 then
	return cast(SB.Sunfire, target)
end

if target.castable(SB.Moonfire) and target.debuff(SB.Moonfire).remains <= 3 and -power.combopoints <= 5 then
	return cast(SB.Moonfire, target)
end

-- Catweaving
if castable(SB.CatForm, player) and not -buff(SB.CatForm) and target.distance <= 8 and talent(3,2) then
	return cast(SB.CatForm, player)
end

if -buff(SB.CatForm) and target.distance <= 8 and talent(3,2) then
	if enemies.around(8) < 2 then
		if castable(SB.Rake) and -power.combopoints <= 4 and -power.energy >= 35 and target.debuff(SB.RakeDebuff).remains <= 2 then
			return cast(SB.Rake, target)
		end
	
		if castable(SB.Shred) and -power.combopoints <= 4 and -power.energy >= 40 then
			return cast(SB.Shred, target)
		end
	end
		
	if enemies.around(8) >= 2 then
		if castable(SB.SwipeCat) and -power.combopoints <= 4 and -power.energy >= 35 then
			return cast(SB.SwipeCat, target)
		end
	end
		
	if castable(SB.FerociousBite) and -power.combopoints == 5 and -power.energy >= 50 then
		return cast(SB.FerociousBite, target)
	end	
end

if target.castable(SB.SolarWrathResto) and not player.moving and not talent(3,2) then
	return cast(SB.SolarWrathResto, target)
end
end
end

local function resting()

-------------------
-- Fetch Settings--
-------------------
local current_rejuvs = group.count(function (unit)
  return unit.alive and unit.distance < 40 and unit.buff(SB.Rejuvenation).up
end)
local max_rejuvs = dark_addon.settings.fetch('respal_settings_max_rejuvs', 10)
local wildgrowth_percent = dark_addon.settings.fetch('respal_settings_wildgrowth_percent', 80)
local wildgrowth_number = dark_addon.settings.fetch('respal_settings_wildgrowth_number', 3)
local barkskin_percent = dark_addon.settings.fetch('respal_settings_barkskin_percent', 60)
local racial_use = dark_addon.settings.fetch('respal_settings_racial_use.check', true)
local racial_percent = dark_addon.settings.fetch('respal_settings_racial_percent.spin', 50)
local use_healthstone = dark_addon.settings.fetch('respal_settings_use_healthstone.check', true)
local healthstone_percent = dark_addon.settings.fetch('respal_settings_use_healthstone.spin', 25)
local use_healing_potion = dark_addon.settings.fetch('respal_settings_use_healing_potion.check', false)
local ironbark_percent = dark_addon.settings.fetch('respal_settings_ironbark_percent', 66)
local flourish_percent = dark_addon.settings.fetch('respal_settings_flourish_percent', 75)
local trinket_use = dark_addon.settings.fetch('respal_settings_trinket_use.check', true)
local trinkets_percent = dark_addon.settings.fetch('respal_settings_trinket_use.spin', 75)

local lfg = GetLFGProposal();
local hasData = GetLFGQueueStats(LE_LFG_CATEGORY_LFD);
local hasData2 = GetLFGQueueStats(LE_LFG_CATEGORY_LFR);
local hasData3 = GetLFGQueueStats(LE_LFG_CATEGORY_RF);
local hasData4 = GetLFGQueueStats(LE_LFG_CATEGORY_SCENARIO);
local hasData5 = GetLFGQueueStats(LE_LFG_CATEGORY_FLEXRAID);
local hasData6 = GetLFGQueueStats(LE_LFG_CATEGORY_WORLDPVP);
local bgstatus = GetBattlefieldStatus(1);
local autojoin = dark_addon.settings.fetch('respal_settings_autojoin', true)

---------------
-- Auto Forms--
---------------
local outdoor = IsOutdoors()
if player.alive then
	if (player.buff(SB.TravelForm).exists and player.moving) or player.buff(SB.Refreshment).up or player.buff(SB.Drink).up then
		return
	end

	if toggle('Forms', false) and player.moving and player.buff(SB.Prowl).down and player.buff(SB.TigerDashBuff).down and player.buff(1850).down then
		x = x + 1
		if player.moving and player.buff(SB.CatForm).up and -spell(SB.Dash) == 0 then
			return cast(SB.Dash)
		end
		if outdoor and x >= 20 then
			x = 0
				return cast(SB.TravelForm)
		end

		if not outdoor and x >= 8 and player.buff(SB.CatForm).down then
			x = 0
			return cast(SB.CatForm)
		end
	elseif toggle('Forms', false) and not player.moving and player.buff(SB.Prowl).down and player.buff(SB.TigerDashBuff).down and player.buff(1850).down and player.alive then
		y = y + 1
		if y >= 20 then
			y = 0
			macro('/cancelform')
		end
	end
end

--------------
-- Auto Join--
--------------
  if autojoin == true and hasData == true or hasData2 == true or hasData4 == true or hasData5 == true or hasData6 == true or bgstatus == "queued" then
    SetCVar ("Sound_EnableSoundWhenGameIsInBG",1)
  elseif autojoin == false and hasdata == nil or hasData2 == nil or hasData3 == nil or hasData4 == nil or hasData5 == nil or hasData6 == nil or bgstatus == "none" then
    SetCVar ("Sound_EnableSoundWhenGameIsInBG",0)
  end

  if autojoin ==true and lfg == true or bgstatus == "confirm" then
    PlaySound(SOUNDKIT.IG_PLAYER_INVITE, "Dialog");
    lftime = lftime + 1
  end

  if lftime >=math.random(20,35) then
    SetCVar ("Sound_EnableSoundWhenGameIsInBG",0)
    macro('/click LFGDungeonReadyDialogEnterDungeonButton')
    lftime = 0
  end
  
--------------
-- Modifiers--
--------------
-- Efflorence
if modifier.alt and not lastcast(SB.Efflorescence) then
	return cast(SB.Efflorescence, 'ground')
end
end

local function interface()
  local settings = {
    key = 'respal_settings',
    title = 'Restoration Pal - Settings',
    width = 250,
    height = 750,
    resize = true,
    show = false,
    template = {
      { type = 'header', text = 'Restoration Pal - Settings', align= 'center' },
      { type = 'rule' },
      { type = 'rule' },
      { type = 'header', text = 'Class Settings', align= 'center' },
      { key = 'ironbark_percent', type = 'spinner', text = 'Iron Bark', desc = 'Health Percent to Cast At', default = 66,  min = 1, max = 100, step = 5 },
      { type = 'rule' },
      { type = 'header', text = 'Wild Growth Settings', align= 'center' },
      { key = 'wildgrowth_percent', type = 'spinner', text = 'Wild Growth', desc = 'Health Percent to Cast At', default = 80,  min = 1, max = 100, step = 5 },
      { key = 'wildgrowth_number', type = 'spinner', text = 'Wild Growth Targets', desc = 'Minimum Wild Growth Targets', default = 3, min = 1, max = 40, step = 1 },
      { type = 'rule' },
      { type = 'header', text = 'Rejuvenation', align= 'center' },
      { key = 'max_rejuvs', type = 'spinner', text = 'Max Rejuvenation Targets', desc = 'Maximum Rejuvenation Targets', default = 10, min = 1, max = 20, step = 1 },
      { type = 'rule' },
      { type = 'header', text = 'Flourish', align= 'center' },
      { key = 'flourish_percent', type = 'spinner', text = 'Flourish', desc = 'Health Percent to Cast At', default = 75,  min = 1, max = 100, step = 5 },
      { type = 'rule' },
      { type = 'header', text = 'Defensives', align= 'center' },
      { key = 'barkskin_percent', type = 'spinner', text = 'Barkskin', desc = 'Health Percent to Cast At', default = 60, min = 1, max = 100, step = 5 },
      { key = 'use_healthstone', type = 'checkspin', text = 'Healthstone', desc = 'Auto use Healthstone at health %', default_check = true, default_spin = 30, min = 5, max = 100, step = 5 },
	  { key = 'use_healing_potion', type = 'checkbox', text = 'Healing Potion', desc = 'Auto use Healing Potion', default = false },
      { type = 'rule' },
      { type = 'header', text = 'Utility', align= 'center' },
	  { key = 'racial_use', type = 'checkspin', text = 'Racial', desc = 'Auto use Racial at tank health %', default_check = true, default_spin = 50, min = 5, max = 100, step = 5 },
	  { key = 'trinket_use', type = 'checkspin', text = 'Trinkets', desc = 'Auto use Trinkets at tank health %', default_check = true, default_spin = 75, min = 5, max = 100, step = 5 },
      { key = 'autojoin', type = 'checkbox', text = 'Auto Join', desc = 'Automatically accept Dungeon/Battleground Invites', default = true },

    }
  }  
  configWindow = dark_addon.interface.builder.buildGUI(settings)

    dark_addon.interface.buttons.add_toggle({
        name = 'IronBark',
        label = 'IronBark',
        on = {
            label = 'Bark ON',
            color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = 'Bark OFF',
            color = dark_addon.interface.color.red,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.red, 0.5)
        }
    })
    dark_addon.interface.buttons.add_toggle({
        name = 'Forms',
        label = 'change forms',
        on = {
            label = 'Forms ON',
            color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = 'Forms OFF',
            color = dark_addon.interface.color.red,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.red, 0.5)
        }
    })
        dark_addon.interface.buttons.add_toggle({
        name = 'dps',
        label = 'Use Damage Spells',
        on = {
            label = 'DPS ON',
            color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = 'DPS OFF',
            color = dark_addon.interface.color.red,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.red, 0.5)
        }
        })
        dark_addon.interface.buttons.add_toggle({
        name = 'dispell',
        label = 'dispell',
        on = {
            label = 'Dispell ON',
            color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = 'Dispell OFF',
             color = dark_addon.interface.color.red,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.red, 0.5)
        }
    })
        dark_addon.interface.buttons.add_toggle({
        name = 'settings',
        label = 'Rotation Settings',
        font = 'dark_addon_icon',
        on = {
            label = dark_addon.interface.icon('cog'),
            color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = dark_addon.interface.icon('cog'),
             color = dark_addon.interface.color.red,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.red, 0.5)
        },
        callback = function(self)
            if configWindow.parent:IsShown() then
                configWindow.parent:Hide()
            else
                configWindow.parent:Show()
            end
        end
    })
end

dark_addon.rotation.register({
    spec = dark_addon.rotation.classes.druid.restoration,
    name = 'respal',
    label = 'PAL - restoration druid',
    gcd = gcd,
    combat = combat,
    resting = resting,
    interface = interface
})
