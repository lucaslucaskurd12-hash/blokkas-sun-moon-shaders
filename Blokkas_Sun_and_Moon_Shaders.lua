---@diagnostic disable: undefined-global

--[[
	Blokka's Sun and Moon
	Custom Sun and Moon Shader

	IMPORTANT:
	Upload your new sun and moon PNGs to Roblox first.
	Then replace SUN_ID and MOON_ID below with the new Roblox asset IDs.

	Use as a LocalScript in:
	StarterPlayer > StarterPlayerScripts
]]

print("@Blokka's Sun and Moon Shaders loaded")

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

--// REPLACE THESE AFTER UPLOADING YOUR NEW PNGs TO ROBLOX
local SUN_ID = "110695393344514"
local MOON_ID = "96944380802416"

local SUN_IMAGE = "rbxassetid://" .. SUN_ID
local MOON_IMAGE = "rbxassetid://" .. MOON_ID

local CONFIG = {
	DefaultPreset = "BOTH",
	DefaultClockTime = 18.25,

	BrightnessBoost = 1.05,

	-- Separate distances: moon stays where you liked it, sun is farther back.
	-- Custom objects replace the default Roblox sun/moon.
	SunDistance = 2600,
	MoonDistance = 1600,

	SunPartSize = Vector3.new(1700, 1700, 2),
	MoonPartSize = Vector3.new(1350, 1350, 2),

	PositionSmoothness = 0.1,

	ToggleIconId = "rbxassetid://8498174594",
}

local currentPreset = CONFIG.DefaultPreset
local manualClockTime = CONFIG.DefaultClockTime
local selectedLightingColor = "DEFAULT"

local function cleanupOld()
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		for _, guiName in ipairs({
			"BlokkasSunAndMoonGui",
			"BlokkaShaderV10Gui", "BlokkaShaderV9Gui", "BlokkaShaderV8Gui",
			"BlokkaShaderV7Gui", "BlokkaShaderV6Gui", "BlokkaShaderV5Gui",
			"BlokkaShaderV4Gui", "BlokkaShaderV3Gui", "BlokkaShaderV2Gui",
			"BlokkaShaderGui", "MoonControlGui"
		}) do
			local oldGui = playerGui:FindFirstChild(guiName)
			if oldGui then oldGui:Destroy() end
		end
	end

	for _, folderName in ipairs({
		"BlokkasSunAndMoonObjects",
		"BlokkaShaderV10Objects", "BlokkaShaderV9Objects", "BlokkaShaderV8Objects",
		"BlokkaShaderV7Objects", "BlokkaShaderV6Objects", "BlokkaShaderV5Objects",
		"BlokkaShaderV4Objects", "BlokkaShaderV3Objects", "BlokkaShaderV2Objects",
		"BlokkaShaderBackground", "MoonlitGalaxy"
	}) do
		local oldFolder = Workspace:FindFirstChild(folderName)
		if oldFolder then oldFolder:Destroy() end
	end
end

cleanupOld()

local function clamp(value, minValue, maxValue)
	if value < minValue then return minValue end
	if value > maxValue then return maxValue end
	return value
end

local function clockToAlpha(clockTime)
	return clamp((clockTime % 24) / 24, 0, 1)
end

local function alphaToClock(alpha)
	return (clamp(alpha, 0, 1) * 24) % 24
end

local function formatClockLabel(clockTime)
	local totalMinutes = math.floor((clockTime % 24) * 60 + 0.5)
	local hours24 = math.floor(totalMinutes / 60) % 24
	local minutes = totalMinutes % 60
	local suffix = hours24 >= 12 and "PM" or "AM"
	local hours12 = hours24 % 12
	if hours12 == 0 then hours12 = 12 end
	return string.format("%d:%02d %s", hours12, minutes, suffix)
end

local function getDayAlpha(clockTime)
	local radians = ((clockTime - 6) / 24) * math.pi * 2
	return clamp((math.sin(radians) + 1) / 2, 0, 1)
end

local function getSunDirection(clockTime)
	local angle = ((clockTime - 6) / 24) * math.pi * 2
	local x = math.cos(angle)
	local y = math.sin(angle)
	local z = -0.35
	return Vector3.new(x, y, z).Unit
