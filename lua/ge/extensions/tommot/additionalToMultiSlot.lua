--[ Author: TommoT / Toemmsen
-- Description: This script is used to generate modslot jbeams for all vehicles in the game.
-- It uses a template files that are placed in /modslotgenerator/ to generate the Additional Modification mods and makes them selectable at once.
-- Don't inlcude this mod in your mod, add it as a requirement in you Modpage, as it prevents duplicate code.

local M = {}

local gmsg = tommot_modslotGenerator
local templateNames = {}
local additionalMods = {}

-- helpers
local function isEmptyOrWhitespace(str)
    return str == nil or str:match("^%s*$") ~= nil
end

local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local function readJsonFile(path)
    if isEmptyOrWhitespace(path) then
        log('E', 'readJsonFile', "path is empty")
        return nil
    end
    return jsonReadFile(path)
end

local function writeJsonFile(path, data, compact)
    return jsonWriteFile(path, data, compact)
end

local function getModNameFromPath(path) -- stolen from modmanager.lua lol, credits to BeamNG
    local modname = string.lower(path)
    modname = modname:gsub('dir:/', '') --should have been killed by now
    modname = modname:gsub('/mods/', '')
    modname = modname:gsub('repo/', '')
    modname = modname:gsub('unpacked/', '')
    modname = modname:gsub('/', '')
    modname = modname:gsub('.zip$', '')
    --log('I', 'getModNameFromPath', "getModNameFromPath path = "..path .."    name = "..dumps(modname) )
    return modname
end
-- end helpers

-- TODO: ADJUST BELOW THIS LINE --
local function findMainPart(vehicleJbeam) 
    if type(vehicleJbeam) ~= 'table' then return nil end
    
    for partKey, part in pairs(vehicleJbeam) do
        -- is it valid?
        if part.slotType == "main" then
            return partKey
        end
    end
    return nil
end

local function loadMainSlot(vehicleDir)
    --first check if a file exists named vehicleDir.jbeam
    local vehJbeamPath = "/vehicles/" .. vehicleDir .. "/" .. vehicleDir .. ".jbeam"
    local vehicleJbeam = nil
    
    if FS:fileExists(vehJbeamPath) then
        -- load it!
        vehicleJbeam = readJsonFile(vehJbeamPath)
        
        -- is it valid?
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey ~= nil then
            return vehicleJbeam[mainPartKey]
        end
    end
    
    --if it wasn't valid, look through all files in this vehicle dir
    local files = FS:findFiles("/vehicles/" .. vehicleDir, "*.jbeam", -1, true, false)
    for _, file in ipairs(files) do
        -- load it!
        vehicleJbeam = readJsonFile(file)
        
        -- is it valid?
        local mainPartKey = findMainPart(vehicleJbeam)
        if mainPartKey ~= nil then
            return mainPartKey
        end
    end
    if DET_DEBUG then log('W', 'loadMainSlot', "No main slot found for " .. vehicleDir) end
    --if all else fails, return nil
    return nil
end

local function getSlotTypes(slotTable)
    local slotTypes = {}
    for i, slot in pairs(slotTable) do
        if i > 1 then
            local slotType = slot[1]
            table.insert(slotTypes, slotType)
        end
    end
    return slotTypes
end

local function getModSlot(vehicleDir)
    local mainSlotData = loadMainSlot(vehicleDir)
    if mainSlotData ~= nil and mainSlotData.slots ~= nil and type(mainSlotData.slots) == 'table' then
        for _,slotType in pairs(getSlotTypes(mainSlotData.slots)) do
            if ends_with(slotType, "_mod") then
                return slotType
            end
        end
    end

    --if that didn't work, try for slots2, which is used in some vehicles, and a newer format
    if mainSlotData ~= nil and mainSlotData.slots2 ~= nil and type(mainSlotData.slots2) == 'table' then
        for _,slotType in pairs(getSlotTypes(mainSlotData.slots2)) do
            if ends_with(slotType, "_mod") then
                return slotType
            end
        end
    end
    return nil
end

local function getAdditionalMods(vehicleDir)
    --[[ TODO: 
    find additional mods
    for each of them:
        load and deepcopy jbeam
        find _mod slot
        generate new Templatename
        change _mod slot to new Templatename_mod
        return list of additional mods to
        add to templateList
    ]] 
end

local function generateMultiWithAdditional(vehicleDir, additionalMods)
    local multiModTemplate = readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        logToConsole('E', 'generateMultiWAdditional', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then logToConsole('D', 'generateMulti', vehicleDir .. " has no mod slot") end
        return
    end
    multiModTemplate.slotType = vehicleModSlot
    for _,templateName in pairs(templateNames) do
        if multiModTemplate ~= nil and multiModTemplate.slots ~= nil and type(multiModTemplate.slots) == 'table' then
            for _,slotType in pairs(getSlotTypes(multiModTemplate.slots)) do
                table.insert(multiModTemplate.slots, {templateName .. "_mod", "", templateName})
            end
        end
    end

    -- add additional mods
    for _, additionalMod in pairs(additionalMods) do
        if additionalMod ~= nil and additionalMod.slots ~= nil and type(additionalMod.slots) == 'table' then
            for _,slotType in pairs(getSlotTypes(additionalMod.slots)) do
                table.insert(multiModTemplate.slots, {additionalMod .. "_mod", "", additionalMod})
            end
        end
    end

    local savePath = gmsg.GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_multiMod.jbeam"
    gmsg.makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multiMod")
end

-- END OF ADJUSTMENTS --

local function additionalToMultiSlot()
    gmsg.GMSGMessage("Generating MultiSlot Mods from Additional Mods")
    local vehicles = gmsg.getVehicles()
    templateNames = gmsg.getTemplateNames()
    for _,vehicle in pairs(vehicles) do
        additionalMods = getAdditionalMods(vehicle)
        generateMultiWithAdditional(vehicle, additionalMods)
    end
    gmsg.GMSGMessage("Finished generating MultiSlot Mods from Additional Mods")

end




M.additionalToMultiSlot = additionalToMultiSlot