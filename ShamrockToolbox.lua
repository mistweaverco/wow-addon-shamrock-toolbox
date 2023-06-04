local M = {}
M.Frames = {}
M.Textures = {}
M.Buffs = {}

M.Talents = {}
M.Talents["Earthliving Weapon"] = {
  node_id = 81049,
  selected = false,
}
M.Talents["Earth Shield"] = {
  node_id = 81106,
  selected = false,
}
M.Talents["Elemental Orbit"] = {
  node_id = 81105,
  selected = false,
}

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

M.Buffs.Player = {}
M.Buffs.Player["Water Shield"] = {
  spell_ids = {
    52127,
  },
  aura_instance_id = nil,
  internal_id = "water_shield",
  active = false,
  icon = "ability_shaman_watershield",
}
M.Buffs.Player["Earth Shield"] = {
  spell_ids = {
    383648,
    202036,
  },
  aura_instance_id = nil,
  internal_id = "earth_shield",
  active = false,
  icon = "spell_nature_skinofearth",
}

function play_sound(sound)
  PlaySoundFile("Interface\\AddOns\\ShamrockToolbox\\sounds\\" .. sound .. ".ogg", "Master")
end

function M.fetch_talent_info()
  local spec_id = PlayerUtil.GetCurrentSpecID()
  local config_id = C_ClassTalents.GetLastSelectedSavedConfigID(spec_id) or C_ClassTalents.GetActiveConfigID()
  local config_info = C_Traits.GetConfigInfo(config_id)
  local tree_id = config_info.treeIDs[1]

  local nodes = C_Traits.GetTreeNodes(tree_id)

  for _, node_id in ipairs(nodes) do
    for talent_name, talent_data in pairs(M.Talents) do
      if (talent_data.node_id == node_id) then
        local node_info = C_Traits.GetNodeInfo(config_id, node_id)
        if node_info.currentRank and node_info.currentRank > 0 then
          talent_data.selected = true
        end
      end
    end
  end
end

function M.debug_print_talent_info()
  local spec_id = PlayerUtil.GetCurrentSpecID()
  local config_id = C_ClassTalents.GetLastSelectedSavedConfigID(spec_id) or C_ClassTalents.GetActiveConfigID()
  local config_info = C_Traits.GetConfigInfo(config_id)
  local tree_id = config_info.treeIDs[1]

  local nodes = C_Traits.GetTreeNodes(tree_id)

  for _, node_id in ipairs(nodes) do
    local node_info = C_Traits.GetNodeInfo(config_id, node_id)
    if node_info.currentRank and node_info.currentRank > 0 then
      local entry_id = node_info.activeEntry and node_info.activeEntry.entryID and node_info.activeEntry.entryID
      local entry_info = entry_id and C_Traits.GetEntryInfo(config_id, entry_id)
      local definition_info = entry_info and entry_info.definitionID and C_Traits.GetDefinitionInfo(entry_info.definitionID)

      if definition_info ~= nil then
        local talent_name = TalentUtil.GetTalentName(definition_info.overrideName, definition_info.spellID)
        print(string.format("Name: %s - Rank: %d/%d - SpellID: %d - NodeID: %d", talent_name, node_info.currentRank, node_info.maxRanks, definition_info.spellID, node_id))
      end
    end
  end
end

function setup_frame(buff)
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
  M.Frames[buff.internal_id]:Show()
end

-- Create icons for each weapon buff
for i, buff in pairs(M.Buffs.Weapon) do
  setup_frame(buff)
end

-- Create icons for each player buff
for i, buff in pairs(M.Buffs.Player) do
  setup_frame(buff)
end

function has_weapon_enchant()
  local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID  = GetWeaponEnchantInfo()
  if (hasMainHandEnchant and mainHandEnchantID) then
    for i, buff in pairs(M.Buffs.Weapon) do
      for j, spell_id in pairs(buff.spell_ids) do
        if (spell_id == mainHandEnchantID) then
          buff.active = true
          M.AddBuff(buff)
        end
      end
    end
  else
    for i, buff in pairs(M.Buffs.Weapon) do
      if (buff.active) then
        buff.active = false
        M.RemoveBuff(buff)
      end
    end
  end
end

function pass_weapon_enchant_check()
  for i, buff in pairs(M.Buffs.Weapon) do
    if (buff.active == false) then
      buff.active = true
      M.AddBuff(buff)
    end
  end
end

function pass_earthshield_check()
  M.Buffs.Player['Earth Shield'].active = true
  M.AddBuff(M.Buffs.Player['Earth Shield'])
end

function check_player_buffs_on_entering_world()
  for i, buff in pairs(M.Buffs.Player) do
    for j, spell_id in pairs(buff.spell_ids) do
      local aura = C_UnitAuras.GetPlayerAuraBySpellID(spell_id)
      if (aura) then
        buff.active = true
        buff.aura_instance_id = aura.auraInstanceID
        M.AddBuff(buff)
      end
    end
  end
end

function on_player_entering_world()
  -- required to get the selected talents
  M.fetch_talent_info()

  if M.Talents["Earthliving Weapon"].selected then
    has_weapon_enchant()
  else
    pass_weapon_enchant_check()
  end

  if M.Talents['Elemental Orbit'].selected == false or M.Talents['Earth Shield'].selected == false then
    pass_earthshield_check()
  end

  check_player_buffs_on_entering_world()
end

M.Frames.player_entering_world = CreateFrame("Frame")
M.Frames.player_entering_world:RegisterEvent("PLAYER_ENTERING_WORLD")
M.Frames.player_entering_world:RegisterEvent("UNIT_INVENTORY_CHANGED")
M.Frames.player_entering_world:SetScript("OnEvent", on_player_entering_world)

function on_added_auras(added_auras)
  if (added_auras) then
    for i, aura in pairs(added_auras) do
      for j, buff in pairs(M.Buffs.Player) do
        for k, spell_id in pairs(buff.spell_ids) do
          if (aura.spellId == spell_id) then
            buff.active = true
            buff.aura_instance_id = aura.auraInstanceID
            M.AddBuff(buff)
          end
        end
      end
    end
  end
end

function on_removed_auras(removed_auras)
  if (removed_auras) then
    for i, aura_instance_id in pairs(removed_auras) do
      for j, buff in pairs(M.Buffs.Player) do
        if (aura_instance_id == buff.aura_instance_id) then
          buff.active = false
          M.RemoveBuff(buff)
        end
      end
    end
  end
end

function on_unit_aura_event(self, event, unit, update_info)
  if (unit == nil) then
    return
  end
  if (unit ~= "player") then
    return
  end
  if (update_info == nil) then
    return
  end

  on_added_auras(update_info.addedAuras)
  on_removed_auras(update_info.removedAuraInstanceIDs)
end

M.Frames.unit_aura = CreateFrame("Frame")
M.Frames.unit_aura:RegisterEvent("UNIT_AURA")
M.Frames.unit_aura:SetScript("OnEvent", on_unit_aura_event)

function M.AddBuff(buff)
  M.Frames[buff.internal_id]:Hide()
end

function M.RemoveBuff(buff)
  M.Frames[buff.internal_id]:Show()
end

