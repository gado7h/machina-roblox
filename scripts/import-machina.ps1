param(
	[string]$Version = "latest",
	[string]$Repository = "gado7h/Machina",
	[string]$VendorPath = "vendor/machina",
	[string]$DownloadDirectory = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-GitHubHeaders() {
	return @{
		"Accept" = "application/vnd.github+json"
		"User-Agent" = "machina-roblox-importer"
		"X-GitHub-Api-Version" = "2022-11-28"
	}
}

function Get-Release([string]$repo, [string]$requestedVersion) {
	$baseUri = "https://api.github.com/repos/$repo/releases"
	$uri = if ([string]::IsNullOrWhiteSpace($requestedVersion) -or $requestedVersion -eq "latest") {
		"$baseUri/latest"
	} else {
		"$baseUri/tags/$requestedVersion"
	}

	return Invoke-RestMethod -Headers (Get-GitHubHeaders) -Uri $uri
}

function Get-Asset([object]$release, [string]$assetName) {
	$asset = $release.assets | Where-Object { $_.name -eq $assetName } | Select-Object -First 1
	if (-not $asset) {
		throw "Release '$($release.tag_name)' did not contain required asset '$assetName'."
	}

	return $asset
}

function Resolve-AbsolutePath([string]$path) {
	if ([System.IO.Path]::IsPathRooted($path)) {
		return $path
	}

	return Join-Path (Get-Location) $path
}

function Copy-DirectoryContents([string]$sourceDirectory, [string]$destinationDirectory) {
	if (Test-Path $destinationDirectory) {
		Remove-Item -Recurse -Force $destinationDirectory
	}

	New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null
	Copy-Item -Path (Join-Path $sourceDirectory "*") -Destination $destinationDirectory -Recurse -Force
}

$release = Get-Release -repo $Repository -requestedVersion $Version
$resolvedVersion = $release.tag_name
$packageAssetName = "machina-roblox-$resolvedVersion.tar.gz"
$metadataAssetName = "machina-release-metadata-$resolvedVersion.json"

$packageAsset = Get-Asset -release $release -assetName $packageAssetName
$metadataAsset = Get-Asset -release $release -assetName $metadataAssetName

$resolvedDownloadDirectory = if ([string]::IsNullOrWhiteSpace($DownloadDirectory)) {
	Join-Path ([System.IO.Path]::GetTempPath()) ("machina-download-" + [guid]::NewGuid().ToString("N"))
} else {
	Resolve-AbsolutePath $DownloadDirectory
}

$resolvedVendorPath = Resolve-AbsolutePath $VendorPath
$extractRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("machina-extract-" + [guid]::NewGuid().ToString("N"))

New-Item -ItemType Directory -Force -Path $resolvedDownloadDirectory | Out-Null
New-Item -ItemType Directory -Force -Path $extractRoot | Out-Null

$packageArchivePath = Join-Path $resolvedDownloadDirectory $packageAsset.name
$metadataPath = Join-Path $resolvedDownloadDirectory $metadataAsset.name

try {
	Invoke-WebRequest -Headers (Get-GitHubHeaders) -Uri $packageAsset.browser_download_url -OutFile $packageArchivePath
	Invoke-WebRequest -Headers (Get-GitHubHeaders) -Uri $metadataAsset.browser_download_url -OutFile $metadataPath

	$metadata = Get-Content -Raw -Path $metadataPath | ConvertFrom-Json
	$expectedHash = $metadata.artifacts."machina-roblox".sha256.ToLowerInvariant()
	$actualHash = (Get-FileHash -Path $packageArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()

	if ($actualHash -ne $expectedHash) {
		throw "Checksum mismatch for '$packageAssetName'. Expected $expectedHash but got $actualHash."
	}

	& tar -xzf $packageArchivePath -C $extractRoot
	if ($LASTEXITCODE -ne 0) {
		throw "Failed to extract '$packageAssetName'."
	}

	$packageRoot = Join-Path $extractRoot "machina-roblox"
	if (-not (Test-Path $packageRoot)) {
		throw "Extracted package did not contain 'machina-roblox/'."
	}

	Copy-DirectoryContents -sourceDirectory $packageRoot -destinationDirectory $resolvedVendorPath

	[ordered]@{
		package = "machina-roblox"
		version = $resolvedVersion
		repository = $Repository
		releaseUrl = $release.html_url
		packageAssetUrl = $packageAsset.browser_download_url
		metadataAssetUrl = $metadataAsset.browser_download_url
		gitRef = $metadata.gitRef
		importedAtUtc = [DateTime]::UtcNow.ToString("o")
	} | ConvertTo-Json -Depth 6 | Set-Content -Path (Join-Path $resolvedVendorPath ".machina-import.json")

	Write-Host "Imported machina-roblox $resolvedVersion into $resolvedVendorPath"
} finally {
	if ([string]::IsNullOrWhiteSpace($DownloadDirectory) -and (Test-Path $resolvedDownloadDirectory)) {
		Remove-Item -Recurse -Force $resolvedDownloadDirectory
	}

	if (Test-Path $extractRoot) {
		Remove-Item -Recurse -Force $extractRoot
	}
}
