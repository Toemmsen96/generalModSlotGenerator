--[ Author: TommoT / Toemmsen
-- Description: This script is used to generate modslot jbeams for all vehicles in the game.
-- It uses a template files that are placed in /modslotgenerator/ to generate the Additional Modification mods and makes them selectable at once.
-- Don't inlcude this mod in your mod, add it as a requirement in you Modpage, as it prevents duplicate code.

local M = {}

--template variables
local template = nil
local templateVersion = -1
local templateNames = nil
-- settings
local SEPARATE_MODS = false -- defines if templates generate separate mods for each vehicle
local MULTISLOT_MODS = true -- defines if templates generate multi mods for each vehicle
local DET_DEBUG = false -- defines if debug messages are printed
local LOGLEVEL = 2 -- 0 = no logs, 1 = info, 2 = debug
local USE_COROUTINES = true -- defines if coroutines are used to generate mods
local AUTO_APPLY_SETTINGS = false -- defines if settings are automatically applied on load
local AUTOPACK = false -- defines if the mod should be autopacked
local GENERATED_PATH = "/mods/unpacked/generatedModSlot"
local SETTINGS_PATH = "/settings/GMSG_Settings.json"
local customOutputPath = nil
local customOutputName = nil
local isWaitingForAutoPack = false
local isWaitingForPackAll = false
-- end constants

--helpers
local queueHookJS
if obj then
  queueHookJS = function(...) obj:queueHookJS(...) end
elseif be then
  queueHookJS = function(...) be:queueHookJS(...) end
end

local function logToConsole(level, func, message)
    if LOGLEVEL == 0 then
        return
    end
    if level == 'D' and LOGLEVEL < 2 then
        return
    end
    if level == 'I' and LOGLEVEL < 1 then
        return
    end
    if level == 'W' and LOGLEVEL < 1 then
        return
    end
    if level == 'E' then
        log('E', func, message)
        return
    end
    log(level, func, message)
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
        AutoApplySettings = AUTO_APPLY_SETTINGS,
        Autopack = AUTOPACK
    }
    guihooks.trigger('setModSettings', data)
end

local function loadSettings()
    local settings = readJsonFile(SETTINGS_PATH)
    if settings == nil then
        log('W', 'loadSettings', "Failed to find any saved settings, using defaults")
        settings = readJsonFile("/lua/ge/extensions/tommot/GMSG_Settings.json")
    end
    if settings ~= nil then
        SEPARATE_MODS = settings.SeparateMods
        MULTISLOT_MODS = settings.MultiSlotMods
        DET_DEBUG = settings.DetailedDebug
        USE_COROUTINES = settings.UseCoroutines
        AUTO_APPLY_SETTINGS = settings.AutoApplySettings
        AUTOPACK = settings.Autopack
        GMSGMessage("Settings loaded: SeparateMods: " .. tostring(SEPARATE_MODS) .. " MultiSlot: " .. tostring(MULTISLOT_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES).." Autopack all: "..tostring(AUTOPACK), "Info", "info", 2000)
        sendSettingsToUI()
    end 
    if settings == nil then
        GMSGMessage("Failed to load settings, using defaults: SeparateMods: " .. tostring(SEPARATE_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES), "Warning", "warning", 2000)
    end
end

local function saveSettings()
    local settings = {
        SeparateMods = SEPARATE_MODS,
        MultiSlotMods = MULTISLOT_MODS,
        DetailedDebug = DET_DEBUG,
        UseCoroutines = USE_COROUTINES,
        AutoApplySettings = AUTO_APPLY_SETTINGS,
        Autopack = AUTOPACK
    }
    writeJsonFile(SETTINGS_PATH, settings, true)
    GMSGMessage("Settings saved: SeparateMods: " .. tostring(SEPARATE_MODS) .." MultiSlot: "..tostring(MULTISLOT_MODS) .. " DetailedDebug: " .. tostring(DET_DEBUG) .. " UseCoroutines: " .. tostring(USE_COROUTINES).." Autopack all: ".. tostring(AUTOPACK), "Info", "info", 2000)
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
    if data.Autopack ~= nil then
        AUTOPACK = data.Autopack
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
    local path = GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_" .. templateName .. ".jbeam"
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
        logToConsole('E', 'generateMulti', "Failed to load multiModTemplate")
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
    local savePath = GENERATED_PATH:lower().."/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_multiMod.jbeam"
    makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, multiModTemplate, "multiMod")
