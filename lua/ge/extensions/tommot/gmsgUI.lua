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
local detailedDebugCheckboxValue = ffi.new("bool[1]", true)
local useCoroutinesCheckboxValue = ffi.new("bool[1]", true)
-- End Settings

local function loadSettings()
    local settings = jsonReadFile(SETTINGS_PATH)
    if settings == nil then
        log('W', 'loadSettings', "Failed to any saved settings, using defaults")
        settings = jsonReadFile("/lua/ge/extensions/tommot/GMSG_Settings.json")
    end
    if settings ~= nil then
        generateSeparateCheckboxValue[0] = settings.SeparateMods
        detailedDebugCheckboxValue[0] = settings.DetailedDebug
        useCoroutinesCheckboxValue[0] = settings.UseCoroutines
        autopackAllCheckboxValue[0] = settings.Autopack
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
    
            imgui.Text("Enter Output Path:")
            imgui.InputText("##outputPath", outputPath, 256, imgui.InputTextFlags_EnterReturnsTrue)
    
            if imgui.Button("Generate selected Mod") then
                gmsg.generateSpecificMod(selectedTemplate, selectedTemplate, ffi.string(outputPath), autopackCheckboxValue[0])
            end
    
            imgui.Checkbox("##autopackCheckbox", autopackCheckboxValue)
            imgui.SameLine()
            imgui.Text("Autopack generated Mod")
    
            imgui.EndTabItem()
        end

        if imgui.BeginTabItem("Generate Manually") then
            if imgui.Button("Generate MuliSlot-Mods") then
                gmsg.generateMultiSlotMod()
            end
            if imgui.Button("Generate SingleSlot-Mods") then
                gmsg.generateSeparateMods()
            end
            imgui.EndTabItem()
        end

    
        if imgui.BeginTabItem("Settings") then
            imgui.Checkbox("##generateSeparateCheckbox", generateSeparateCheckboxValue)
            imgui.SameLine()
            imgui.Text("Generate Separate Mods")
        
            imgui.Checkbox("##detailedDebugCheckbox", detailedDebugCheckboxValue)
            imgui.SameLine()
            imgui.Text("Detailed Debug")
        
            imgui.Checkbox("##useCoroutinesCheckbox", useCoroutinesCheckboxValue)
            imgui.SameLine()
            imgui.Text("Generate Mods concurrently (less of a lag spike)")
        
            imgui.Checkbox("##autopackAllCheckbox", autopackAllCheckboxValue)
            imgui.SameLine()
            imgui.Text("Autopack all generated Mods")
        
            if imgui.Button("Save Settings") then
                local settings = {
                    SeparateMods = generateSeparateCheckboxValue[0],
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