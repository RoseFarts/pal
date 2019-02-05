-- Restoration Druid for 8.1 by Tacotits - 9/2018  (fixed by laks later)
-- Restoration Druid for 8.1 by Tacotits - 9/2018
-- Talents: Raid=3133213 Dungeon=1133212
-- Holding Alt = Efflorescence
-- Holding CTRL = Cleanse - mouseover and Battle Ressurrect if mouseover is dead
-- Holding Shift =
-- TODO: Flourish Logic = Count how many Hots are active in total and watch the cooldowns for all of them so we can if < 8 seconds are remaining, Rejuv Spinners, Regrowth Spinners, Swiftmend Spinners




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

SB.Refreshment = 167152
SB.Drink = 274914
SB.ReplenishmentDebuff = 252753
SB.Regrowth = 8936
SB.SolarWrathResto = 5176
SB.GiftOftheNaaru = 59544
SB.AncestralCall = 274738
SB.LightsJudgement = 255647

local function gcd()
	return
end

local function combat()
    if not player.alive or player.buff(SB.TravelForm).exists or player.buff(SB.Refreshment).up or player.buff(SB.Drink).up or player.channeling() then
        return
    end
-------------
----Fetch----
-------------
local max_rejuvs = group.count(function (unit)
  return unit.alive and unit.distance < 40 and unit.buff(SB.Rejuvenation).up
end)
local simultaneousrejuvenations = dark_addon.settings.fetch('respal_settings_simultaneousrejuvenations', 10)
local wildgrowthpercent = dark_addon.settings.fetch('respal_settings_wildgrowthpercent', 80)
local wildgrowthnumber = dark_addon.settings.fetch('respal_settings_wildgrowthnumber', 3)
local barkskinpercent = dark_addon.settings.fetch('respal_settings_barkskinpercent', 60)
local usehealthstone = dark_addon.settings.fetch('respal_settings_healthstone.check', true)
local healthstonepercent = dark_addon.settings.fetch('respal_settings_healthstone.spin', 25)
local ironbarkpercent = dark_addon.settings.fetch('respal_settings_ironbarkpercent', 66)
local flourishpercent = dark_addon.settings.fetch('respal_settings_flourishpercent', 75)

-------------
---Utility---
-------------
--Health Stone
    if usehealthstone == true and player.health.percent < healthstonepercent and GetItemCount(5512) >= 1 and GetItemCooldown(5512) == 0 then
        macro('/use Healthstone')
    end

-- Innervate should be used as many times during the fight as possible. Refresh Efflorescence, cast Wild Growth, and spam Rejuvenation during Innervate.
    if player.castable(SB.Innervate) and player.power.mana.percent < 90 then
        return cast(SB.Innervate, player)
    end

-- Barkskin
    if player.castable(SB.Barkskin) and player.health.percent < barkskinpercent then
        return cast(SB.Barkskin, player)
    end
    
--Trinket Use
    --trinket slot 1
    local GearSlot13 = GetInventoryItemID("player", 13)
	if IsUsableItem(GearSlot13) and GetItemCooldown(GearSlot13) == 0 and tank.health.percent < 70 and tank.distance < 40 then
        macro('/use [help] 13; [@targettarget] 13')
    end
    -- trinket slot 2
    local GearSlot14 = GetInventoryItemID("player", 14)
    if IsUsableItem(GearSlot14) and GetItemCooldown(GearSlot14) == 0 and tank.health.percent < 70 and tank.distance < 40 then
	    macro('/use [help] 14; [@targettarget] 14')
	end

-------------
--Modifiers--
-------------
-- Efflorence
    if modifier.alt and not lastcast(SB.Efflorescence) then
        return cast(SB.Efflorescence, 'ground')
    end

    if modifier.control then
        if mouseover.alive and -spell(SB.NaturesCure) == 0 then
            return cast(SB.NaturesCure, 'mouseover')

        elseif not mouseover.alive and -spell(SB.Rebirth) == 0 then
            return cast(SB.Rebirth, 'mouseover')
        end
    end
	
