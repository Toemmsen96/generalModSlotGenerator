--[ Author: TommoT / Toemmsen
-- Description: This script is used to generate modslot jbeams for all vehicles in the game.
-- It uses a template files that are placed in /modslotgenerator/ to generate the Additional Modification mods and makes them selectable at once.
-- Don't inlcude this mod in your mod, add it as a requirement in you Modpage, as it prevents duplicate code.

local M = {}

--template variables
local template = nil
local templateVersion = -1
local templateNames = nil
-- constants
local SEPARATE_MODS = false -- defines if templates also generate separate mods for each vehicle
local DET_DEBUG = false -- defines if debug messages are printed
local USE_COROUTINES = true -- defines if coroutines are used to generate mods
local AUTO_APPLY_SETTINGS = false -- defines if settings are automatically applied on load
local AUTOPACK = false -- defines if the mod should be autopacked
local GENERATED_PATH = "/mods/unpacked/generatedModSlot"
local SETTINGS_PATH = "/settings/GMSG_Settings.json"
-- end constants

--helpers
local queueHookJS
if obj then
  queueHookJS = function(...) obj:queueHookJS(...) end
elseif be then
  queueHookJS = function(...) be:queueHookJS(...) end
end

local function GMSGMessage(msg, title, type, timeOut)
    if not queueHookJS then return end
    local onTap = "function() { window.open('https://www.beamng.com/resources/general-modslot-generator-multislot.31265/') }"
    local config = jsonEncode({
      type = type or "warning",
      title = title or "GMSG / MultiSlot Generator",
      msg = msg or "",
      config = {
        timeOut = timeOut or 10000,
        progressBar = true,
        closeButton = true,
  
        -- default stuffs
        positionClass = "toast-top-right",
        preventDuplicates = true,
        preventOpenDuplicates = true,
  
        onTap = "<REPLACETHIS>"
      }
    })
    config = config:gsub("\"<REPLACETHIS>\"", onTap)
  
    queueHookJS("toastrMsg", "["..config.."]", 0)
end

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
-- end helpers

-- Editable settings
local function sendSettingsToUI()
    local data = {
        SeparateMods = SEPARATE_MODS,
        DetailedDebug = DET_DEBUG,
        UseCoroutines = USE_COROUTINES,
        AutoApplySettings = AUTO_APPLY_SETTINGS
    }
    guihooks.trigger('setModSettings', data)
end

local function loadSettings()
    local settings = readJsonFile(SETTINGS_PATH)
    if settings == nil then
        log('W', 'loadSettings', "Failed to any saved settings, using defaults")
        settings = readJsonFile("/lua/ge/extensions/tommot/GMSG_Settings.json")
    end
    if settings ~= nil then
        SEPARATE_MODS = settings.SeparateMods
        DET_DEBUG = settings.DetailedDebug
        USE_COROUTINES = settings.UseCoroutines
        GMSGMessage("Settings loaded: SeparateMods: " .. tostring(SEPARATE_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES), "Info", "info", 2000)
        sendSettingsToUI()
    end 
    if settings == nil then
        GMSGMessage("Failed to load settings, using defaults: SeparateMods: " .. tostring(SEPARATE_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES), "Warning", "warning", 2000)
    end
end

local function saveSettings()
    local settings = {
        SeparateMods = SEPARATE_MODS,
        DetailedDebug = DET_DEBUG,
        UseCoroutines = USE_COROUTINES,
        AutoApplySettings = AUTO_APPLY_SETTINGS
    }
    writeJsonFile(SETTINGS_PATH, settings, true)
    GMSGMessage("Settings saved: SeparateMods: " .. tostring(SEPARATE_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES), "Info", "info", 2000)
    sendSettingsToUI()
end

local function setModSettings(jsonData)
    local data = json.decode(jsonData)
    if data.SeparateMods ~= nil then
        SEPARATE_MODS = data.SeparateMods
    end
    if data.DetailedDebug ~= nil then
        DET_DEBUG = data.DetailedDebug
    end
    if data.UseCoroutines ~= nil then
        USE_COROUTINES = data.UseCoroutines
    end
    if data.AutoApplySettings ~= nil then
        AUTO_APPLY_SETTINGS = data.AutoApplySettings
    end
    
    saveSettings()
end
--end Editable Settings

local function getAllVehicles()
  local vehicles = {}
  for _, v in ipairs(FS:findFiles('/vehicles', '*', 0, false, true)) do
    if v ~= '/vehicles/common' then
      table.insert(vehicles, string.match(v, '/vehicles/(.*)'))
    end
  end
  return vehicles
end

local function getModSlotJbeamPath(vehicleDir, templateName)
    local path = GENERATED_PATH.."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_" .. templateName .. ".jbeam"
    return path
end

local function loadExistingModSlotData(vehicleDir, templateName)
    return readJsonFile(getModSlotJbeamPath(vehicleDir, templateName))
end

local function makeAndSaveNewTemplate(vehicleDir, slotName, helperTemplate, templateName)
    local templateCopy = deepcopy(helperTemplate)
    
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. templateName] = templateCopy
    
    --save it
    local savePath = getModSlotJbeamPath(vehicleDir, templateName)
    writeJsonFile(savePath, mainPart, true)