end

--// LIGHTING
Lighting.ClockTime = manualClockTime
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.62
Lighting.EnvironmentSpecularScale = 0.45
Lighting.ShadowSoftness = 0.36
Lighting.ExposureCompensation = 0.06

local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.Name = "BlokkasSunAndMoonSky"
sky.Parent = Lighting
sky.CelestialBodiesShown = true -- stars stay on; default sun/moon sizes are hidden
sky.SunAngularSize = 0
sky.MoonAngularSize = 0
sky.StarCount = 16000
sky.SkyboxBk = ""
sky.SkyboxDn = ""
sky.SkyboxFt = ""
sky.SkyboxLf = ""
sky.SkyboxRt = ""
sky.SkyboxUp = ""

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Parent = Lighting
atmosphere.Offset = 0.12

local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Parent = Lighting

local colorCorrection = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
colorCorrection.Parent = Lighting

local depthOfField = Lighting:FindFirstChildOfClass("DepthOfFieldEffect") or Instance.new("DepthOfFieldEffect")
depthOfField.Parent = Lighting
depthOfField.InFocusRadius = 180
depthOfField.FocusDistance = 110

--// OBJECTS
local folder = Instance.new("Folder")
folder.Name = "BlokkasSunAndMoonObjects"
folder.Parent = Workspace

local function createSurfaceCelestial(name, imageUri, size, lightColor, lightBrightness)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 1
	part.Size = size
	part.Parent = folder

	local light = Instance.new("PointLight")
	light.Name = name .. "Light"
	light.Color = lightColor
	light.Brightness = lightBrightness
	light.Range = 2400
	light.Shadows = false
	light.Parent = part

	local surface = Instance.new("SurfaceGui")
	surface.Name = name .. "Surface"
	surface.Face = Enum.NormalId.Front
	surface.AlwaysOnTop = false
	surface.LightInfluence = 0
	surface.Brightness = 4
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 1
	surface.Parent = part

	local image = Instance.new("ImageLabel")
	image.Name = "Image"
	image.Size = UDim2.fromScale(1, 1)
	image.BackgroundTransparency = 1
	image.Image = imageUri
	image.ImageTransparency = 0
	image.ImageColor3 = Color3.fromRGB(255, 255, 255)
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = surface

	return {
		part = part,
		light = light,
		surface = surface,
		image = image,
	}
end

local sunObj = createSurfaceCelestial("BlokkaSun", SUN_IMAGE, CONFIG.SunPartSize, Color3.fromRGB(255, 215, 95), 8)
local moonObj = createSurfaceCelestial("BlokkaMoon", MOON_IMAGE, CONFIG.MoonPartSize, Color3.fromRGB(235, 225, 150), 5.5)


--// LIGHTING COLOR OPTIONS
local lightingColors = {
	DEFAULT = {
		label = "Default",
		tint = Color3.fromRGB(255, 255, 255),
		ambient = Color3.fromRGB(255, 255, 255),
	},
	BLUE = {
		label = "Blue",
		tint = Color3.fromRGB(150, 185, 255),
		ambient = Color3.fromRGB(95, 125, 190),
	},
	PURPLE = {
		label = "Purple",
		tint = Color3.fromRGB(205, 145, 255),
		ambient = Color3.fromRGB(135, 85, 180),
	},
	RED = {
		label = "Red",
		tint = Color3.fromRGB(255, 115, 100),
		ambient = Color3.fromRGB(185, 55, 45),
	},
	ORANGE = {
		label = "Orange",
		tint = Color3.fromRGB(255, 185, 95),
		ambient = Color3.fromRGB(190, 110, 45),
	},
	GREEN = {
		label = "Green",
		tint = Color3.fromRGB(145, 255, 165),
		ambient = Color3.fromRGB(65, 150, 85),
	},
}

local lightingColorOrder = {"DEFAULT", "BLUE", "PURPLE", "RED", "ORANGE", "GREEN"}