if modifier.shift and target.alive and target.enemy and not player.channeling() and talent(3,2) then
	if target.castable(SB.Sunfire) and target.debuff(SB.Sunfire).down then
		return cast(SB.Sunfire, target)
	end

	if target.castable(SB.Moonfire) and target.debuff(SB.Moonfire).down then
		return cast(SB.Moonfire, target)
	end

	if castable(SB.CatForm, 'player') and not -buff(SB.CatForm) then
		return cast(SB.CatForm, 'player')
	end
	
	if -buff(SB.CatForm) and target.distance <= 8 then
		if enemies.around(8) < 2 then
			if castable(SB.Rake) and -power.combopoints <= 4 and -power.energy >= 55 and target.debuff(SB.RakeDebuff).remains <= 3 then
				return cast(SB.Rake)
			end
	
			if castable(SB.Shred) and -power.combopoints <= 4 and -power.energy >= 60 then
				return cast(SB.Shred)
			end
		end
		
		if enemies.around(8) >= 2 then
			if castable(SB.SwipeCat) and -power.combopoints <= 4 and -power.energy >= 60 then
				return cast(SB.SwipeCat)
			end
		end
		
		if castable(SB.FerociousBite) and -power.combopoints == 5 and -power.energy >= 65 then
			return cast(SB.FerociousBite)
		end	
	end
end

-------------
---Racials---
-------------
    if toggle('racial', false) then
        if race == "Orc" and castable(SB.BloodFury) then
            return cast(SB.BloodFury)
        end
        if race == "Troll" and -spell(SB.Berserking) == 0 and tank.health.percent <= 70 then
            return cast(SB.Berserking)
        end
        if race == "Mag'har Orc" and castable(SB.AncestralCall) then
            return cast(SB.AncestralCall)
        end
        if race == "LightforgedDraenei" and castable(SB.LightsJudgement) then
            return cast(SB.LightsJudgement)
        end
        if race == "Draenei" and lowest.castable(SB.GiftOftheNaaru) and lowest.health.effective >= 50 then
            return cast(SB.GiftOftheNaaru, lowest)
        end
    end


--- Healing Cooldowns
    if toggle('cooldowns') then

        if toggle('IronBark', false) then
            if tank.castable(SB.Ironbark) and tank.health.percent < ironbarkpercent then
                return cast(SB.Ironbark, tank)
            end
        end
--Flourish
        if talent(7, 3) and group.under(flourishpercent, 60, true) or lastcast(SB.Tranquility) and -spell(SB.Flourish) == 0 then
            return cast(SB.Flourish)
        end

-- Keep Lifebloom on an active tank, or on self if talent(7,1)
        --if talent(7,1) and group.under(50, 30, true) and player.castable(SB.Lifebloom) and player.buff(SB.Lifebloom).down and not lastcast(SB.Lifebloom) then
            --return cast(SB.Lifebloom, player)
        --end
        if tank.castable(SB.Lifebloom) and tank.buff(SB.Lifebloom).down and not lastcast(SB.Lifebloom) then
            return cast(SB.Lifebloom, tank)
        end
    end

--soothe
    if target.castable(SB.Soothe) then
        for i = 1, 40 do
            local name, _, _, count, debuff_type, _, _, _, _, spell_id = UnitAura("target", i)
            if name and DS[spell_id] then
                print("Soothing " .. name .. " off the target.")
                return cast(SB.Soothe, target)
            end
        end
    end

--- Decurse
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

--- Healing
-- Use Clearcasting procs to cast Regrowth on any person in the raid.
    if player.buff(SB.Clearcasting).up and lowest.castable(SB.Regrowth) and lowest.health.percent < 80
            and not player.moving then
        return cast(SB.Regrowth, lowest)
    end
-- Use Cenarion Ward on cooldown.
    if talent(1, 3) and tank.castable(SB.CenarionWard) and tank.buff(SB.CenarionWard).down then
        return cast(SB.CenarionWard, tank)
    end


-- Keep Rejuvenation, on the tank and on members of the group that just took damage or are about to take damage.
    if tank.castable(SB.Rejuvenation) and (tank.buff(SB.Rejuvenation).down and max_rejuvs <= simultaneousrejuvenations or (talent(7, 2)
            and tank.buff(SB.RejuvenationGermination).down)) then
        return cast(SB.Rejuvenation, tank)
    end
    if lowest.castable(SB.Rejuvenation) and (lowest.buff(SB.Rejuvenation).down and max_rejuvs <= simultaneousrejuvenations and lowest.health.percent < 100)
            or (talent(7, 2) and lowest.buff(SB.RejuvenationGermination).down
            and (lowest.health.percent < 80 or player.buff(SB.Innervate))) then
        return cast(SB.Rejuvenation, lowest)
    end

