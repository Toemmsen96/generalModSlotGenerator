local M = {}

--template
local template = nil
local templateVersion = -1

--helpers
local function ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

local json = require 'dkjson'  -- imports required json lib (see /lua/common/extensions/LICENSE.txt)


local function readJsonFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*a")
    file:close()
    return content and json.decode(content) or nil
end

local function writeJsonFile(path, data, compact)
	local file = io.open(path, "w")
	if not file then return nil end
	local content = json.encode(data, { indent = not compact })
	file:write(content)
	file:close()
	return true
end


local function getAllVehicles()
  local vehicles = {}
  for _, v in ipairs(FS:findFiles('/vehicles', '*', 0, false, true)) do
    if v ~= '/vehicles/common' then
      table.insert(vehicles, string.match(v, '/vehicles/(.*)'))
    end
	if v == '/vehicles/common' then
		--TODO: add common vehicles
		--for _, v2 in ipairs(FS:findFiles('/vehicles/common', '*', 0, false, true)) do
		--	table.insert(vehicles, string.match(v2, '/vehicles/common/(.*)'))
		--	log('D', 'getAllVehicles', "found common vehicle: " .. string.match(v2, '/vehicles/common/(.*)'))
		--end
	end
  end
  return vehicles
end

local function getModSlotJbeamPath(vehicleDir, templateName)
	local path = "/mods/unpacked/generatedModSlot/vehicles/" .. vehicleDir .. "/ModSlot/" .. vehicleDir .. "_" .. templateName .. ".jbeam"
	return path
end

local function loadExistingModSlotData(vehicleDir, templateName)
	return readJsonFile(getModSlotJbeamPath(vehicleDir, templateName))
end

local function makeAndSaveNewTemplate(vehicleDir, slotName, templateName)
	local templateCopy = deepcopy(template)
	
	--make main part
	local mainPart = {}
	templateCopy.slotType = slotName
	mainPart[vehicleDir .. "_" .. templateName] = templateCopy
	
	
	--save it
	local savePath = getModSlotJbeamPath(vehicleDir, templateName)
	writeJsonFile(savePath, mainPart, true)
end


--template version finder
local function findTemplateVersion(modslotJbeam)
	if type(modslotJbeam) ~= 'table' then return nil end
	
	for modKey, mod in pairs(modslotJbeam) do
		-- log('D', 'GELua.modslotGenerator.onExtensionLoaded', "modKey: " .. modKey)
		-- is it valid?
		if mod.version ~= nil then
			log('D', 'findTemplateVersion', "mod.version found: " .. mod.version)
			return mod.version
		end
	end
	return nil
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
	log('E', 'loadMainSlot', "No main slot found for " .. vehicleDir)
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
	return nil
end

--generation stuff
local function generate(vehicleDir, templateName)
	local existingData = loadExistingModSlotData(vehicleDir,templateName)
	local existingVersion = findTemplateVersion(existingData)
	local vehicleModSlot = getModSlot(vehicleDir)
	if vehicleModSlot == nil then
		log('D', 'generate', vehicleDir .. " has no mod slot")
		return
	end
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
	makeAndSaveNewTemplate(vehicleDir, vehicleModSlot, templateName)
end

local function generateAll(templateName)
	log('D', 'generateAll', "running generateAll()")
	for _,veh in pairs(getAllVehicles()) do
		generate(veh, templateName)
	end
	log('D', 'generateAll', "done")
end

local function loadTemplate(templateName)
	if templateName == nil then
		log('E', 'loadTemplate', "templateName is nil")
		return
	end
	template = readJsonFile("/lua/ge/extensions/tommot/ModSlotGeneratorTemplates/" .. templateName .. ".json")
	if template ~= nil then
		templateVersion = template.version
		log('D', 'loadTemplate', "Loaded Template-version: " .. templateVersion)
	end
	if template == nil then
		log('E', 'loadTemplate', "Failed to load template: " .. templateName)
	end
end

local function loadTemplateNames()
	templateNames = {}
	files = FS:findFiles("/lua/ge/extensions/tommot/ModSlotGeneratorTemplates", "*.json", -1, true, false)
	for _, file in ipairs(files) do
		local name = string.match(file, "/lua/ge/extensions/tommot/ModSlotGeneratorTemplates/(.*)%.json")
		log('D', 'loadTemplateNames', "found template: " .. name)
		table.insert(templateNames, name)
	end
	return templateNames
end

local function onExtensionLoaded()
	log('D', 'onExtensionLoaded', "Mods/TommoT ModSlot Generator Loaded")
	templateNames = loadTemplateNames()
	if templateNames == nil then
		log('E', 'onExtensionLoaded', "No templates found")
		return
	end
	log('D', 'onExtensionLoaded', "Templates found: " .. table.concat(templateNames, ", "))
	for _,name in pairs(templateNames) do
		loadTemplate(name)
		if template ~= nil then
			generateAll(name)
		end
	end
end


-- probably make this into a function to be called if wanted, so its not always removing all files on gameexit
local function deleteTempFiles()
	--delete all files in /mods/unpacked/generatedModSlot
	local files = FS:findFiles("/mods/unpacked/generatedModSlot", "*", -1, true, false)
	for _, file in ipairs(files) do
		FS:removeFile(file)
	end
	--TODO: dirs still there, needs to be fixed
	local dirs = FS:findFiles("/mods/unpacked/generatedModSlot", "*", -1, false, true)
	for _, dir in ipairs(dirs) do
		FS:removeDir(dir)
	end
end

-- functions which should actually be exported
M.onExtensionLoaded = onExtensionLoaded
M.onModDeactivated = onExtensionLoaded
M.onModActivated = onExtensionLoaded
M.onExit = deleteTempFiles

return M