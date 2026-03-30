-- Auto-generated Machina package
-- Root is script (works for both games and most tools)

local root = script

-- Auto-generated module registry
local modules = {
	["@src/Contracts"] = root.src.Contracts,
	["@src/DefaultConfiguration"] = root.src.DefaultConfiguration,
	["@src/platforms/x86/Assembler8086"] = root.src.platforms.x86.Assembler8086,
	["@src/platforms/x86/BiosInterrupts"] = root.src.platforms.x86.BiosInterrupts,
	["@src/platforms/x86/BiosRom"] = root.src.platforms.x86.BiosRom,
	["@src/platforms/x86/BootController"] = root.src.platforms.x86.BootController,
	["@src/platforms/x86/BootImageCatalog"] = root.src.platforms.x86.BootImageCatalog,
	["@src/platforms/x86/BootImageCatalogProductionImages"] = root.src.platforms.x86.BootImageCatalogProductionImages,
	["@src/platforms/x86/BootImageCatalogUtils"] = root.src.platforms.x86.BootImageCatalogUtils,
	["@src/platforms/x86/BootImageCatalogValidationImages"] = root.src.platforms.x86.BootImageCatalogValidationImages,
	["@src/platforms/x86/BootImageLoader"] = root.src.platforms.x86.BootImageLoader,
	["@src/platforms/x86/Cpu80386"] = root.src.platforms.x86.Cpu80386,
	["@src/platforms/x86/Cpu8086"] = root.src.platforms.x86.Cpu8086,
	["@src/platforms/x86/devices/AtaController"] = root.src.platforms.x86.devices.AtaController,
	["@src/platforms/x86/devices/CmosRtc"] = root.src.platforms.x86.devices.CmosRtc,
	["@src/platforms/x86/devices/FirmwareRom"] = root.src.platforms.x86.devices.FirmwareRom,
	["@src/platforms/x86/devices/I8042Controller"] = root.src.platforms.x86.devices.I8042Controller,
	["@src/platforms/x86/devices/PhysicalMemory"] = root.src.platforms.x86.devices.PhysicalMemory,
	["@src/platforms/x86/devices/Pic8259"] = root.src.platforms.x86.devices.Pic8259,
	["@src/platforms/x86/devices/Pit8254"] = root.src.platforms.x86.devices.Pit8254,
	["@src/platforms/x86/devices/SystemBus"] = root.src.platforms.x86.devices.SystemBus,
	["@src/platforms/x86/devices/Uart8250"] = root.src.platforms.x86.devices.Uart8250,
	["@src/platforms/x86/devices/VgaAdapter"] = root.src.platforms.x86.devices.VgaAdapter,
	["@src/platforms/x86/HardwareDiagnostics"] = root.src.platforms.x86.HardwareDiagnostics,
	["@src/platforms/x86/HardwareDiagnosticsState"] = root.src.platforms.x86.HardwareDiagnosticsState,
	["@src/platforms/x86/ImageCatalogUtils"] = root.src.platforms.x86.ImageCatalogUtils,
	["@src/platforms/x86/ImportedImageCatalog"] = root.src.platforms.x86.ImportedImageCatalog,
	["@src/platforms/x86/PcSystem"] = root.src.platforms.x86.PcSystem,
	["@src/platforms/x86/ProtectedModeSelfTest"] = root.src.platforms.x86.ProtectedModeSelfTest,
	["@src/platforms/x86/RawImageCatalog"] = root.src.platforms.x86.RawImageCatalog,
}

local Package = {
	Name = "machina-roblox",
	Version = "v0.3.1",
}

-- Deep copy a table recursively
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- Merge overrides into base config
local function mergeConfig(base, overrides)
	if not overrides then
		return deepCopy(base)
	end
	local config = deepCopy(base)
	for key, value in pairs(overrides) do
		if type(value) == "table" then
			if config[key] == nil then
				config[key] = {}
			end
			for k, v in pairs(value) do
				config[key][k] = v
			end
		else
			config[key] = value
		end
	end
	return config
end

-- Get the default configuration (as function)
function Package.default()
	local DefaultConfiguration = Package.require("@src/DefaultConfiguration")
	return deepCopy(DefaultConfiguration)
end

-- Build config with overrides
function Package.build(overrides)
	local DefaultConfiguration = Package.require("@src/DefaultConfiguration")
	return mergeConfig(DefaultConfiguration, overrides)
end

-- Entry points for common dependencies
Package.machine = modules["@src/platforms/x86/PcSystem"]
Package.Contracts = modules["@src/Contracts"]

-- Resolve a module ID to a Roblox script instance
function Package.resolve(moduleId)
	local moduleScript = modules[moduleId]
	assert(moduleScript, "machina: unknown module " .. tostring(moduleId))
	return moduleScript
end

-- Require a module by its ID
function Package.require(moduleId)
	return require(Package.resolve(moduleId))
end

-- Get the PcSystem machine
function Package.getMachine()
	return Package.require("@src/platforms/x86/PcSystem")
end

-- Get platform contracts
function Package.getContracts()
	return Package.require("@src/Contracts")
end

return Package

