
## Project Technology

1. Swift (ver 5+) is the main language
2. SwiftUI is a UI framework
3. App target platform is macOS 14.5+ (AppKit and other macOS APIs are available)
4. Swift concurrency for asynchronous programming

## Project Architecture

1. App main UI coordinator is XDevMan/Main/ContentView.swift

- The main UI container is NavigationSplitView
- The left side of the split view is a menu with a list of features (sidebar)
- The center side of the split view is a list view with sub-features (content)
- The right side of the split view is a sub-feature details view (details)

2. Each feature consists of:

- View components under the directory XDevMan/Sidebar/${FEATURE_NAME}/ for `content` and `details` views
- Business non-UI logic is in the Swift file XDevMan/Services/${FEATURE_NAME}Service.swift for whole one feature

3. Available code to reuse for a feature:

- Access to cli tools and macOS file system use XDevMan/CliTool/CliTool+Bash.swift
- For small reusable UI components use components from XDevMan/Views/ directory where:

`BaseErrorView` – view to show Error

`BashOpenView` – special styled ui button to open a given directory in macOS Finder

`ByteSizeView` – Text like view to show byte size (takes Int byte as a parameter)

`DeleteIconView` – app universal delete icon view

`NothingView` – empty view with a styled text

`OpenLinkView` – app universal button to open a link (https) in macOS browser

`PasteboardCopyView` – app universal button to copy text to pasteboard

`StringSizeView` – View that asynchronously asks size, then shows spinner and on a result shows size as Text view

## How to create a new feature

1. **MUST NOT** read all project files except listed below to reduce AI token usage.
2. To create a feature you need:

- Take a look at the source file XDevMan/Services/CarthageService.swift as an example of business logic structure (it is a completed feature)
- Take a look at the directory XDevMan/Sidebar/Carthage/ as an example of UI components structure for a new feature (it is a completed feature)
- Create a new Swift file XDevMan/Services/${FEATURE_NAME}Service.swift for business logic place for a new feature
- Create a new directory XDevMan/Sidebar/${FEATURE_NAME}/ for UI components and create there UI components for a new feature
- If you need access to macOS file system or cli tools, use XDevMan/CliTool/CliTool+Bash.swift
- For the UI part try to reuse UI components from XDevMan/Views/ directory if needed
- For each feature view component source file (under directory XDevMan/Sidebar/${FEATURE_NAME}/) also add there SwiftUI Preview (#Preview macro with test data)
- Add a new feature service to EnvironmentValues in XDevMan/Services/${FEATURE_NAME}Service.swift (example is in XDevMan/Services/CarthageService.swift)
- Inject into the app environment real new feature service in XDevMan/Main/XDevMan.swift
- Inject into the test environment mocked new feature service in XDevMan/Utils/View+AppMocks.swift
- Add feature enum key into enum MainMenuItem at XDevMan/Main/MainMenu.swift if not already there
- Add to XDevMan/Main/ContentView.swift using new feature (content and details)
