# My AwesomeWM Config

*Description goes here :)*

## Directory Structure

### `bin`

These are executables provided by this awesome config best implemented as
stand-alone tasks to be utilized across all locations.
The config build system and build hooks are installed here.

### `config`

- Defaults apps used by this config
- Buttons and key binds
- Theming and icons
- User profile
- Any other globally accessible config/settings

### `desktop`

These modules are built into the desktop and are considered "required" features
for baseline functionality.

### `lib`

Anything here is not meant to be called directly by the user-space but provided
as standard functionality for the code-base.

### `src`

Source code for `/bin` and `/lib` executables lives here.

### `utils`

These are nice-to-haves that are preferred to be built-in to the desktop rather
than installing standalone apps.
They are additional desktop features but not required for use.

- [ ] TODO: create sys util "app" drawer
- [ ] TODO: can be pinned to the control center

### `widgets`

These are wrappers on built-in widgets and custom stand-alone widgets used
across the desktop.
They define default behavior beyond what `beautiful` theming provides as well
as complex groups of widgets and functionality.
They are high-level, purpose-built, modular widgets.
