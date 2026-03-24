A virtual IBM PC-style computer running inside Roblox.

Includes CPU, memory, BIOS, VGA display, disk system, and a bootable OS.
Interact with low-level hardware, observe the boot process, and experiment with system behavior in real time.

## Machina Package

This repo vendors the upstream `machina-roblox` release bundle into `vendor/machina`.

Refresh it locally with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\import-machina.ps1
```

Import a specific upstream tag with:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\import-machina.ps1 -Version v0.2.0
```

## Automation

- `CI` builds the place on pushes and pull requests.
- `Sync Machina` can be run manually or on its daily schedule to import the latest upstream Machina release and open a PR.
- `Release` builds `MachinaLab.rbxlx` and attaches it to a GitHub release when you push a tag like `v1.2.3`.
- `Publish` deploys the place to Roblox from `main`.

`Publish` requires:

- `secrets.ROBLOX_API_KEY`
- `vars.ROBLOX_UNIVERSE_ID`
- `vars.ROBLOX_PLACE_ID`