end

local function makeAndSaveCustomTemplate(vehicleDir, slotName, helperTemplate, templateName, outputPath)
    if outputPath == nil then
        log('E', 'makeAndSaveCustomTemplate', "outputPath is nil")
        return
    end
    log('D', 'makeAndSaveCustomTemplate', "Making and saving custom template: " .. vehicleDir .. " " .. slotName .. " " .. templateName .. " " .. outputPath)
    local templateCopy = deepcopy(helperTemplate)
    
    --make main part
    local mainPart = {}
    templateCopy.slotType = slotName
    mainPart[vehicleDir .. "_" .. templateName] = templateCopy
    
    --save it
    local savePath = "mods/" .. outputPath .. "/vehicles/".. vehicleDir.."/" ..vehicleDir.. "_" .. templateName .. ".jbeam"
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

--part helpers
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

--generation stuff for multi templates
local function generateMulti(vehicleDir)
    local multiModTemplate = readJsonFile("/lua/ge/extensions/tommot/mSGTemplate.json")
    if multiModTemplate == nil then
        log('E', 'generateMulti', "Failed to load multiModTemplate")
        return
    end
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then log('D', 'generateMulti', vehicleDir .. " has no mod slot") end
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
    local savePath = GENERATED_PATH.."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_multiMod.jbeam"
    makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multiMod")
end

local function saveMultiTemplate(template, templateName)
    local newTemplate = deepcopy(template)
    makeAndSaveNewTemplate("common", templateName .. "_mod", newTemplate, templateName)
end

--generation stuff
local function generate(vehicleDir, templateName)
    local existingData = loadExistingModSlotData(vehicleDir,templateName)
    local existingVersion = findTemplateVersion(existingData)
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        if DET_DEBUG then log('D', 'generate', vehicleDir .. " has no mod slot") end
        return
    end
	if DET_DEBUG then
		if existingData == nil then
			log('D', 'generate', "No existingData for " .. vehicleDir)
		else
			log('D', 'generate', "Loaded existing Version: " .. existingVersion .. " for " .. vehicleDir)
		end
		
		if existingData ~= nil and existingVersion == templateVersion then
			log('D', 'generate', vehicleDir .. " up to date")
			return
		else
			log('D', 'generate', vehicleDir .. " NOT up to date, updating")
		end
	end
    makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, template, templateName)
end

local function generateSpecific(vehicleDir, templateName, outputPath)
    --local existingData = loadExistingModSlotData(vehicleDir,templateName)
    local existingVersion = findTemplateVersion(existingData)
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        log('D', 'generateSpecific', vehicleDir .. " has no mod slot")
        return
    end
    if existingData == nil then
        log('D', 'generateSpecific', "No existingData for " .. vehicleDir)
    else
        log('D', 'generateSpecific', "Loaded existing Version: " .. existingVersion .. " for " .. vehicleDir)
    end
    if existingData ~= nil and existingVersion == templateVersion then
        log('D', 'generateSpecific', vehicleDir .. " up to date")
        return
    else
        log('D', 'generateSpecific', vehicleDir .. " NOT up to date, updating")
    end
    makeAndSaveCustomTemplate(vehicleDir, vehicleModSlot, template, templateName, outputPath)
end

local function generateAll(templateName)
    log('D', 'generateAll', "running generateAll() for template: " .. templateName)
    for _,veh in pairs(getAllVehicles()) do
        generate(veh, templateName)
        --generate(veh, templateName)
    end
    log('D', 'generateAll', "done")
end

-- For concurrency with the job system
local function generateAllJob(job)
    log('D', 'generateAll', "running generateAll() for template: " .. templateName)
    for _,veh in pairs(getAllVehicles()) do
        generate(veh, templateName)
        job.yield()
    end
    log('D', 'generateAll', "done")
end
local function generateAllSpecific(templateName, outputPath)
    log('D', 'generateAllSpecific', "running generateAllSpecific()")
    for _,veh in pairs(getAllVehicles()) do
        generateSpecific(veh, templateName, outputPath)
    end
	GMSGMessage("Done generating all mods for template: " .. templateName.."\n and path: " .. outputPath, "Info", "info", 2000)
    log('D', 'generateAllSpecific', "done")
end

local function generateSeparateJob(job)
    GMSGMessage("Generating separate mods", "Info", "info", 2000)
	getTemplateNames()
    for _,name in pairs(templateNames) do
        loadTemplate(name)
        if template ~= nil then
            generateAll(name)
            job.yield()
        end
    end
	GMSGMessage("Done generating separate mods", "Info", "info", 2000)
