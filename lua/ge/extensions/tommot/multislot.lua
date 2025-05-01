--[[
This file is part of the "MultiSlot / ModSlot generator" mod for BeamNG.drive by TommoT / Toemmsen
To get the latest version of this mod, please visit:
https://github.com/Toemmsen96/generalModSlotGenerator/
]]


local M = {}

local makeAndSaveNewTemplate = tommot_templates.makeAndSaveNewTemplate
local getModSlot = tommot_modslotGenerator.getModSlot
local getModSlotJbeamPath = tommot_modslotGenerator.getModSlotJbeamPath
local getSlotTypes = tommot_modslotGenerator.getSlotTypes
local getAllVehicles = tommot_modslotGenerator.getAllVehicles
local readJsonFile = tommot_modslotGenerator.readJsonFile
local writeJsonFile = tommot_modslotGenerator.writeJsonFile
local loadTemplateNames = tommot_templates.loadTemplateNames
local loadTemplate = tommot_templates.loadTemplate
local convertName = tommot_modslotGenerator.convertName
local GENERATED_PATH = tommot_modslotGenerator.GENERATED_PATH
local onFinishGen = tommot_modslotGenerator.onFinishGen

local function GMSGMessage(msg, title, icon, duration)
    tommot_modslotGenerator.GMSGMessage(msg, title, icon, duration)
end

local function saveMultiTemplate(template, templateName)
    local convName = convertName(templateName)
    local newTemplate = deepcopy(template)
    dump(convName)
    makeAndSaveNewTemplate("common", convName .. "_mod", newTemplate, templateName)
end

--generation stuff for multi templates
local function generateMulti(vehicleDir)
    local multiModTemplate = readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        logToConsole('E', 'generateMulti', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then logToConsole('D', 'generateMulti', vehicleDir .. " has no mod slot") end
        return
    end
    multiModTemplate.slotType = vehicleModSlot
    local templateNames = loadTemplateNames()
    for _,templateName in pairs(templateNames) do
        local convName = convertName(templateName)
        if multiModTemplate ~= nil and multiModTemplate.slots ~= nil and type(multiModTemplate.slots) == 'table' then
            for _,slotType in pairs(getSlotTypes(multiModTemplate.slots)) do
                table.insert(multiModTemplate.slots, {convName .. "_mod", "", templateName})
            end
        end
    end
    local savePath = GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_multiMod.jbeam"
    makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multiMod")
end

local function generateMultiSlotJob(job)
    local timer = nil
    local time = nil
    if TIMER_GENERATION then 
        log('D', 'generateSeparateJob', "Generating MultiSlot mods with timer: " .. os.time())
        timer = hptimer()
    end
    GMSGMessage("Generating multi mods", "Info", "info", 2000)
    local templateNames = loadTemplateNames()
    for _,name in pairs(templateNames) do
        local template = loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
            job.yield()
        end
    end
    for _,veh in pairs(getAllVehicles()) do
        generateMulti(veh)
        job.yield()
    end
    if TIMER_GENERATION then 
        time = timer:stop()
        log('D', 'generateSeparateJob', "Done generating MultiSlot mods with timer: " .. time)
        GMSGMessage("Done generating MultiSlot mods with timer: " .. time, "Info", "info", 2000)
    end
    GMSGMessage("Done generating all mods", "Info", "info", 2000)
    onFinishGen()
end

local function generateMultiSlotMod()
    local templateNames = loadTemplateNames()
    for _,name in pairs(templateNames) do
        local template = loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
        end
    end
	for _,veh in pairs(getAllVehicles()) do
		generateMulti(veh)
    end
    onFinishGen()
end





M.generateMultiSlotJob = generateMultiSlotJob
M.generateMultiSlotMod = generateMultiSlotMod
M.saveMultiTemplate = saveMultiTemplate

return M