# Titanius Launcher

[![Codemagic build status](https://api.codemagic.io/apps/641a93e956ceb17664370612/android-workflow/status_badge.svg)](https://codemagic.io/apps/641a93e956ceb17664370612/android-workflow/latest_build)

Titanius Launcher is a minimalistic, controller-first game launcher designed for those who want to enjoy a seamless gaming experience on their Android devices. 
Inspired by EmulationStation and AmberELEC, it allows users to easily integrate their pre-scraped ROMs libraries from Linux systems like AmberELEC and ArkOS. With its straightforward setup and uncomplicated user interface, Titanius Launcher is perfect for gamers who appreciate simplicity and an efficient gaming experience.

## Download

Download the latest apk from the [Releases](https://github.com/dsolonenko/titanius-launcher/releases) page.

## How to use

By design, Titanius Launcher does not come with a game scraper. 
The idea is to reuse your existing, pre-scraped ROMs library on both Linux devices that run AmberELEC, ArkOS, etc and your Android device.

1. Arrange ROMs in a folder structure like this: [AmbeELEC](https://amberelec.org/systems/)
2. Use [Skraper](https://www.skraper.net/) to scrape your ROMs and generate `gamelist.xml` files along with images and/or videos
3. Copy your ROMs to your Android device's Internal Storage or SD card into one of the following locations: `Internal Storage/Roms`, `SD Card root`, `SD Card/Roms`
4. Configure Titanius Launcher to include the ROMs folder
5. Enjoy!

## Deliberate Constraints

1. This is work in progress. Expect bugs and crashes.
2. Not designed to be used as a general purpose launcher. If you are looking for someting more powerful, check out [Daijishō](https://github.com/magneticchen/Daijishou)
3. Only [Retroarch 64-bit](https://buildbot.libretro.com/stable/1.15.0/android/RetroArch_aarch64.apk) and some standalone emulators are configured right now. For the list of supported systems and emulators see [JSON config file](assets/metadata.json).

## Screenshots

Landing page with a scrolling list of systems:
![Screenshot 1](assets/screenshots/01.png)
![Screenshot 3](assets/screenshots/03.png)

Games page:
![Screenshot 2](assets/screenshots/02.png)
![Screenshot 4](assets/screenshots/04.png)

Folders support:
![Screenshot 5](assets/screenshots/05.png)

Android apps:
![Screenshot 9](assets/screenshots/09.png)
![Screenshot 10](assets/screenshots/10.png)

Some settings:
![Screenshot 6](assets/screenshots/06.png)
![Screenshot 7](assets/screenshots/07.png)
![Screenshot 8](assets/screenshots/08.png)

## Attributions

- [Console logos created by Dan Patrick](https://archive.org/details/console-logos-professionally-redrawn-plus-official-versions)
- [App icon created by Irfansusanto20 - Flaticon](https://www.flaticon.com/free-icons/game-console)