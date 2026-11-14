# Changelog

## Minimap Button Frame Enhanced 3.1 (2026-11-14)

### Fixed
- `LibDataBroker-1.1` folder was named `libdatabroker-1-1`, so the path in `embeds.xml` failed and the library never loaded.
- `locale.xml` referenced a missing `Locale-esMX.lua`, causing a load error. Added the file (currently a copy of the esES text).
- Package shipped without `libs`, `Locale` and `Textures`. All are now bundled, so the addon works standalone.
- Skin Pack never loaded because it checked for the old `MinimapButtonFrame` addon name.


## Minimap Button Frame Enhanced Skin Pack 3.1

### Changed
- Renamed to `Minimap_Button_Frame_Enhanced_SkinPack`.
- Now requires `Minimap_Button_Frame_Enhanced` (`## Dependencies`), replacing the old optional dependency.
- All skin texture paths updated to the new folder name.

## Installation
Extract both folders into `Interface\AddOns\`. Remove any original `MinimapButtonFrame` / `MinimapButtonFrame_SkinPack` folders first, since they share the `MBFDB` saved variables and global names.

## Credits
Original addon by Bachlott. Enhanced edition by Angelouss. Skin graphics by their original artists (ClassRings and EmotionRings by Jeffy162).
