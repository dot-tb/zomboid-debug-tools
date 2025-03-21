-- Debug only print
local function dprint(...)
  if isDebugEnabled() then
    print("[DELRAN'S DEBUG TOOLS]: ", ...);
  end
end

---@param number number
local function IsNaN(number)
  return number ~= number;
end

---@param clothingItem Clothing
local function FixWetnessBugOnItem(clothingItem)
  local name = clothingItem:getName();
  dprint("Checking ", name, " for wetness bug.");
  local wetness = clothingItem:getWetness();
  if IsNaN(wetness) then
    dprint("Found NaN wetness value on : ", name);
    clothingItem:setWetness(0);
    dprint("Item fixed")
  else
    dprint("No NaN found on : ", name);
  end
end

---@param body BodyDamage
local function PlayerHasWetnessBug(body)
  dprint("Checking player for wetness bug.");
  local wetness = body:getWetness();
  local temperature = body:getTemperature();
  return IsNaN(wetness) or IsNaN(temperature);
end

---@param body BodyDamage
local function FixWetnessBugOnPlayer(body)
  body:getThermoregulator():reset();
  body:setWetness(0);
  dprint("Player fixed")
end

---@param player IsoPlayer
local function FixAllClothingAndPlayer(player)
  local body = player:getBodyDamage();
  if (PlayerHasWetnessBug(body)) then
    local clothingItems = player:getInventory():getItemsFromCategory("Clothing");
    for i = 1, clothingItems:size() - 1, 1 do
      clothingItems:get(i):setWetness(0);
    end
    FixWetnessBugOnPlayer(body);
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
      if IsNaN(wetness) then
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
  context:addOption("Fix Temperature and Wetness", player, FixAllClothingAndPlayer);
end
---@param playerNum integer
---@param context ISContextMenu
---@param objects IsoObject[]
local function AddAllNaNs(playerNum, context, objects, test)
  local player = getSpecificPlayer(playerNum);
  context:addOption("!!! ADD ALL NANS !!!", player, function()
    player:getStats():setThirst(0 / 0);
    local nutrition = player:getNutrition();
    nutrition:setCalories(0 / 0);
    nutrition:setCarbohydrates(0 / 0);
    nutrition:setLipids(0 / 0);
    nutrition:setProteins(0 / 0);
  end);
end

-- Only add context menus for debug mode
if isDebugEnabled() then
  Events.OnFillInventoryObjectContextMenu.Add(WetnessFixContextMenu);
  Events.OnFillWorldObjectContextMenu.Add(BodyTemperatureFixContextMenu);
  Events.OnFillWorldObjectContextMenu.Add(AddAllNaNs);
end

Events.OnGameStart.Add(function()
  local player = getPlayer();
  local body = player:getBodyDamage();
  FixAllClothingAndPlayer(player);

  local stats = player:getStats();
  local thirst = stats:getThirst();
  if IsNaN(thirst) then
    stats:setThirst(0);
  end

  local nutrition = player:getNutrition();
  local calories = nutrition:getCalories();
  local carbohydrates = nutrition:getCarbohydrates();
  local lipids = nutrition:getLipids();
  local proteins = nutrition:getProteins();

  if IsNaN(calories) then
    nutrition:setCalories(1000);
  end
  if IsNaN(carbohydrates) then
    nutrition:setCarbohydrates(300);
  end
  if IsNaN(lipids) then
    nutrition:setLipids(300);
  end
  if IsNaN(proteins) then
    nutrition:setProteins(300);
  end
end);

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
    local body = self.character:getBodyDamage();
    FixWetnessBugOnItem(item);
    if (PlayerHasWetnessBug(body)) then
      dprint("Found NaN wetness value on player");
      FixWetnessBugOnPlayer(body);
    end
  end
  PATCHED_PERFORM(self);
end
