local root = script.Parent
local modules = {
	["src/Config"] = root.src.Config,
	["src/platform/Contracts"] = root.src.platform.Contracts,
	["src/platforms/x86/Assembler8086"] = root.src.platforms.x86.Assembler8086,
	["src/platforms/x86/BiosInterrupts"] = root.src.platforms.x86.BiosInterrupts,
	["src/platforms/x86/BiosRom"] = root.src.platforms.x86.BiosRom,
	["src/platforms/x86/BootController"] = root.src.platforms.x86.BootController,
	["src/platforms/x86/BootImageCatalog"] = root.src.platforms.x86.BootImageCatalog,
	["src/platforms/x86/BootImageCatalogProductionImages"] = root.src.platforms.x86.BootImageCatalogProductionImages,
	["src/platforms/x86/BootImageCatalogUtils"] = root.src.platforms.x86.BootImageCatalogUtils,
	["src/platforms/x86/BootImageCatalogValidationImages"] = root.src.platforms.x86.BootImageCatalogValidationImages,
	["src/platforms/x86/BootImageLoader"] = root.src.platforms.x86.BootImageLoader,
	["src/platforms/x86/Cpu80386"] = root.src.platforms.x86.Cpu80386,
	["src/platforms/x86/Cpu8086"] = root.src.platforms.x86.Cpu8086,
	["src/platforms/x86/devices/AtaController"] = root.src.platforms.x86.devices.AtaController,
	["src/platforms/x86/devices/CmosRtc"] = root.src.platforms.x86.devices.CmosRtc,
	["src/platforms/x86/devices/FirmwareRom"] = root.src.platforms.x86.devices.FirmwareRom,
	["src/platforms/x86/devices/I8042Controller"] = root.src.platforms.x86.devices.I8042Controller,
	["src/platforms/x86/devices/PhysicalMemory"] = root.src.platforms.x86.devices.PhysicalMemory,
	["src/platforms/x86/devices/Pic8259"] = root.src.platforms.x86.devices.Pic8259,
	["src/platforms/x86/devices/Pit8254"] = root.src.platforms.x86.devices.Pit8254,
	["src/platforms/x86/devices/SystemBus"] = root.src.platforms.x86.devices.SystemBus,
	["src/platforms/x86/devices/Uart8250"] = root.src.platforms.x86.devices.Uart8250,
	["src/platforms/x86/devices/VgaAdapter"] = root.src.platforms.x86.devices.VgaAdapter,
	["src/platforms/x86/HardwareDiagnostics"] = root.src.platforms.x86.HardwareDiagnostics,
	["src/platforms/x86/HardwareDiagnosticsState"] = root.src.platforms.x86.HardwareDiagnosticsState,
	["src/platforms/x86/ImageCatalogUtils"] = root.src.platforms.x86.ImageCatalogUtils,
	["src/platforms/x86/ImportedImageCatalog"] = root.src.platforms.x86.ImportedImageCatalog,
	["src/platforms/x86/PcSystem"] = root.src.platforms.x86.PcSystem,
	["src/platforms/x86/ProtectedModeSelfTest"] = root.src.platforms.x86.ProtectedModeSelfTest,
	["src/platforms/x86/RawImageCatalog"] = root.src.platforms.x86.RawImageCatalog,
}

local Package = {
	Name = "machina-roblox",
	Version = "v0.2.0",
}

Package.EntryPoints = {
	config = modules["src/Config"],
	machine = modules["src/platforms/x86/PcSystem"],
	platformContracts = modules["src/platform/Contracts"],
}

function Package.getModule(moduleId)
	local moduleScript = modules[moduleId]
	assert(moduleScript, "machina-roblox: unknown module id " .. tostring(moduleId))
	return moduleScript
end

function Package.requireById(moduleId)
	return require(Package.getModule(moduleId))
end

function Package.requireConfig()
	return Package.requireById("src/Config")
end

function Package.requireMachine()
	return Package.requireById("src/platforms/x86/PcSystem")
end

function Package.requirePlatformContracts()
	return Package.requireById("src/platform/Contracts")
end

return Package