-- Use Wild Growth, when at least 4/6 members of the group/raid are damaged.

    if (lowest.castable(SB.WildGrowth) and not player.moving and group.under(wildgrowthpercent, 30, true) >= wildgrowthnumber) or
       (player.buff(SB.Innervate).up and lowest.castable(SB.WildGrowth) and not player.moving )then
		return cast(SB.WildGrowth, lowest)
    end
-- Use Swiftmend on a player that just took heavy damage. If not in immediate danger, use Rejuvenation first.
    if lowest.castable(SB.Swiftmend)
            and (lowest.buff(SB.Rejuvenation).up and lowest.health.percent <= 75 or lowest.health.percent <= 50) then
        return cast(SB.Swiftmend, lowest)
    end
    if tank.castable(SB.Swiftmend) and tank.health.percent <= 75 then
        return cast(SB.Swiftmend, tank)
    end

-- Use Regrowth as an emergency heal.
    if not IsInRaid() then
        if (tank.castable(SB.Regrowth) and not player.moving and tank.health.percent <= 70) or
	   (player.buff(SB.Innervate).up and tank.castable(SB.Regrowth) and not player.moving) then
           	return cast(SB.Regrowth, tank)
        end
        if (lowest.castable(SB.Regrowth) and not player.moving and lowest.health.percent <= 50) or
	   (player.buff(SB.Innervate).up and lowest.castable(SB.Regrowth) and not player.moving) then
           	return cast(SB.Regrowth, lowest)
			
    elseif IsInRaid() then
        if (tank.castable(SB.Regrowth) and not player.moving and tank.health.percent <= 50) or
	   (player.buff(SB.Innervate).up and tank.castable(SB.Regrowth) and not player.moving) then
            	return cast(SB.Regrowth, tank)
        end
        if (lowest.castable(SB.Regrowth) and not player.moving and lowest.health.percent <= 40) or
	   (player.buff(SB.Innervate).up and lowest.castable(SB.Regrowth) and not player.moving) then
           	return cast(SB.Regrowth, lowest)
        end
    end
    end

-------------
-----DPS-----
-------------
--keep dots on target
--During downtime, use Moonfire, Sunfire and Solar Wrath on enemies to help with the damage.
    if player.power.mana.percent > 55 and lowest.health.percent > 55 and tank.health.percent > 55 and toggle('dps', false) and not isCC("target") then
        if target.castable(SB.Moonfire) and target.debuff(SB.Moonfire).down then
            return cast(SB.Moonfire, target)
        end
        if target.castable(SB.Sunfire) and target.debuff(SB.Sunfire).down then
            return cast(SB.Sunfire, target)
        end
    

    if target.castable(SB.SolarWrathResto) and not player.moving then
        return cast(SB.SolarWrathResto, target)
    end
    if target.castable(SB.Moonfire) and player.moving then
        return cast(SB.Moonfire, target)
    end
    end
end 
local function resting()

-------------
----Fetch----
-------------
local lfg = GetLFGProposal();
local hasData = GetLFGQueueStats(LE_LFG_CATEGORY_LFD);
local hasData2 = GetLFGQueueStats(LE_LFG_CATEGORY_LFR);
local hasData3 = GetLFGQueueStats(LE_LFG_CATEGORY_RF);
local hasData4 = GetLFGQueueStats(LE_LFG_CATEGORY_SCENARIO);
local hasData5 = GetLFGQueueStats(LE_LFG_CATEGORY_FLEXRAID);
local hasData6 = GetLFGQueueStats(LE_LFG_CATEGORY_WORLDPVP);
local bgstatus = GetBattlefieldStatus(1);
local autojoin = dark_addon.settings.fetch('respal_settings_autojoin', true)
local max_rejuvs = group.count(function (unit)
  return unit.alive and unit.distance < 40 and unit.buff(SB.Rejuvenation).up
end)
local simultaneousrejuvenations = dark_addon.settings.fetch('respal_settings_simultaneousrejuvenations', 10)
local wildgrowthpercent = dark_addon.settings.fetch('respal_settings_wildgrowthpercent', 80)
local wildgrowthnumber = dark_addon.settings.fetch('respal_settings_wildgrowthnumber', 3)
local barkskinpercent = dark_addon.settings.fetch('respal_settings_barkskinpercent', 60)
local usehealthstone = dark_addon.settings.fetch('respal_settings_healthstone.check', true)
local healthstonepercent = dark_addon.settings.fetch('respal_settings_healthstone.spin', 25)
local ironbarkpercent = dark_addon.settings.fetch('respal_settings_ironbarkpercent', 66)
  
