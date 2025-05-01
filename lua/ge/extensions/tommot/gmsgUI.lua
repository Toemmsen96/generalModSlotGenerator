-- GMSG UI
-- Author: Toemmsen / TommoT

local M = {}
M.dependencies = {"ui_imgui"}
M.showUI = false

local imgui = ui_imgui
local imguiUtils = require("/lua/common/extensions/ui/imguiUtils")
local gmsg = tommot_modslotGenerator
local gmsg_templates = tommot_templates
local multislot = tommot_multislot
local additionalToMultiSlot = tommot_additionalToMultiSlot
local style = imgui.GetStyle()
local ffi = require("ffi")
local SETTINGS_PATH = "/settings/GMSG_Settings.json"

-- Settings
local outputPath = ffi.new("char[?]", 256, "/unpacked/gmsg_out/")
local autopackCheckboxValue = ffi.new("bool[1]", false)
local autopackAllCheckboxValue = ffi.new("bool[1]", false)
local generateSeparateCheckboxValue = ffi.new("bool[1]", false)
local generateMultiSlotCheckboxValue = ffi.new("bool[1]", true)
local generateAdditionalCheckboxValue = ffi.new("bool[1]", true)
local detailedDebugCheckboxValue = ffi.new("bool[1]", true)
local useCoroutinesCheckboxValue = ffi.new("bool[1]", true)
local includeMStemplate = ffi.new("bool[1]", true)
local addDependencyDownloader = ffi.new("bool[1]", true)
local advancedModeCheckbox = ffi.new("bool[1]", false)
local concurrencyDelay = ffi.new("float[1]", 2/3)
local logLevelOptions = {"No Logs", "Info & Warnings", "All Logs"}
local logLevelSelected = ffi.new("int[1]", 2) -- Default to Debug level
local LOGLEVEL = 2 -- Global log level: 0 = only errors, 1 = info/warnings, 2 = debug
local loadedExtensions = {}
local selectedExtension = ""

-- End Settings

local function loadSettings()
    local settings = jsonReadFile(SETTINGS_PATH)
    if settings == nil then
        log('W', 'loadSettings', "Failed to any saved settings, using defaults")
        settings = jsonReadFile("/lua/ge/extensions/tommot/GMSG_Settings.json")
    end
    if settings ~= nil then
        local settingsMap = {
            SeparateMods = generateSeparateCheckboxValue,
            MultiSlotMods = generateMultiSlotCheckboxValue,
            DetailedDebug = detailedDebugCheckboxValue,
            UseCoroutines = useCoroutinesCheckboxValue,
            Autopack = autopackAllCheckboxValue
        }

        for key, value in pairs(settingsMap) do
            if settings[key] ~= nil then
                value[0] = settings[key]
                gmsg.logToConsole('I',"loadSettings","Loaded setting: " .. key .. " = " .. tostring(value[0]))
            end
        end
    end 
    if settings == nil then
        gmsg.logToConsole('E',"loadSettings","Failed to load settings, using defaults")
    end
end

local function getTemplate()
    extensions.load("tommot_templates")
    return gmsg_templates.loadTemplateNames()
end

local templates = getTemplate()
local selectedTemplate = nil
if templates then 
    selectedTemplate = templates[1]
end 

local function toggleUI()
    M.showUI = not M.showUI
end

local function renderTopBar()
    imgui.SetCursorPosY(-style.ItemSpacing.y + imgui.GetScrollY())
    imgui.PushFont3("cairo_bold")

    imgui.Text("GMSG UI")

    imgui.SetCursorPosX(imgui.GetWindowWidth() - imgui.CalcTextSize("X").x - style.FramePadding.x * 2 - style.WindowPadding.x)
    if imgui.Button("X") then
        toggleUI()
    end
    imgui.SetCursorPosX(0)
    imgui.PopFont()

    imgui.Separator()
end