end

local function generateSeparateMods()
	GMSGMessage("Generating separate mods", "Info", "info", 2000)
	getTemplateNames()
    for _,name in pairs(templateNames) do
        loadTemplate(name)
        if template ~= nil then
            generateAll(name)
        end
    end
	GMSGMessage("Done generating separate mods", "Info", "info", 2000)
end

local function generateMultiSlotJob(job)
    GMSGMessage("Generating multi mods", "Info", "info", 2000)
    getTemplateNames()
    for _,name in pairs(templateNames) do
        loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
            job.yield()
        end
    end
    for _,veh in pairs(getAllVehicles()) do
        generateMulti(veh)
        job.yield()
    end
    GMSGMessage("Done generating all mods", "Info", "info", 2000)
end

local function generateMultiSlotMod()
    for _,name in pairs(templateNames) do
        loadTemplate(name)
        if template ~= nil then
            saveMultiTemplate(template, name)
        end
    end
	for _,veh in pairs(getAllVehicles()) do
		generateMulti(veh)
    end
end

local function generateSpecificMod(templatePath, templateName, outputPath)
    if isEmptyOrWhitespace(templatePath) then
        log('E', 'generateSpecificMod', "templatePath is empty")
        GMSGMessage("Error: templatePath is empty", "Error", "error", 5000)
        return
    end
    if isEmptyOrWhitespace(templateName) then
        log('E', 'generateSpecificMod', "templateName is empty")
        GMSGMessage("Error: templateName is empty", "Error", "error", 5000)
        return
    end
    if isEmptyOrWhitespace(outputPath) then
        log('E', 'generateSpecificMod', "outputPath is empty")
        GMSGMessage("Error: outputPath is empty", "Error", "error", 5000)
        return
    end
    template = readJsonFile(templatePath)
    if template ~= nil then
        templateVersion = template.version
        log('D', 'generateSpecificMod', "Loaded Template-version: " .. templateVersion)
    end
    if template == nil then
        log('W', 'generateSpecificMod', "Failed to load template from path: " .. templatePath)
        template = loadTemplate(templateName)
        if template == nil then
            log('E', 'generateSpecificMod', "Failed to load template: " .. templateName)
            GMSGMessage("Failed to load template: " .. templateName, "Error", "error", 5000)
            return
        end
    end
    log('D', 'generateSpecificMod', "Generating specific mod: " .. templatePath)
    GMSGMessage("Generating specific mod: " .. templatePath, "Info", "info", 2000)
    if template ~= nil then
        generateAllSpecific(templateName, outputPath)
    end
end



local function onExtensionLoaded()
    log('D', 'onExtensionLoaded', "Mods/TommoT ModSlot Generator Loaded")
    loadSettings()
    GMSGMessage("MultiSlot Generator Loaded, starting to generate.", "Info", "info", 3000)
    if getTemplateNames() then
        if SEPARATE_MODS then
            if USE_COROUTINES then core_jobsystem.create(generateSeparateJob, 1/60) else generateSeparateMods() end
        else
            if USE_COROUTINES then core_jobsystem.create(generateMultiSlotJob, 1/60) else generateMultiSlotMod() end
        end
		GMSGMessage("Done generating all mods", "Info", "info", 4000)
    end
    extensions.load("tommot_gmsgUI")
    reloadModules(extensions)
end

-- probably make this into a function to be called if wanted, so its not always removing all files on gameexit
local function deleteTempFiles()
    --delete all files in /mods/unpacked/generatedModSlot
    log('W', 'deleteTempFiles', "Deleting all files in /mods/unpacked/generatedModSlot")
	GMSGMessage("Deleting all files in /mods/unpacked/generatedModSlot", "Info", "info", 2000)
    local files = FS:findFiles(GENERATED_PATH, "*", -1, true, false)
    for _, file in ipairs(files) do
        if DET_DEBUG then log('D', 'deleteTempFiles', "Deleting file: " .. file) end
        FS:removeFile(file)
    end
    log('W', 'deleteTempFiles', "Done")
	GMSGMessage("Done", "Info", "info", 2000)
end

-- functions which should actually be exported
M.onExtensionLoaded = onExtensionLoaded
M.onModDeactivated = deleteTempFiles
M.onModActivated = onExtensionLoaded
M.onExit = deleteTempFiles
M.deleteTempFiles = deleteTempFiles
M.generateSeparateMods = generateSeparateMods
M.getTemplateNames = getTemplateNames
M.loadTemplateNames = loadTemplateNames
M.generateSpecificMod = generateSpecificMod
M.loadSettings = loadSettings
M.saveSettings = saveSettings
M.setSeparateMods = setSeparateMods
M.setDetailedDebug = setDetailedDebug
M.setUseCoroutines = setUseCoroutines
M.setModSettings = setModSettings
M.sendSettingsToUI = sendSettingsToUI

return M