end

local function saveMultiTemplate(template, templateName)
    local newTemplate = deepcopy(template)
    makeAndSaveNewTemplate("common", templateName .. "_mod", newTemplate, templateName)
end

--generation stuff
local function onFinishGen()
    core_modmanager.initDB()
    if AUTOPACK then
        isWaitingForPackAll = true
        logToConsole('W', 'onExtensionLoaded', "Queued for Autopack")
    end
end

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
    local vehicleModSlot = getModSlot(vehicleDir)
    if vehicleModSlot == nil then
        log('D', 'generateSpecific', vehicleDir .. " has no mod slot")
        return
    end
    log('D', 'generateSpecific', "Generating specific mod: " .. vehicleDir .. " " .. templateName .. " " .. outputPath)
    makeAndSaveCustomTemplate(vehicleDir, vehicleModSlot, template, templateName, outputPath)
end

local function generateAll(templateName)
    log('D', 'generateAll', "running generateAll() for template: " .. templateName)
    for _,veh in pairs(getAllVehicles()) do
        generate(veh, templateName)
        --generate(veh, templateName)
    end
    log('D', 'generateAll', "done")
    onFinishGen()
end

-- For concurrency with the job system
local function generateAllJob(job)
    log('D', 'generateAll', "running generateAll() for template: " .. templateName)
    for _,veh in pairs(getAllVehicles()) do
        generate(veh, templateName)
        job.yield()
    end
    log('D', 'generateAll', "done")
    onFinishGen()
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
    onFinishGen()
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
    onFinishGen()
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
    onFinishGen()
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
    onFinishGen()
end

local function generateSpecificMod(templatePath, templateName, outputPath, autoPack, includeMStemplate)
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
    if autoPack == nil then
        autoPack = AUTOPACK
    end
    if includeMStemplate == nil then
        includeMStemplate = false
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
    if includeMStemplate then
        -- TODO: Copy the template to "outputPath/modslotgenerator/templateName.json"
        local templateCopy = deepcopy(template)
        local success = false
        if ends_with(outputPath,"/") then
        log('D', 'generateSpecificMod', "Copying template to: /mods" .. outputPath .. "modslotgenerator/" .. templateName .. ".json")
        writeJsonFile("/mods"..outputPath .. "modslotgenerator/" .. templateName .. ".json", templateCopy, true)
        else
            log('D', 'generateSpecificMod', "Copying template to: /mods" .. outputPath .. "/modslotgenerator/" .. templateName .. ".json")
            writeJsonFile("/mods"..outputPath .. "/modslotgenerator/" .. templateName .. ".json", templateCopy, true)
        end
    end
    if autoPack then
        GMSGMessage("Autopacking generated mod", "Info", "info", 2000)
        customOutputPath = outputPath
        customOutputName = core_modmanager.getModNameFromPath(outputPath)
        core_modmanager.initDB()
        isWaitingForAutoPack = true
    end
end

local function isModInDB(nameToCheck)
    logToConsole('D', 'checkForModName', "Checking for mod: " .. nameToCheck)
    if not nameToCheck then return false end
    
    nameToCheck = nameToCheck:lower()
    local mods = core_modmanager.getMods()
    
    if not mods then
        logToConsole('E', 'checkForModName', "Failed to get mods list")
        return false
    end
    
    -- Iterate through mods table using pairs instead of ipairs
    for modId, mod in pairs(mods) do
        if mod and mod.modname and mod.modname:lower() == nameToCheck then
            logToConsole('D', 'checkForModName', "Found mod: " .. mod.modname)
            return true
        end
    end
    return false
end

