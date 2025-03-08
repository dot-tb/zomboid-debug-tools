-- Debug only print
local function dprint(...)
  if isDebugEnabled() then
    print("[DELRAN'S DEBUG TOOLS]: ", ...);
  end
end

---@param clothingItem Clothing
local function FixWetnessBugOnItem(clothingItem)
  local name = clothingItem:getName();
  dprint("Checking ", name, " for wetness bug.");
  local wetness = clothingItem:getWetness();
  if wetness ~= wetness then
    dprint("Found NaN wetness value on : ", name);
    clothingItem:setWetness(0);
    dprint("Item fixed")
  else
    dprint("No NaN found on : ", name);
  end
end

---@param player IsoPlayer
local function FixWetnessBugOnPlayer(player)
  dprint("Checking player for wetness bug.");
  local body = player:getBodyDamage();
  local wetness = body:getWetness();
  local temperature = body:getTemperature();
  if wetness ~= wetness or temperature ~= temperature then
    dprint("Found NaN wetness value on player");
    body:getThermoregulator():reset();
    body:setWetness(0);
    dprint("Player fixed")
  else
    dprint("No wetness/temp NaN found on the player ");
  end
end

---@param playerNum integer
---@param context ISContextMenu
---@param items table
local function WetnessFixContextMenu(playerNum, context, items)
  ---@type InventoryItem[]
  local inventoryItems = ISInventoryPane.getActualItems(items)
  for _, item in ipairs(inventoryItems) do
    if item:IsClothing() then
      local wetness = item:getWetness();
      if wetness ~= wetness then
        context:addOption("Fix Wetness value", getSpecificPlayer(playerNum), function()
          --- Is there any way to do a proper type cast here ?
          ---@diagnostic disable-next-line: param-type-mismatch
          FixWetnessBugOnItem(item);
        end)
      else
        context:addOption("!!! ADD WETNESS BUG !!!", getSpecificPlayer(playerNum), function()
          ---@diagnostic disable-next-line: undefined-field
          item:setWetness(0 / 0);
        end)
      end
    end
  end
end

---@param playerNum integer
---@param context ISContextMenu
---@param objects IsoObject[]
local function BodyTemperatureFixContextMenu(playerNum, context, objects, test)
  local player = getSpecificPlayer(playerNum);

  context:addOption("Fix Temperature and Wetness", player, FixWetnessBugOnPlayer);
end

-- Only add context menus for debug mode
if isDebugEnabled() then
  Events.OnFillInventoryObjectContextMenu.Add(WetnessFixContextMenu);
  Events.OnFillWorldObjectContextMenu.Add(BodyTemperatureFixContextMenu);
end

-- Guard against reload
if not ORIGINAL_PERFORM then
  dprint("LOADING MODULE");
  ORIGINAL_PERFORM = ISWearClothing.perform;
  PATCHED_PERFORM = ISWearClothing.perform;
else
  dprint("RELOADING MODULE");
  PATCHED_PERFORM = ORIGINAL_PERFORM;
end
---@diagnostic disable-next-line: duplicate-set-field
function ISWearClothing:perform()
  ---@type Clothing
  local item = self.item;
  if item then
    FixWetnessBugOnItem(item);
    FixWetnessBugOnPlayer(self.character);
  end
  PATCHED_PERFORM(self);
end
