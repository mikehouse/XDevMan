
Add a new feature called SwiftPMGraph

First must read how to add a feature at the file ../AGENTS.md

What SwiftPMGraph feature should look like.

1. Logic behind the feature.

We want to show a dependency graph on UI for dependencies that were integrated into the Xcode app using Swift Package Manager (SwiftPM). When SwiftPM integrates a dependency(es) into the Xcode app, it creates Package.resolved JSON file that describes all the dependencies. We already have a service that parses Package.resolved JSON file and extracts all the dependencies, the service is called SwiftPMService and is in the file XDevMan/services/SwiftPMService.swift.

## Logic details

1. When the user clicks on the SwiftPMGraph feature in the menu.

- we show on content a button to select a folder (see example from Fastlane feature), when the folder is selected, hide the button.
- also we show such a button on the toolbar for a case when the user wants to re-open the folder
- when a folder is selected, also should show in the toolbar a folder button that opens the selected folder in Finder.

2. Validate the folder logic

- When a folder is selected, we have to find a Package.resolved JSON file.
- First we look for this file in the selected folder itself
- Then we search in the selected folder '*.xcodeproj' directory. If found, then append to that folder the 'project.xcworkspace/xcshareddata/swiftpm/Package.resolved' path and check if the file exists.
- If no file is found, then show an error popup.

3. When we found a Package.resolved JSON file for the selected folder.

- Show on 'content' a progress view, hide the 'add folder' button. Progress goes from 0 to a number of dependencies on the graph. Counter for progress view should take from SwiftPMService.buildGraph when waiting for graph resolution of Package.resolved JSON file. The above progress view should show the current dependency name being processed by SwiftPMService.buildGraph. If got an error, then show an error popup. On Success on 'content' should show a list of top most graphs names that are:

```swift
let graph = swiftPMService.buildGraph(...)
let topmost = graph.map { $0.value }
```

4. When a user selects a dependency name from the 'content' list, then update the 'details' view.

- We should show a dependency graph for the selected Graph. Graphs we parse from topmost `graph.description` of the Graph object that returns string representation of the graph with dependency names.

```swift
let string = graph.description
```

that has the following format:

```swift
"""
swift-navigation
 -> swift-collections
 -> swift-docc-plugin
 -> swift-case-paths
 ->  -> swift-benchmark
 ->  ->  -> swift-argument-parser
 ->  -> xctest-dynamic-overlay
 ->  ->  -> swift-docc-plugin
 ->  ->  -> carton
 ->  ->  ->  -> swift-log
 ->  ->  ->  ->  -> swift-docc-plugin
 ->  ->  ->  -> swift-argument-parser
 ->  ->  ->  -> swift-nio
 ->  ->  ->  -> wasmtransformer
 ->  ->  ->  ->  -> swift-argument-parser
 ->  -> swift-docc-plugin
 -> swift-concurrency-extras
 ->  -> swift-docc-plugin
 -> swift-custom-dump
"""
```

We will split the string with a new line and drop the first line to get a result as

```swift
let lines = [
" -> swift-collections",
" -> swift-docc-plugin",
" -> swift-case-paths",
" ->  -> swift-benchmark",
" ->  ->  -> swift-argument-parser",
" ->  -> xctest-dynamic-overlay",
" ->  ->  -> swift-docc-plugin",
" ->  ->  -> carton",
" ->  ->  ->  -> swift-log",
" ->  ->  ->  ->  -> swift-docc-plugin",
" ->  ->  ->  -> swift-argument-parser",
" ->  ->  ->  -> swift-nio",
" ->  ->  ->  -> wasmtransformer",
" ->  ->  ->  ->  -> swift-argument-parser",
" ->  -> swift-docc-plugin",
" -> swift-concurrency-extras",
" ->  -> swift-docc-plugin",
" -> swift-custom-dump",
 ]
```

After that each line we split with a Graph.marker to get a result like

```swift
let lines = [
    ["", "swift-collections"],
    ["", "swift-docc-plugin"],
    ["", "swift-case-paths"],
    ["", "", "swift-benchmark"]
]
```

after that for each array in the root array drop the first element to get a result like

```swift
let lines = [
    ["swift-collections"],
    ["swift-docc-plugin"],
    ["swift-case-paths"],
    ["", "swift-benchmark"]
]
```

Then lay out the arrays on UI. If an element is an empty string, then show a rectangle with width = 32, if not, show a button with a string title. On the button click should find in the graph a dependency and open it in a browser with location url + revision or version as each not empty element represents a dependency name / identity. Lay out each array in a horizontal direction. You may do it like this:

```swift
ScrollView {
    ForEach(lines) { line in
        HStack {
            ForEach(line) { element in
                if element.isEmpty {
                    Rectangle()
                        .frame(width: 32)
                } else {
                    Button(element) {
                        // On click find the dependency with this name in graph and open in browser it with location url + revision / version.
                        for graph in graphs {
                            if let dependency = graph.graph(element) {
                                // open in browser
                            }
                        }
                    }
                }
            }
        }
    }
}
```

That is all about this feature.

