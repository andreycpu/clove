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

## Requirements

- macOS 13.0+
- Xcode 15+

## Build

```bash
# Install xcodegen (one-time)
brew install xcodegen

# Generate Xcode project and open it
bash setup.sh
open Clove.xcodeproj
```

Hit `Cmd+R` in Xcode to build and run. Clove will appear as a bag icon (`􀎭`) in your menu bar.

## Usage

- **Click the bag icon** to open/close the panel
- **Hover an item** to reveal the green copy button
- **Right-click an item** for copy, reveal in Finder, or remove
- **Settings** - click the gear icon or use `Cmd+,` to adjust the item limit and clear history

## Design

- Frosted glass (`.hudWindow` vibrancy) pill panel drops down from the menu bar
- Zero CPU at rest - clipboard uses a timer with OS-batched tolerance, folder watching uses kernel-level `DispatchSource` events
- Images stored as compressed 80x80 JPEG thumbnails - original files are never duplicated
- All data persists to `~/Library/Application Support/Clove/items.json`

## License

MIT
