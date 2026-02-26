
Add a new feature called Scipio

First must read how to add a feature at the file ../AGENTS.md

What Scipio feature should look like.

1. Scipio it is a command line tool that converts SwiftPM (Package.swift) file to binary files for each library found in that package file. Sometimes there is no `Package.swift` file when the target is an Xcode App project as it only has `Package.resolved` in JSON format. In this case we will convert `Package.resolved` to  `Package.swift`. What feature will do:

- Our app will ask a user to select a directory where `scipio` binary file is located to invoke it in terminal later
- Our app will ask a user to select a directory where `Package.swift` file that we will pass to `scipio` binary file
- Our app will ask a user to select a directory where `Package.resolved` file, then convert it to `Package.swift` that we will pass to `scipio` binary file

2. How to convert `Package.resolved` to `Package.swift`

This is a sample of `Package.resolved` file:

```json
{
  "originHash" : "8804a02cc6cc5bbf90a4368d3382e7f53ae9ea2fca54d7e1e30316bb266adb37",
  "pins" : [
    {
      "identity" : "apngkit",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/onevcat/APNGKit.git",
      "state" : {
        "revision" : "f1807697d455b258cae7522b939372b4652437c1"
      }
    },
    {
      "identity" : "delegate",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/onevcat/Delegate.git",
      "state" : {
        "revision" : "ec3014ca2621c717f758d8718ec90e84b6e774b3"
      }
    }
  ],
  "version" : 3
}
```

After converting it to `Package.swift` that will look like:

```swift
// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MyAppDependencies",
    platforms: [
        // Specify platforms to build
        .iOS(.v14),
    ],
    products: [],
    dependencies: [
        // Add dependencies
        .package(url: "https://github.com/onevcat/APNGKit.git", revision: "f1807697d455b258cae7522b939372b4652437c1"),
        .package(url: "https://github.com/onevcat/Delegate.git", revision: "ec3014ca2621c717f758d8718ec90e84b6e774b3"),
    ],
    targets: [
        .target(
            name: "MyAppDependency",
            dependencies: [
                // List all dependencies to build
                .product(name: "APNGKit", package: "APNGKit"),
                .product(name: "Delegate", package: "Delegate"),
            ]),
    ]
)
```

The rules to make a conversion from `Package.resolved` to `Package.swift` file:

- Use this JSON above example as a template where you need to update `platforms`, `dependencies` and `targets` arrays
- Our converter only supports the iOS platform
- You need to set a minimum iOS version to `platforms` array, that is `.iOS(.v${iOS_MIN_VERSION})`. We will support versions: 14, 15, 16, 17, 18, 26
- You need to set a swift version to `swift-tools-version`, that is `swift-tools-version: ${SWIFT_VERSION}`
- Next step 'dependencies' array. It should contain all the dependencies that are listed in `Package.resolved` file. That is

```json
    {
      "identity" : "apngkit",
      "kind" : "remoteSourceControl",
      "location" : "https://github.com/onevcat/APNGKit.git",
      "state" : {
        "revision" : "f1807697d455b258cae7522b939372b4652437c1"
      }
    }
```

translates to package dependency:

```swift
.package(url: "https://github.com/onevcat/APNGKit.git", revision: "f1807697d455b258cae7522b939372b4652437c1")
```

- Next step `targets.target.dependencies` array. List there all the dependencies that were added to `dependencies` array. For product `name` and `package` values use last path component of the URL by deleting the `.git` suffix from it, except for `name` make it capitalized. That us for "https://github.com/onevcat/APNGKit.git" the product will be `.product(name: "APNGKit", package: "APNGKit")`

3. When a user selected Scipio feature in the menu, then should hide the 'content' section.
4. In the 'details' section:

- Show 'add folder' button to select a directory where `scipio` binary file is located and there near the button show text with a path to scipio binary when user selected correct directory. Name it as like "scipio executable". User may re-select the directory. When the user has selected the correct directory, show also a folder button to open the selected directory in Finder.  

How to validate the scipio directory. When user selected a directory, then add to it a `scipio` path and check that this file exists, if so then show on UI part else show error popup.

- Then we need to show configurations that Scipio supports.

Key `configuration` is a list of values two string types that are 'release', or 'debug'. By default, set to 'release'.
Key `framework-type` is a list of values three string types that are 'dynamic', 'static' and 'mergeable'. By default, set to 'dynamic'.
Key `embed-debug-symbols` has a boolean value. By default, set to 'false'.
Key `support-simulators` has a boolean value. By default, set to 'true'.
Key `enable-library-evolution` has a boolean value. By default, set to 'true'.
Key `strip-static-lib-dwarf-symbols` has a boolean value. By default, set to 'false'.

- Show 'add folder' button to select a directory where `Package.swift` or `Package.resolved`. Name it as like "Package.swift | Package.resolved". The same behavior as for the 'add scipio' directory button.

How to validate the directory for `Package.swift` and `Package.resolved`. First, look for `Package.swift` by adding 'Package.swift' to the directory and check file existance. If a file exists, use its path as the final result. If a file does not exist, then we try to find `Package.resolved` file. First, append to the directory path 'Package.resolved' and check file existence, if so, use it as a valid result. If no file is found, then in that directory (not recursively) look for first the directory '*.xcodeproj', of not found show error popup. If a directory is found, then append to the found directory '/project.xcworkspace/xcshareddata/swiftpm/Package.resolved' and check a file for existence. When exists use as a valid result else shows an error popup.

- When user has selected `Package.swift` then no changes needed. Just show its content in the text view.
- When user has selected `Package.resolved` then we need to convert it to `Package.swift` format as described above. 

After conversion do not write to disk, just show the result below all buttons in the text view.

- Show the 'Build in Terminal' button above the text view.

When user selected 'Build in Terminal' button, then create a directory called 'scipio-convert' in user-selected directory for `Package.swift` and `Package.resolved`. Then create/rewrite there `Package.swift` file with content like is in the text view. And also create in scipio-convert directory a directory named `Sources` if not exists as it needed for scipio. Then run the terminal with the command

```bash
${SCIPIO_BINARY_PATH} prepare ${SCIPIO_CONVERT_DIRECTORY} ${KEYS}
```

Where ${KEYS} are scipio configuration options. For string type configurations form command as 

```bash
--${KEY} ${VALUE}
```

for example:

```bash
--configuration release
```

For boolean type configurations if it is set to false, then skip else just add a key without a value with the prefix '--', for example `--support-simulators` 

example of a real command:

```bash
/Users/user/scipio prepare /Users/user/project/scipio-convert --configuration release --framework-type dynamic --embed-debug-symbols
```






