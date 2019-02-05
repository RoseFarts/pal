-- Dead, Travelform, Resting or Channeling in Combat
if not player.alive or player.buff(SB.TravelForm).exists or player.buff(SB.Refreshment).up or player.buff(SB.Drink).up or player.channeling() then
	return
end

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
local GearSlot13 = GetInventoryItemID("player", 13)
if IsUsableItem(GearSlot13) and GetItemCooldown(GearSlot13) == 0 and tank.health.percent < trinkets_percent and tank.distance < 35 then
	macro('/use [help] 13; [@targettarget] 13')
end

local GearSlot14 = GetInventoryItemID("player", 14)
if IsUsableItem(GearSlot14) and GetItemCooldown(GearSlot14) == 0 and tank.health.percent < trinkets_percent and tank.distance < 35 then
	macro('/use [help] 14; [@targettarget] 14')
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
	if tank.castable(SB.Lifebloom) and tank.buff(SB.Lifebloom).down and not lastcast(SB.Lifebloom) then
		return cast(SB.Lifebloom, tank)
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
if tank.castable(SB.Rejuvenation) and tank.buff(SB.Rejuvenation).down then
	return cast(SB.Rejuvenation, tank)
end
if lowest.castable(SB.Rejuvenation) and lowest.buff(SB.Rejuvenation).down and current_rejuvs <= max_rejuvs and lowest.health.percent < 100 then
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
			
elseif IsInRaid() then
	if (tank.castable(SB.Regrowth) and tank.health.percent <= 50)
	or (player.buff(SB.Innervate).up and tank.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, tank)
	end
	if (lowest.castable(SB.Regrowth) and lowest.health.percent <= 40)
	or (player.buff(SB.Innervate).up and lowest.castable(SB.Regrowth)) and not player.moving then
		return cast(SB.Regrowth, lowest)
	end
end

-- Rejuvenation Germination, on the tank and on members of the group that just took damage or are about to take damage.
if talent(7, 2) then
    if tank.castable(SB.Rejuvenation) and tank.buff(SB.Rejuvenation).up and tank.buff(SB.RejuvenationGermination).down) then
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
if target.castable(SB.Sunfire) and target.debuff(SB.Sunfire).remains <= 2 then
	return cast(SB.Sunfire, target)
end

if target.castable(SB.Moonfire) and target.debuff(SB.Moonfire).remains <= 2 then
	return cast(SB.Moonfire, target)
end

-- Catweaving
if castable(SB.CatForm, player) and not -buff(SB.CatForm) and talent(3,2) then
	return cast(SB.CatForm, player)
end

if -buff(SB.CatForm) and target.distance <= 8 and talent(3,2) then
	if enemies.around(8) < 2 then
		if castable(SB.Rake) and -power.combopoints <= 4 and -power.energy >= 55 and target.debuff(SB.RakeDebuff).remains <= 2 then
			return cast(SB.Rake, target)
		end
	
		if castable(SB.Shred) and -power.combopoints <= 4 and -power.energy >= 60 then
			return cast(SB.Shred, target)
		end
	end
		
	if enemies.around(8) >= 2 then
		if castable(SB.SwipeCat) and -power.combopoints <= 4 and -power.energy >= 60 then
			return cast(SB.SwipeCat, target)
		end
	end
		
	if castable(SB.FerociousBite) and -power.combopoints == 5 and -power.energy >= 65 then
		return cast(SB.FerociousBite, target)
	end	
end

if target.castable(SB.SolarWrathResto) and not player.moving then
	return cast(SB.SolarWrathResto, target)
end
