local M = {}
M.Frames = {}
M.Textures = {}
M.Buffs = {}

M.Buffs.Weapon = {
  {
    spell_ids = {
      6498,
    },
    aura_instance_id = nil,
    internal_id = "earthliving_weapon",
    name = "Earthliving Weapon",
    active = false,
    icon = "spell_shaman_giftearthmother",
  },
}

M.Buffs.Player = {
  {
    spell_ids = {
      52127,
    },
    aura_instance_id = nil,
    internal_id = "water_shield",
    name = "Water Shield",
    active = false,
    icon = "ability_shaman_watershield",
  },
  {
    spell_ids = {
      383648,
      202036,
    },
    aura_instance_id = nil,
    internal_id = "earth_shield",
    name = "Earth Shield",
    active = false,
    icon = "spell_nature_skinofearth",
  }
}

-- Create icons for each weapon buff
for i, buff in pairs(M.Buffs.Weapon) do
  M.Frames[buff.internal_id] = CreateFrame("frame")
  M.Frames[buff.internal_id]:SetWidth(64)
  M.Frames[buff.internal_id]:SetHeight(64)
  M.Frames[buff.internal_id]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  M.Frames[buff.internal_id]:SetMovable(true)
  M.Frames[buff.internal_id]:RegisterForDrag("LeftButton")
  M.Frames[buff.internal_id]:SetScript("OnDragStart", function(self) self:StartMoving() end)
  M.Frames[buff.internal_id]:SetScript("OnDragStop", function(self)
    -- TODO Save position to SavedVariables
  end)

  M.Textures[buff.internal_id] = M.Frames[buff.internal_id]:CreateTexture(nil,"BACKGROUND")
  M.Textures[buff.internal_id]:SetAllPoints(M.Frames[buff.internal_id])
  M.Textures[buff.internal_id]:SetTexture("Interface\\Icons\\" .. buff.icon)
  M.Frames[buff.internal_id]:Hide()
end

-- Create icons for each player buff
for i, buff in pairs(M.Buffs.Player) do
  M.Frames[buff.internal_id] = CreateFrame("frame")
  M.Frames[buff.internal_id]:SetWidth(64)
  M.Frames[buff.internal_id]:SetHeight(64)
  M.Frames[buff.internal_id]:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

  M.Frames[buff.internal_id]:SetMovable(true)
  M.Frames[buff.internal_id]:RegisterForDrag("LeftButton")
  M.Frames[buff.internal_id]:SetScript("OnDragStart", function(self) self:StartMoving() end)
  M.Frames[buff.internal_id]:SetScript("OnDragStop", function(self)
    -- TODO Save position to SavedVariables
  end)

  M.Textures[buff.internal_id] = M.Frames[buff.internal_id]:CreateTexture(nil,"BACKGROUND")
  M.Textures[buff.internal_id]:SetAllPoints(M.Frames[buff.internal_id])
  M.Textures[buff.internal_id]:SetTexture("Interface\\Icons\\" .. buff.icon)
  M.Frames[buff.internal_id]:Hide()
end

M.Frames.player_entering_world = CreateFrame("Frame")
M.Frames.player_entering_world:RegisterEvent("PLAYER_ENTERING_WORLD")
M.Frames.player_entering_world:RegisterEvent("UNIT_INVENTORY_CHANGED")
M.Frames.player_entering_world:SetScript("OnEvent", function(self, event, ...)
  local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID  = GetWeaponEnchantInfo()
  if (hasMainHandEnchant and mainHandEnchantID) then
    for i, buff in pairs(M.Buffs.Weapon) do
      for j, spell_id in pairs(buff.spell_ids) do
        if (spell_id == mainHandEnchantID) then
          buff.active = true
          M.AddBuffAdjustment(buff)
        end
      end
    end
  else
    for i, buff in pairs(M.Buffs.Weapon) do
      if (buff.active) then
        buff.active = false
        M.RemoveBuffAdjustment(buff)
      end
    end
  end
end)

M.Frames.unit_aura = CreateFrame("Frame")
M.Frames.unit_aura:RegisterEvent("UNIT_AURA")
M.Frames.unit_aura:SetScript("OnEvent", function(self, event, unit, update_info)
  if (unit == nil) then
    return
  end
  if (unit ~= "player") then
    return
  end
  if (update_info == nil) then
    return
  end

  -- added auras during this update
  local added_auras = update_info.addedAuras
  if (added_auras) then
    for i, aura in pairs(added_auras) do
      for j, buff in pairs(M.Buffs.Player) do
        for k, spell_id in pairs(buff.spell_ids) do
          if (aura.spellId == spell_id) then
            buff.active = true
            buff.aura_instance_id = aura.auraInstanceID
            M.AddBuffAdjustment(buff)
          end
        end
      end
    end
  end

  -- removed auras during this update
  local removed_auras = update_info.removedAuraInstanceIDs
  if (removed_auras) then
    for i, aura_instance_id in pairs(removed_auras) do
      for j, buff in pairs(M.Buffs.Player) do
        if (aura_instance_id == buff.aura_instance_id) then
          buff.active = false
          M.RemoveBuffAdjustment(buff)
        end
      end
    end
  end
end)

function M.AddBuffAdjustment(buff)
  if (buff.name == "Water Shield") then
    M.Frames[buff.internal_id]:Hide()
  end
  if (buff.name == "Earth Shield") then
    -- TODO check if player has earth shield skilled
    -- TODO check if player has elemental orbit skilled
    -- otherwise we need to figure out a way to track the buff on other targets maybe?
    M.Frames[buff.internal_id]:Hide()
  end
  if (buff.name == "Earthliving Weapon") then
    -- TODO check if player has earthliving weapon spell skilled
    M.Frames[buff.internal_id]:Hide()
  end
end

function M.RemoveBuffAdjustment(buff)
  if (buff.name == "Water Shield") then
    M.Frames[buff.internal_id]:Show()
  end
  if (buff.name == "Earth Shield") then
    -- TODO check if player has earth shield skilled
    -- TODO check if player has elemental orbit skilled
    -- otherwise we need to figure out a way to track the buff on other targets maybe?
    M.Frames[buff.internal_id]:Show()
  end
  if (buff.name == "Earthliving Weapon") then
    -- TODO check if player has earthliving weapon spell skilled
    M.Frames[buff.internal_id]:Show()
  end
end

