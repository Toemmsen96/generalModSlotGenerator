--[[
This file is part of the "MultiSlot / ModSlot generator" mod for BeamNG.drive by TommoT / Toemmsen
To get the latest version of this mod, please visit:
https://github.com/Toemmsen96/generalModSlotGenerator/
]]

local M = {}

--template variables
local template = nil
local templateVersion = -1
local templateNames = nil

local readJsonFile = tommot_modslotGenerator.readJsonFile
local writeJsonFile = tommot_modslotGenerator.writeJsonFile
local convertName = tommot_modslotGenerator.convertName

local function GMSGMessage(msg, title, icon, duration)
    tommot_modslotGenerator.GMSGMessage(msg, title, icon, duration)
end


local function makeAndSaveNewTemplate(vehicleDir, slotName, helperTemplate, templateName)
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then
        log('W', 'makeAndSaveNewTemplate', "templateCopy is nil")
        --GMSGMessage("Error: templateCopy is nil", "Error", "error", 5000)
        return
    end
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. templateName] = templateCopy

    local convName = convertName(templateName)
    
    --save it
    local savePath = tommot_modslotGenerator.getModSlotJbeamPath(vehicleDir, convName)
    writeJsonFile(savePath, mainPart, true)
end

--template version finder
local function findTemplateVersion(modslotJbeam)
    if type(modslotJbeam) ~= 'table' then return nil end
    
    for modKey, mod in pairs(modslotJbeam) do
        -- log('D', 'GELua.modslotGenerator.onExtensionLoaded', "modKey: " .. modKey)
        -- is it valid?
        if mod.version ~= nil then
            if DET_DEBUG then log('D', 'findTemplateVersion', "mod.version found: " .. mod.version) end
            return mod.version
        end
    end
    return nil
end

local function loadTemplate(templateName)
    if templateName == nil then
        log('E', 'loadTemplate', "templateName is nil")
        GMSGMessage("Error: templateName is nil", "Error", "error", 5000)
        return
    end
    template = readJsonFile("/modslotgenerator/" .. templateName .. ".json")
    if template ~= nil then
        templateVersion = template.version
        if templateVersion == nil then
            templateVersion = 1.0
            template.version = templateVersion
        end
        log('D', 'loadTemplate', "Loaded Template: " ..templateName.. " Version: " .. templateVersion)
        return template
    end
    if template == nil then
        log('E', 'loadTemplate', "Failed to load template: " .. templateName)
        GMSGMessage("Failed to load template: " .. templateName, "Error", "error", 5000)
        return nil
    end
end

local function loadTemplateNames()
    templateNames = {}
    local files = FS:findFiles("/modslotgenerator", "*.json", -1, true, false)
    for _, file in ipairs(files) do
        local name = string.match(file, "/modslotgenerator/(.*)%.json")
        if DET_DEBUG then log('D', 'loadTemplateNames', "found template: " .. name) end
        table.insert(templateNames, name)
    end
    if #templateNames == 0 then
        return nil
    end
    return templateNames
end

local function makeAndSaveCustomTemplate(vehicleDir, slotName, helperTemplate, templateName, outputPath)
    if outputPath == nil then
        log('E', 'makeAndSaveCustomTemplate', "outputPath is nil")
        return
    end
    local convName = convertName(templateName)
    log('D', 'makeAndSaveCustomTemplate', "Making and saving custom template: " .. vehicleDir .. " " .. slotName .. " " .. convName .. " " .. outputPath)
    local templateCopy = deepcopy(helperTemplate)
    if templateCopy == nil then
        log('W', 'makeAndSaveCustomTemplate', "templateCopy is nil")
        GMSGMessage("Error: templateCopy is nil", "Error", "error", 5000)
        return
    end
    
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. convName] = templateCopy
    
    --save it
    local savePath = "mods/" .. outputPath .. "/vehicles/".. vehicleDir.."/" ..vehicleDir.. "_" .. convName .. ".jbeam"
    writeJsonFile(savePath, mainPart, true)
end

local function getTemplateNames()
    templateNames = loadTemplateNames()
    if templateNames == nil then
        GMSGMessage("No templates found! \n Please make sure you have downloaded at least one MultiSlot / GMSG Plugin", "Warning", "warning", 5000)
        log('E', 'getTemplateNames', "No templates found")
        return false
    end
    log('D', 'getTemplateNames', "Templates found: " .. table.concat(templateNames, ", "))
    GMSGMessage("Templates found: " .. table.concat(templateNames, ", "), "Info", "info", 2000)
    return true
end

M.loadTemplate = loadTemplate
M.loadTemplateNames = loadTemplateNames
M.findTemplateVersion = findTemplateVersion
M.makeAndSaveNewTemplate = makeAndSaveNewTemplate
M.makeAndSaveCustomTemplate = makeAndSaveCustomTemplate
M.getTemplateNames = getTemplateNames

return M