local function render()
    imgui.SetNextWindowSizeConstraints(imgui.ImVec2(256, 256), imgui.ImVec2(1024, 1024))
    imgui.Begin("GMSG UI", nil, imgui.WindowFlags_NoTitleBar + imgui.WindowFlags_MenuBar + imgui.WindowFlags_NoDocking)
    
    imgui.BeginMenuBar()
    renderTopBar()
    imgui.EndMenuBar()
    
    if imgui.BeginTabBar("Tabs") then
        if imgui.BeginTabItem("Generate Standalone") then
            if selectedTemplate == nil then
                imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "No Templates found!")
                imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "Please make sure you have downloaded or created at least one MultiSlot / GMSG Plugin")
                imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), "also ensure that the mod is loaded and the template is in the modslotgenerator folder")
            elseif imgui.BeginCombo("Select Template", selectedTemplate) then
                for _, template in ipairs(templates) do
                    if imgui.Selectable1(template, template == selectedTemplate) then
                        selectedTemplate = template
                    end
                end
                imgui.EndCombo()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Select the Template you want to generate a Mod for. It needs to be saved in the mods-Folder under /unpacked/\"anything\"/modslotgenerator/\"Template-Name\".json")
            end
    
            imgui.Text("Enter Output Path: (Relative to the mods-Folder)")
            imgui.InputText("##outputPath", outputPath, 256, imgui.InputTextFlags_EnterReturnsTrue)
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Defines where the generated Mod will be saved relative to the mods-Folder in AppData (Default: /unpacked/gmsg_out/)")
            end

            if imgui.Checkbox("##autopackCheckbox", autopackCheckboxValue) or imgui.IsItemClicked() then
                autopackCheckboxValue[0] = not autopackCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Automatically packs the generated Mod into a .zip file, which will then be in the mods-Folder")
            end
            imgui.SameLine()
            if imgui.Selectable1("Autopack generated Mod", autopackCheckboxValue[0]) then
                autopackCheckboxValue[0] = not autopackCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Automatically packs the generated Mod into a .zip file, which will then be in the mods-Folder")
            end

            imgui.Checkbox("##includeMStemplate", includeMStemplate)
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Enables the MultiSlot-Template to be included in the generated Mod and with that compatibility with MultiSlot-Mods and automatic generation. (Recommended)")
            end
            imgui.SameLine()
            if imgui.Selectable1("Include MultiSlot-Template", includeMStemplate[0]) then
                includeMStemplate[0] = not includeMStemplate[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Enables the MultiSlot-Template to be included in the generated Mod and with that compatibility with MultiSlot-Mods and automatic generation. (Recommended)")
            end

            if includeMStemplate[0] then
                imgui.Checkbox("##addDependencyDownloader", addDependencyDownloader)
            else
                imgui.BeginDisabled()
                addDependencyDownloader[0] = false
                imgui.Checkbox("##addDependencyDownloader", addDependencyDownloader)
                imgui.EndDisabled()
            end
            if imgui.IsItemHovered() then
                if not includeMStemplate[0] then
                    imgui.SetTooltip("Enable 'Include MultiSlot-Template' to use this option")
                else
                    imgui.SetTooltip("Adds the Dependency-Downloader to the generated Mod, which will automatically download the required MultiSlot-Mod from the Repository")
                end
            end
            imgui.SameLine()
            if imgui.Selectable1("Add Dependency-Downloader", addDependencyDownloader[0]) then
                addDependencyDownloader[0] = not addDependencyDownloader[0]
            end
            if imgui.IsItemHovered() then
                if not includeMStemplate[0] then
                    imgui.SetTooltip("Enable 'Include MultiSlot-Template' to use this option")
                else
                    imgui.SetTooltip("Adds the Dependency-Downloader to the generated Mod, which will automatically download the required MultiSlot-Mod from the Repository")
                end
            end
    
            if imgui.Button("Generate selected Mod") then
                gmsg.generateSpecificMod(selectedTemplate, selectedTemplate, ffi.string(outputPath), autopackCheckboxValue[0],addDependencyDownloader[0], includeMStemplate[0])
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates the selected mod with the specified settings")
            end
    
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Generate Manually") then
            
            
            if imgui.Button("Generate MuliSlot-Mods") then
                if not extensions.isExtensionLoaded("tommot_multislot") then
                    extensions.load("tommot_multislot")
                    setExtensionUnloadMode("tommot_multislot", "manual")
                end
                tommot_multislot.generateMultiSlotMod()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as MultiSlot-Mods and the MultiSlot-Base-Mod, (Lag-Spike)")
            end
            
            
            if imgui.Button("Generate MuliSlot-Mods concurrently") then
                if not extensions.isExtensionLoaded("tommot_multislot") then
                    extensions.load("tommot_multislot")
                    setExtensionUnloadMode("tommot_multislot", "manual")
                end
                core_jobsystem.create(tommot_multislot.generateMultiSlotJob, concurrencyDelay[0])
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as MultiSlot-Mods and the MultiSlot-Base-Mod, less lag")
            end


            if imgui.Button("Generate SingleSlot-Mods") then
                gmsg.generateSeparateMods()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as normal \"Additional Modification\"-Mods, (Lag-Spike)")
            end

            if imgui.Button("Generate SingleSlot-Mods concurrently") then
                core_jobsystem.create(gmsg.generateSeparateJob, tonumber(concurrencyDelay[0]))
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as normal \"Additional Modification\"-Mods, less lag")
            end

            if imgui.Button("Generate MultiSlot-Mods from Additional Mods") then
                extensions.load("tommot_additionalToMultiSlot")
                additionalToMultiSlot.additionalToMultiSlot()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates MultiSlot-Mods from Additional Mods, which are not generated by the Mod")
            end

            if imgui.Button("Generate MultiSlot-Mods from Additional Mods concurrently") then
                extensions.load("tommot_additionalToMultiSlot")
                core_jobsystem.create(additionalToMultiSlot.additionalToMultiSlotJob, tonumber(concurrencyDelay[0]))
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates MultiSlot-Mods from Additional Mods, which are not generated by the Mod, less lag")
            end


            imgui.EndTabItem()
        end

    
        if imgui.BeginTabItem("Settings") then
            imgui.Checkbox("##generateSeparateCheckbox", generateSeparateCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Generate Separate Mods", generateSeparateCheckboxValue[0]) then
                generateSeparateCheckboxValue[0] = not generateSeparateCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("If enabled, makes the Mod generate all Templates as normal \"Additional Modification\"-Mods")
            end

            imgui.Checkbox("##generateMultiSlotCheckbox", generateMultiSlotCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Generate MultiSlot Mods", generateMultiSlotCheckboxValue[0]) then
                generateMultiSlotCheckboxValue[0] = not generateMultiSlotCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("If enabled, makes the Mod generate all Templates as MultiSlot-Mods, which use the MultiSlot-Base-\"Additional Modification\"-Mod")
            end

            imgui.Checkbox("##generateAdditionalCheckbox", generateAdditionalCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Generate Additional as MultiSlot-Mods", generateAdditionalCheckboxValue[0]) then
                generateAdditionalCheckboxValue[0] = not generateAdditionalCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("If enabled, combines both the Template-Mods and the normal Additional-Mods into MultiSlot-Mods, which use the MultiSlot-Base-\"Additional Modification\"-Mod")
            end

            imgui.Checkbox("##detailedDebugCheckbox", detailedDebugCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Detailed Debug", detailedDebugCheckboxValue[0]) then
                detailedDebugCheckboxValue[0] = not detailedDebugCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("If enabled, the Mod will log more detailed information to the console and the UI (may impact performance)")
            end

            imgui.Checkbox("##useCoroutinesCheckbox", useCoroutinesCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Generate Mods concurrently (less of a lag spike)", useCoroutinesCheckboxValue[0]) then
                useCoroutinesCheckboxValue[0] = not useCoroutinesCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("If enabled, the Mod will generate Mods concurrently, which will reduce the lag spike when generating Mods (disabling will impact performance)")
            end

            imgui.Checkbox("##autopackAllCheckbox", autopackAllCheckboxValue)
            imgui.SameLine()
            if imgui.Selectable1("Autopack all generated Mods", autopackAllCheckboxValue[0]) then
                autopackAllCheckboxValue[0] = not autopackAllCheckboxValue[0]
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("(WIP, buggy!) If enabled, all generated Mods will be automatically packed into a .zip file, which will then be in the mods-Folder, instead of the unpacked folder. \nThis can improve performance and reduce clutter & file size, but may make GMSG / MultiSlot-Generation slower and more complex")
            end

            imgui.Text("Log Level:")
            if imgui.BeginCombo("##logLevelCombo", logLevelOptions[logLevelSelected[0]+1]) then
                for i, level in ipairs(logLevelOptions) do
                    if imgui.Selectable1(level, (i-1) == logLevelSelected[0]) then
                        logLevelSelected[0] = i-1
                        LOGLEVEL = i-1
                        --gmsg.setLogLevel(i-1)
                    end
                end
                imgui.EndCombo()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Sets the log level for the Mod (0 = no logs, 1 = info/warnings, 2 = all logs)")
            end
            
        
            if imgui.Button("Save Settings") then
                local settings = {
                    SeparateMods = generateSeparateCheckboxValue[0],
                    MultiSlotMods = generateMultiSlotCheckboxValue[0],
                    DetailedDebug = detailedDebugCheckboxValue[0],
                    UseCoroutines = useCoroutinesCheckboxValue[0],
                    AutoApplySettings = false,
                    Autopack = autopackAllCheckboxValue[0],
                    AdditionalToMultiSlot = generateAdditionalCheckboxValue[0],
                    LogLevel = logLevelSelected[0]
                }
                dump(settings)
                gmsg.setModSettings(jsonEncode(settings))
            end
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Utils") then
            if imgui.Button("Get Templates") then
                templates = getTemplate()
                gmsg_templates.getTemplateNames()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Reloads the Templates from the mods-Folder, updates the list in the UI and the Mod")
            end

            if imgui.Button("Reload ModDB") then
                core_modmanager.initDB()  
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Reloads the ModDB by running the vanilla initDB, which will update the list of Mods in the Mod-Manager")
            end
            imgui.Checkbox("##advancedMode", advancedModeCheckbox)
            imgui.SameLine()
            imgui.Text("Advanced Mode")
           if imgui.IsItemHovered() then
                imgui.SetTooltip("Enable advanced features (use with caution)")
            end

            if advancedModeCheckbox[0] then
                if imgui.Button("Reload GELUA") then
                    Lua:requestReload()
                    ui_message('engine.lua.reloaded', 2, 'lua', 'refresh')
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Reloads all Lua extensions (warning: will lag the game and take a moment)")
                end

                if imgui.Button("Reload gmsgUI") then
                    toggleUI()
                    local function reloadUIJob()
                        extensions.unload("tommot_gmsgUI")
                        extensions.load("tommot_gmsgUI")
                        return
                    end
                    core_jobsystem.create(reloadUIJob, 1/60)
                end

                if imgui.Button("Reload GMSG / MultiSlot") then
                    toggleUI()
                    local function reloadGMSGJob()
                        extensions.unload("tommot_modslotGenerator")
                        extensions.load("tommot_modslotGenerator")
                        return
                    end
                    core_jobsystem.create(reloadGMSGJob, 1/60)
                end

                loadedExtensions = extensions.getLoadedExtensionsNames()
                if loadedExtensions then
                    if imgui.BeginCombo("##loadedExtensions", selectedExtension == "" and "Select an extension" or selectedExtension) then
                        for _, extName in ipairs(loadedExtensions) do
                            if imgui.Selectable1(extName, extName == selectedExtension) then
                                selectedExtension = extName
                                gmsg.logToConsole('I', "ExtensionSelected", "Selected extension: " .. extName)
                            end
                        end
                        imgui.EndCombo()
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip("Select an extension to reload it")
                    end
                    
                    imgui.SameLine()
                    if imgui.Button("Reload Selected Extension") and selectedExtension ~= "" then
                        gmsg.logToConsole('I', "ExtensionReload", "Reloading extension: " .. selectedExtension)
                        local function reloadExtensionJob()
                            extensions.unload(selectedExtension)
                            extensions.load(selectedExtension)
                            return
                        end
                        core_jobsystem.create(reloadExtensionJob, 1/60)
                    end
                    if imgui.IsItemHovered() then
                        imgui.SetTooltip("Reloads the selected extension")
                    end
                end


                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Reloads all Lua extensions (warning: will lag the game and take a moment)")
                end


                if imgui.Button("Load Dependency Installer UI") then
                    extensions.load("tommot_depInstallerUi")
                end
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("Loads the Dependency Installer UI extension (gmsgDownloader needs to be installed)")
                end

                if imgui.SliderFloat("##concurrencyDelay", concurrencyDelay, 1/1000, 1/1) then
                    gmsg.setConcurrencyDelay(concurrencyDelay[0])
                end
                imgui.SameLine()
                imgui.Text("Concurrency Delay")
                if imgui.IsItemHovered() then
                    imgui.SetTooltip("sets the delay for concurrent generation (default: 2/3 seconds)")
                end
            end
            imgui.EndTabItem()
        end
    
        imgui.EndTabBar()
    end
    
    imgui.End()
end

local function onUpdate(dtReal)
    if not M.showUI then return end

    local success, err = pcall(render, dtReal)
    if not success and err then
        print("Error in onUpdate: " .. err)
    end
end

local function onExtensionLoaded()
    getTemplate()
    loadSettings()
end

local function onExtensionUnloaded()
    if M.showUI then
        toggleUI()
    end
end

M.onUpdate = onUpdate
M.toggleUI = toggleUI
M.onExtensionLoaded = onExtensionLoaded
M.onExtensionUnloaded = onExtensionUnloaded

return M