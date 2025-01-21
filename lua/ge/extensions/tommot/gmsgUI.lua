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

local function getTemplate()
    return gmsg.loadTemplateNames()
end

local templates = getTemplate()
local selectedTemplate = templates[1]

local outputPath = ffi.new("char[?]", 256, "/gmsg/output/")

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

    if imgui.Button("Generate all") then
        gmsg.generateSpecificMod(selectedTemplate, selectedTemplate, ffi.string(outputPath))
    end

    if imgui.Button("Get Templates") then
        templates = getTemplate()
        gmsg.getTemplateNames()
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