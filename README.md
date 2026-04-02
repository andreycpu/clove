# Clove

A lightweight macOS menu bar app that turns your clipboard history, screenshots, and downloads into a frosted-glass inventory panel - inspired by the item grid from Animal Crossing.

![Clove demo](assets/demo.gif)

## What it does

- **Clipboard** - automatically captures text snippets and copied images
- **Screenshots** - watches `~/Desktop` for new screenshots (where macOS saves them by default)
- **Downloads** - watches `~/Downloads` for new files
- Holds up to 10 items (configurable up to 50) with persistence across sessions
- Green copy button on hover to paste any item back to clipboard
- Red capacity warning when full - choose to replace oldest or adjust the limit

## Quick Start

```bash
git clone https://github.com/andreycpu/clove.git
cd clove
bash setup.sh
open Clove.xcodeproj
```

Then press `Cmd+R` in Xcode to build and run. Clove will appear as a leaf icon in your menu bar.

### Requirements

- macOS 13.0+
- Xcode 15+
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (installed automatically by `setup.sh` via Homebrew)

## Usage

- **Cmd+Shift+V** - toggle the Clove panel from anywhere
- **Click the menu bar icon** - also toggles the panel
- **Press 1-9** - copy the corresponding item back to clipboard and dismiss
- **Hover an item** - reveals the green copy button
- **Escape** - dismiss the panel
- **Settings** - click the gear icon to adjust the item limit and clear history

## Design

- Frosted glass (`.hudWindow` vibrancy) pill panel drops down from the menu bar
- Zero CPU at rest - clipboard uses a timer with OS-batched tolerance, folder watching uses kernel-level `DispatchSource` events
- Images stored as compressed 80x80 JPEG thumbnails - original files are never duplicated
- All data persists to `~/Library/Application Support/Clove/items.json`

## License

MIT