local presets = {
	NORMAL = {
		label = "Normal",
		showSun = false,
		showMoon = true,
		bloodMoon = false,
		ambient = Color3.fromRGB(42, 52, 78),
		outdoor = Color3.fromRGB(70, 84, 112),
		atmosphere = Color3.fromRGB(92, 120, 172),
		decay = Color3.fromRGB(28, 36, 70),
		tint = Color3.fromRGB(178, 198, 228),
		fog = Color3.fromRGB(36, 48, 78),
		bloom = 0.92,
		saturation = -0.04,
	},
	SOUL_SUN = {
		label = "Blokka Sun",
		showSun = true,
		showMoon = false,
		bloodMoon = false,
		ambient = Color3.fromRGB(82, 58, 24),
		outdoor = Color3.fromRGB(155, 110, 40),
		atmosphere = Color3.fromRGB(190, 135, 58),
		decay = Color3.fromRGB(70, 42, 12),
		tint = Color3.fromRGB(255, 220, 150),
		fog = Color3.fromRGB(82, 58, 28),
		bloom = 1.35,
		saturation = 0.12,
	},
	MOON = {
		label = "Moon",
		showSun = false,
		showMoon = true,
		bloodMoon = false,
		ambient = Color3.fromRGB(22, 24, 48),
		outdoor = Color3.fromRGB(45, 48, 75),
		atmosphere = Color3.fromRGB(75, 82, 125),
		decay = Color3.fromRGB(18, 18, 38),
		tint = Color3.fromRGB(180, 175, 145),
		fog = Color3.fromRGB(20, 22, 42),
		bloom = 1.08,
		saturation = 0.02,
	},
	BOTH = {
		label = "Sun + Moon",
		showSun = true,
		showMoon = true,
		bloodMoon = false,
		ambient = Color3.fromRGB(58, 50, 70),
		outdoor = Color3.fromRGB(108, 88, 96),
		atmosphere = Color3.fromRGB(132, 102, 142),
		decay = Color3.fromRGB(32, 22, 52),
		tint = Color3.fromRGB(230, 200, 210),
		fog = Color3.fromRGB(45, 35, 70),
		bloom = 1.2,
		saturation = 0.04,
	},
	BLOOD_MOON = {
		label = "Blood Moon",
		showSun = false,
		showMoon = true,
		bloodMoon = true,
		ambient = Color3.fromRGB(62, 12, 16),
		outdoor = Color3.fromRGB(110, 24, 26),
		atmosphere = Color3.fromRGB(155, 35, 38),
		decay = Color3.fromRGB(72, 6, 8),
		tint = Color3.fromRGB(255, 125, 110),
		fog = Color3.fromRGB(72, 10, 14),
		bloom = 1.45,
		saturation = 0.08,
	},
}

local presetOrder = {"NORMAL", "SOUL_SUN", "MOON", "BOTH", "BLOOD_MOON"}

local function setVisible(obj, visible)
	obj.surface.Enabled = visible
	obj.light.Enabled = visible
end