local function onExtensionLoaded() -- TODO: needs check if the Extension's already running. Otherwise modScript reruns this
    if extensions.isExtensionLoaded("tommot_gmsgUI") then 
        logToConsole('W', 'onExtensionLoaded', "Already loaded, returning.")
        return
    end
    log('D', 'onExtensionLoaded', "Mods/TommoT ModSlot Generator Loaded")
    loadSettings()
    GMSGMessage("MultiSlot Generator Loaded, starting to generate.", "Info", "info", 3000)
    if getTemplateNames() then
        if SEPARATE_MODS then
            if USE_COROUTINES then core_jobsystem.create(generateSeparateJob, 1/100) else generateSeparateMods() end
        end
        if MULTISLOT_MODS then
            if USE_COROUTINES then core_jobsystem.create(generateMultiSlotJob, 1/100) else generateMultiSlotMod() end
        end
        if not SEPARATE_MODS and not MULTISLOT_MODS then
            GMSGMessage("No generation method selected", "Warning", "warning", 5000)
        end
		GMSGMessage("Done generating all mods", "Info", "info", 4000)
    end

    extensions.reload("tommot_gmsgUI")
end



local function onGuiUpdate()
    if isWaitingForAutoPack and customOutputPath ~= nil then
        if isModInDB(customOutputName) then
            logToConsole('D', 'Autopack', "Packing mod: /mods" .. customOutputPath:lower())
            core_modmanager.packMod("/mods"..customOutputPath:lower())
            isWaitingForAutoPack = false
        end 
    end
    if isWaitingForPackAll then
        if core_modmanager.modIsUnpacked("generatedmodslot") then -- TODO: FIX loop
    --    if isModInDB("generatedmodslot") then
            logToConsole('D', 'Autopack', "Packing generatedModSlot")
            isWaitingForPackAll = false
            core_modmanager.packMod(GENERATED_PATH:lower())
        end
    end

end

-- probably make this into a function to be called if wanted, so its not always removing all files on gameexit
local function deleteTempFiles()
    --delete all files in /mods/unpacked/generatedModSlot
    log('W', 'deleteTempFiles', "Deleting all files in /mods/unpacked/generatedModSlot")
    GMSGMessage("Deleting all files in /mods/unpacked/generatedModSlot", "Info", "info", 2000)
    
    -- Delete files in GENERATED_PATH
    local files = FS:findFiles(GENERATED_PATH, "*", -1, true, false)
    for _, file in ipairs(files) do
        if DET_DEBUG then log('D', 'deleteTempFiles', "Deleting file: " .. file) end
        FS:removeFile(file)
    end

    -- Delete files in lowercase path
    local filesLower = FS:findFiles(GENERATED_PATH:lower(), "*", -1, true, false)
    for _, file in ipairs(filesLower) do
        if DET_DEBUG then log('D', 'deleteTempFiles', "Deleting file: " .. file) end 
        FS:removeFile(file)
    end

    -- Delete packed Zip
    core_modmanager.deleteMod("generatedmodslot")

    log('W', 'deleteTempFiles', "Done")
    GMSGMessage("Done", "Info", "info", 2000)
end

local function onModDeactivated()
    deleteTempFiles()
    extensions.unload("tommot_gmsgUI") -- unloads UI
    extensions.unload("tommot_modslotGenerator") -- unloads this
end

-- Exported functions for mod lifecycle
M.onExtensionLoaded = onExtensionLoaded
-- M.onModManagerReady = onExtensionLoaded
M.onModDeactivated = onModDeactivated
M.onModActivated = onExtensionLoaded
M.onExit = onModDeactivated
M.onGuiUpdate = onGuiUpdate

-- Exported functions for mod generation
M.generateMultiSlotMod = generateMultiSlotMod
M.generateSeparateMods = generateSeparateMods
M.generateSpecificMod = generateSpecificMod

-- Exported functions for template management
M.getTemplateNames = getTemplateNames
M.loadTemplateNames = loadTemplateNames

-- Exported functions for settings management
M.loadSettings = loadSettings
M.saveSettings = saveSettings
M.setModSettings = setModSettings
M.sendSettingsToUI = sendSettingsToUI

-- Exported utility functions
M.deleteTempFiles = deleteTempFiles
M.logToConsole = logToConsole

return M