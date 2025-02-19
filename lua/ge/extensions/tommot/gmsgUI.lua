-- GMSG UI
-- Author: Toemmsen / TommoT

local M = {}
M.dependencies = {"ui_imgui"}
M.showUI = false

local imgui = ui_imgui
local imguiUtils = require("/lua/common/extensions/ui/imguiUtils")
local gmsg = tommot_modslotGenerator
local style = imgui.GetStyle()
local ffi = require("ffi")
local SETTINGS_PATH = "/settings/GMSG_Settings.json"

-- Settings
local outputPath = ffi.new("char[?]", 256, "/unpacked/gmsg_out/")
local autopackCheckboxValue = ffi.new("bool[1]", false)
local autopackAllCheckboxValue = ffi.new("bool[1]", false)
local generateSeparateCheckboxValue = ffi.new("bool[1]", false)
local generateMultiSlotCheckboxValue = ffi.new("bool[1]", true)
local detailedDebugCheckboxValue = ffi.new("bool[1]", true)
local useCoroutinesCheckboxValue = ffi.new("bool[1]", true)
local includeMStemplate = ffi.new("bool[1]", true)
local addDependencyDownloader = ffi.new("bool[1]", true)
local advancedModeCheckbox = ffi.new("bool[1]", false)
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
    return gmsg.loadTemplateNames()
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
            if imgui.BeginCombo("Select Template", selectedTemplate) then
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
                gmsg.generateMultiSlotMod()
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as MultiSlot-Mods and the MultiSlot-Base-Mod, (Lag-Spike)")
            end
            
            
            if imgui.Button("Generate MuliSlot-Mods concurrently") then
                core_jobsystem.create(gmsg.generateMultiSlotJob, 1/100)
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
                core_jobsystem.create(gmsg.generateSeparateJob, 1/100)
            end
            if imgui.IsItemHovered() then
                imgui.SetTooltip("Generates all Templates as normal \"Additional Modification\"-Mods, less lag")
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
                imgui.SetTooltip("If enabled, all generated Mods will be automatically packed into a .zip file, which will then be in the mods-Folder, instead of the unpacked folder. \nThis can improve performance and reduce clutter & file size, but may make GMSG / MultiSlot-Generation slower and more complex")
            end
        
            if imgui.Button("Save Settings") then
                local settings = {
                    SeparateMods = generateSeparateCheckboxValue[0],
                    MultiSlotMods = generateMultiSlotCheckboxValue[0],
                    DetailedDebug = detailedDebugCheckboxValue[0],
                    UseCoroutines = useCoroutinesCheckboxValue[0],
                    AutoApplySettings = false,
                    Autopack = autopackAllCheckboxValue[0]
                }
                dump(settings)
                gmsg.setModSettings(jsonEncode(settings))
            end
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Utils") then
            if imgui.Button("Get Templates") then
                templates = getTemplate()
                gmsg.getTemplateNames()
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