local function applyLighting()
	local preset = presets[currentPreset] or presets.BOTH
	local dayAlpha = getDayAlpha(manualClockTime)
	local nightAlpha = 1 - dayAlpha

	Lighting.ClockTime = manualClockTime
	Lighting.Brightness = (1.4 + dayAlpha * 3.1 + preset.bloom * 0.24) * CONFIG.BrightnessBoost
	Lighting.Ambient = preset.ambient:Lerp(Color3.fromRGB(140, 150, 165), dayAlpha * 0.72)
	Lighting.OutdoorAmbient = preset.outdoor:Lerp(Color3.fromRGB(170, 180, 195), dayAlpha * 0.72)
	Lighting.ColorShift_Top = preset.atmosphere:Lerp(Color3.fromRGB(255, 222, 152), dayAlpha * 0.5)
	Lighting.ColorShift_Bottom = preset.decay:Lerp(Color3.fromRGB(90, 115, 150), dayAlpha * 0.4)

	Lighting.FogColor = preset.fog:Lerp(Color3.fromRGB(155, 180, 220), dayAlpha * 0.62)
	Lighting.FogStart = 80 + dayAlpha * 180
	Lighting.FogEnd = 12000

	atmosphere.Density = 0.11 + nightAlpha * 0.1
	atmosphere.Haze = 0.35 + nightAlpha * 0.95
	atmosphere.Glare = (2.4 + dayAlpha * 2.0 + preset.bloom * 0.2) * CONFIG.BrightnessBoost
	atmosphere.Color = preset.atmosphere:Lerp(Color3.fromRGB(175, 205, 245), dayAlpha * 0.65)
	atmosphere.Decay = preset.decay:Lerp(Color3.fromRGB(88, 105, 145), dayAlpha * 0.5)

	bloom.Intensity = (preset.bloom + dayAlpha * 0.12) * CONFIG.BrightnessBoost
	bloom.Size = 24 + dayAlpha * 9

	colorCorrection.TintColor = preset.tint:Lerp(Color3.fromRGB(255, 242, 215), dayAlpha * 0.42)
	colorCorrection.Brightness = -0.01 + dayAlpha * 0.025
	colorCorrection.Contrast = 0.18 + nightAlpha * 0.1
	colorCorrection.Saturation = preset.saturation + dayAlpha * 0.08

	depthOfField.FarIntensity = 0.06 + nightAlpha * 0.08
	depthOfField.NearIntensity = 0.02 + nightAlpha * 0.05

	local colorOption = lightingColors[selectedLightingColor] or lightingColors.DEFAULT
	if selectedLightingColor ~= "DEFAULT" then
		Lighting.Ambient = Lighting.Ambient:Lerp(colorOption.ambient, 0.35)
		Lighting.OutdoorAmbient = Lighting.OutdoorAmbient:Lerp(colorOption.ambient, 0.28)
		Lighting.ColorShift_Top = Lighting.ColorShift_Top:Lerp(colorOption.tint, 0.32)
		Lighting.ColorShift_Bottom = Lighting.ColorShift_Bottom:Lerp(colorOption.ambient, 0.24)
		colorCorrection.TintColor = colorCorrection.TintColor:Lerp(colorOption.tint, 0.45)
		Lighting.FogColor = Lighting.FogColor:Lerp(colorOption.ambient, 0.18)
	end

	sky.StarCount = math.floor(1800 + nightAlpha * 46000)

	setVisible(sunObj, preset.showSun)
	setVisible(moonObj, preset.showMoon)

	if preset.bloodMoon then
		moonObj.image.ImageColor3 = Color3.fromRGB(175, 45, 38)
		moonObj.light.Color = Color3.fromRGB(255, 80, 65)
		moonObj.light.Brightness = 6
	else
		moonObj.image.ImageColor3 = Color3.fromRGB(205, 195, 150)
		moonObj.light.Color = Color3.fromRGB(235, 225, 150)
		moonObj.light.Brightness = 5.5
	end

	sunObj.image.ImageColor3 = Color3.fromRGB(210, 175, 90)
	sunObj.light.Color = Color3.fromRGB(255, 215, 95)
end

local currentSunCFrame
local currentMoonCFrame

local function updateSkyObjects()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local camera = Workspace.CurrentCamera

	local basePosition
	if root then
		basePosition = root.Position
	elseif camera then
		basePosition = camera.CFrame.Position
	else
		basePosition = Vector3.zero
	end

	-- Use Roblox's actual sun/moon directions so your custom images replace the originals.
	local sunDirection = Lighting:GetSunDirection()
	local moonDirection = Lighting:GetMoonDirection()

	local sunPosition = basePosition + sunDirection * CONFIG.SunDistance
	local moonPosition = basePosition + moonDirection * CONFIG.MoonDistance

	local targetSunCFrame = CFrame.lookAt(sunPosition, basePosition)
	local targetMoonCFrame = CFrame.lookAt(moonPosition, basePosition)

	if not currentSunCFrame then currentSunCFrame = targetSunCFrame end
	if not currentMoonCFrame then currentMoonCFrame = targetMoonCFrame end

	currentSunCFrame = currentSunCFrame:Lerp(targetSunCFrame, CONFIG.PositionSmoothness)
	currentMoonCFrame = currentMoonCFrame:Lerp(targetMoonCFrame, CONFIG.PositionSmoothness)

	sunObj.part.CFrame = currentSunCFrame
	moonObj.part.CFrame = currentMoonCFrame
end