-------------
----Forms----
-------------
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
-------------
--Auto Join--
-------------
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


-------------
--Modifiers--
-------------
    if modifier.lalt and -spell(SB.Efflorescence) == 0 then
        return cast(SB.Efflorescence, 'ground')
    end
-------------
----Heal-----
-------------
-- Keep Lifebloom, on an active tank.
    if IsInGroup() and tank.castable(SB.Lifebloom) and tank.buff(SB.Lifebloom).down and not lastcast(SB.Lifebloom) then
        return cast(SB.Lifebloom, tank)
    end
-- Swiftmend
    if player.castable(SB.Swiftmend) and player.health.percent < 50 then
        return cast(SB.Swiftmend, player)
    end
-- Rejuvenation
    if player.castable(SB.Rejuvenation) and not player.buff(SB.Rejuvenation).up and max_rejuvs <= simultaneousrejuvenations and player.health.percent < 75 then
        return cast(SB.Rejuvenation, player)
    end
-- Regrowth
    if player.castable(SB.Regrowth) and ((player.health.percent < 75 and not player.buff(SB.Regrowth).up) or player.health.percent < 30) then
        return cast(SB.Regrowth, player)
    end
-- Barkskin
    if player.castable(SB.Barkskin) and player.health.percent < 50 then
        return cast(SB.Barkskin, player)
    end
    if lowest.castable(SB.Rejuvenation) and (lowest.buff(SB.Rejuvenation).down and lowest.health.percent <= 95) and max_rejuvs <= simultaneousrejuvenations
            or (talent(7, 2) and lowest.buff(SB.RejuvenationGermination).down and lowest.health.percent <= 75) then
        return cast(SB.Rejuvenation, lowest)
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
      { type = 'header', text = 'Class Settings', align= 'center' },
      { key = 'ironbarkpercent', type = 'spinner', text = 'Iron Bark', desc = 'Health Percent to Cast At', default = 66,  min = 1, max = 100, step = 5 },
      { type = 'rule' },
      { type = 'header', text = 'Wild Growth Settings', align= 'center' },
      { key = 'wildgrowthpercent', type = 'spinner', text = 'Wild Growth', desc = 'Health Percent to Cast At', default = 80,  min = 1, max = 100, step = 5 },
      { key = 'wildgrowthnumber', type = 'spinner', text = 'Wild Growth Targets', desc = 'Minimum Wild Growth Targets', default = 3, min = 1, max = 40, step = 1 },
      { type = 'rule' },
      { type = 'header', text = 'Rejuvenation', align= 'center' },
      { key = 'simultaneousrejuvenations', type = 'spinner', text = 'Max Rejuvenation Targets', desc = 'Maximum Rejuvenation Targets', default = 10, min = 1, max = 20, step = 1 },
      { type = 'rule' },
      { type = 'header', text = 'Rejuvenation', align= 'center' },
      { key = 'flourishpercent', type = 'spinner', text = 'Flourish', desc = 'Health Percent to Cast At', default = 75,  min = 1, max = 100, step = 5 },
      { type = 'rule' },
      { type = 'header', text = 'Defensives', align= 'center' },
      { key = 'barkskinpercent', type = 'spinner', text = 'Barkskin', desc = 'Health Percent to Cast At', default = 60, min = 1, max = 100, step = 5 },
      { key = 'healthstone', type = 'checkspin', text = 'Healthstone', desc = 'Auto use Healthstone at health %', default = 30, min = 5, max = 100, step = 5 },
      { type = 'rule' },
      { type = 'header', text = 'Utility', align= 'center' },
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
        name = 'racial',
        label = 'Use Racials',
        on = {
            label = 'Racials ON',
             color = dark_addon.interface.color.orange,
            color2 = dark_addon.interface.color.ratio(dark_addon.interface.color.dark_orange, 0.7)
        },
        off = {
            label = 'Racials OFF',
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
