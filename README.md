# Titanius Launcher

[![Codemagic build status](https://api.codemagic.io/apps/641a93e956ceb17664370612/android-workflow/status_badge.svg)](https://codemagic.io/apps/641a93e956ceb17664370612/android-workflow/latest_build)

- Inspired by EmulationStation and AmberELEC
- Controller-first navigations
- Unsophisticated, minimalistic UI

## How to use

By design, Titanius Launcher does not come with a game scraper. 
The idea is to reuse your existing, pre-scraped roms library on both Linux devices that run AmberELEC, ArkOS, etc and your Android device.

1. Arrange ROMs in a folder structure like this: [AmbeELEC](https://amberelec.org/systems/)
2. Use [Skraper](https://www.skraper.net/) to scrape your ROMs and generate `gamelist.xml` files along with images and/or videos
3. Copy your ROMs to your Android device's internal storage or an SD card into one of the following locations: `Internal Storage/Roms`, `SD Card root`, `SD Card/Roms`
4. Configure Titanius Launcher to include the ROMs folder
5. Enjoy!

## Screenshots

## Deliberate Constraints

- Not designed to be used as a general purpose launcher
- To simplify configuration, looks for roms in specific locations: 

## Attributions

[Console logos created by Dan Patrick](https://archive.org/details/console-logos-professionally-redrawn-plus-official-versions)
[App icon created by Irfansusanto20 - Flaticon](https://www.flaticon.com/free-icons/game-console)