local function makeCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createGui()
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "BlokkasSunAndMoonGui"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local toggle = Instance.new("ImageButton")
	toggle.Name = "ToggleShaderMenu"
	toggle.Size = UDim2.fromOffset(40, 40)
	toggle.Position = UDim2.fromOffset(16, 16)
	toggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	toggle.BackgroundTransparency = 0.28
	toggle.BorderSizePixel = 0
	toggle.Image = CONFIG.ToggleIconId
	toggle.ScaleType = Enum.ScaleType.Fit
	toggle.Parent = gui
	makeCorner(toggle, 10)

	local panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.fromOffset(330, 410)
	panel.Position = UDim2.fromOffset(-355, 16)
	panel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	panel.BackgroundTransparency = 0.25
	panel.BorderSizePixel = 0
	panel.Parent = gui
	makeCorner(panel, 12)

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.82
	stroke.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -24, 0, 26)
	title.Position = UDim2.fromOffset(12, 10)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamSemibold
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(245, 245, 245)
	title.Text = "Blokka's Sun and Moon Shaders"
	title.Parent = panel

	local timeLabel = Instance.new("TextLabel")
	timeLabel.Size = UDim2.new(1, -24, 0, 18)
	timeLabel.Position = UDim2.fromOffset(12, 46)
	timeLabel.BackgroundTransparency = 1
	timeLabel.Font = Enum.Font.Gotham
	timeLabel.TextSize = 12
	timeLabel.TextXAlignment = Enum.TextXAlignment.Left
	timeLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	timeLabel.Text = "Day / Night: " .. formatClockLabel(manualClockTime)
	timeLabel.Parent = panel

	local sliderBar = Instance.new("Frame")
	sliderBar.Size = UDim2.new(1, -24, 0, 7)
	sliderBar.Position = UDim2.fromOffset(12, 72)
	sliderBar.BackgroundColor3 = Color3.fromRGB(28, 28, 32)
	sliderBar.BackgroundTransparency = 0.15
	sliderBar.BorderSizePixel = 0
	sliderBar.Parent = panel
	makeCorner(sliderBar, 10)

	local sliderFill = Instance.new("Frame")
	sliderFill.Size = UDim2.new(clockToAlpha(manualClockTime), 0, 1, 0)
	sliderFill.BackgroundColor3 = Color3.fromRGB(245, 215, 120)
	sliderFill.BackgroundTransparency = 0.08
	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBar
	makeCorner(sliderFill, 10)

	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(14, 14)
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Position = UDim2.new(clockToAlpha(manualClockTime), 0, 0.5, 0)
	knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	knob.BorderSizePixel = 0
	knob.Parent = sliderBar
	makeCorner(knob, 10)

	local sliderHitbox = Instance.new("TextButton")
	sliderHitbox.Size = UDim2.new(1, 0, 1, 20)
	sliderHitbox.Position = UDim2.fromOffset(0, -7)
	sliderHitbox.BackgroundTransparency = 1
	sliderHitbox.Text = ""
	sliderHitbox.Parent = sliderBar

	local presetLabel = Instance.new("TextLabel")
	presetLabel.Size = UDim2.new(1, -24, 0, 18)
	presetLabel.Position = UDim2.fromOffset(12, 102)
	presetLabel.BackgroundTransparency = 1
	presetLabel.Font = Enum.Font.Gotham
	presetLabel.TextSize = 12
	presetLabel.TextXAlignment = Enum.TextXAlignment.Left
	presetLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	presetLabel.Text = "Preset: " .. presets[currentPreset].label
	presetLabel.Parent = panel

	local buttons = {}

	for i, key in ipairs(presetOrder) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -24, 0, 26)
		button.Position = UDim2.fromOffset(12, 126 + ((i - 1) * 29))
		button.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		button.BackgroundTransparency = key == currentPreset and 0.12 or 0.42
		button.BorderSizePixel = 0
		button.Font = Enum.Font.GothamMedium
		button.TextSize = 12
		button.TextColor3 = key == currentPreset and Color3.fromRGB(255, 235, 145) or Color3.fromRGB(230, 230, 230)
		button.Text = presets[key].label
		button.Parent = panel
		makeCorner(button, 7)
		buttons[key] = button

		button.MouseButton1Click:Connect(function()
			currentPreset = key
			presetLabel.Text = "Preset: " .. presets[currentPreset].label

			for presetKey, presetButton in pairs(buttons) do
				presetButton.BackgroundTransparency = presetKey == currentPreset and 0.12 or 0.42
				presetButton.TextColor3 = presetKey == currentPreset and Color3.fromRGB(255, 235, 145) or Color3.fromRGB(230, 230, 230)
			end

			applyLighting()
			updateSkyObjects()
		end)
	end


	local colorLabel = Instance.new("TextLabel")
	colorLabel.Size = UDim2.new(1, -24, 0, 18)
	colorLabel.Position = UDim2.fromOffset(12, 276)
	colorLabel.BackgroundTransparency = 1
	colorLabel.Font = Enum.Font.Gotham
	colorLabel.TextSize = 12
	colorLabel.TextXAlignment = Enum.TextXAlignment.Left
	colorLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
	colorLabel.Text = "Lighting Color: " .. lightingColors[selectedLightingColor].label
	colorLabel.Parent = panel

	local colorButtons = {}
	local startX = 12
	local startY = 300
	local buttonW = 96
	local buttonH = 24
	local gap = 7

	for i, colorKey in ipairs(lightingColorOrder) do
		local row = math.floor((i - 1) / 3)
		local col = (i - 1) % 3

		local colorButton = Instance.new("TextButton")
		colorButton.Size = UDim2.fromOffset(buttonW, buttonH)
		colorButton.Position = UDim2.fromOffset(startX + col * (buttonW + gap), startY + row * (buttonH + gap))
		colorButton.BackgroundColor3 = Color3.fromRGB(10, 10, 12)
		colorButton.BackgroundTransparency = colorKey == selectedLightingColor and 0.12 or 0.42
		colorButton.BorderSizePixel = 0
		colorButton.Font = Enum.Font.GothamMedium
		colorButton.TextSize = 11
		colorButton.TextColor3 = colorKey == selectedLightingColor and Color3.fromRGB(255, 235, 145) or Color3.fromRGB(230, 230, 230)
		colorButton.Text = lightingColors[colorKey].label
		colorButton.Parent = panel
		makeCorner(colorButton, 7)

		colorButtons[colorKey] = colorButton

		colorButton.MouseButton1Click:Connect(function()
			selectedLightingColor = colorKey
			colorLabel.Text = "Lighting Color: " .. lightingColors[selectedLightingColor].label

			for key, button in pairs(colorButtons) do
				button.BackgroundTransparency = key == selectedLightingColor and 0.12 or 0.42
				button.TextColor3 = key == selectedLightingColor and Color3.fromRGB(255, 235, 145) or Color3.fromRGB(230, 230, 230)
			end

			applyLighting()
			updateSkyObjects()
		end)
	end


	local dragging = false

	local function setSliderFromX(x)
		local alpha = clamp((x - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
		manualClockTime = alphaToClock(alpha)
		Lighting.ClockTime = manualClockTime

		sliderFill.Size = UDim2.new(alpha, 0, 1, 0)
		knob.Position = UDim2.new(alpha, 0, 0.5, 0)
		timeLabel.Text = "Day / Night: " .. formatClockLabel(manualClockTime)

		applyLighting()
		updateSkyObjects()
	end

	sliderHitbox.MouseButton1Down:Connect(function(x)
		dragging = true
		setSliderFromX(x)
	end)

	local inputChangedConn = UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			setSliderFromX(input.Position.X)
		end
	end)

	local inputEndedConn = UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)

	local isOpen = false
	local openPos = UDim2.fromOffset(66, 16)
	local closedPos = UDim2.fromOffset(-355, 16)

	toggle.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		TweenService:Create(panel, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = isOpen and openPos or closedPos
		}):Play()
	end)

	gui.Destroying:Connect(function()
		inputChangedConn:Disconnect()
		inputEndedConn:Disconnect()
	end)
end

createGui()
applyLighting()
updateSkyObjects()

RunService.RenderStepped:Connect(function()
	Lighting.ClockTime = manualClockTime
	applyLighting()
	updateSkyObjects()
end)
