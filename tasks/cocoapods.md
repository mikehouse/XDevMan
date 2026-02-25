
Add a new feature called CocoaPods

What CocoaPods feature should look like

CocoaPods has a global cache for pods in directory /Users/$USER$/Library/Caches/CocoaPods/Pods

1. There is a /Users/$USER$/Library/Caches/CocoaPods/Pods/VERSION file with content as an example
```txt
1.16.2
```
that shows the current installed CocoaPods version. Show this version in the app toolbar (on the left as navigation title) when the user has selected the CocoaPods feature from a menu.

2. There is a directory /Users/$USER$/Library/Caches/CocoaPods/Pods/External/ with subdirectories. Each subdirectory represents pod (library), example is

```bash
/bin/ls
External/Biometrics # Biometrics library
External/DesignKit # DesignKit library
External/LookinServer
External/RxKeyboard
External/SectionKit
```

These libraries are libraries from private repositories or local system (that is why it is called external). Each Library there has a list of subdirectories, each subdirectory has a name as a git hash commit from where this library got fetched/cloned. Example

```bash
/bin/ls
External/Biometrics/16eb1722868e420ca55617a4b66f40c7
External/Biometrics/25db7194a5851b7842c050bd150e1857
External/LookinServer/53997e92f0092e050d538b01fa1b05a7
External/LookinServer/a021e5b6d8ba44176da0a67ffd6beec1
```

and these directories contain source code for the libraries, for example

```bash
/bin/ls
External/Biometrics/16eb1722868e420ca55617a4b66f40c7/Biometrics/Biometrics.h
External/Biometrics/16eb1722868e420ca55617a4b66f40c7/Biometrics/Biometrics.m
```

Also, there is a directory /Users/$USER$/Library/Caches/CocoaPods/Pods/Release/ that has the same structure as /Users/$USER$/Library/Caches/CocoaPods/Pods/External/. The difference is that these libraries are fetched/cloned from public repositories (like Github/Gitlab) and subdirectory named as a library version (tag) instead of git commit hash, example

```bash
/bin/ls
Release/abseil/1.20240116.2-d121d/LICENSE
Release/abseil/1.20240116.2-d121d/PrivacyInfo.xcprivacy
Release/abseil/1.20240116.2-d121d/absl/algorithm/algorithm.h
```

Also, there is a directory /Users/$USER$/Library/Caches/CocoaPods/Pods/Specs/ that contains CocoaPods specs files in JSON format for each library version. Example

```bash
/bin/ls
Specs/External/Biometrics/16eb1722868e420ca55617a4b66f40c7.podspec.json
Specs/External/Biometrics/25db7194a5851b7842c050bd150e1857.podspec.json
Specs/Release/abseil/1.20240116.2-d121d.podspec.json
```

I want you to show a list of library names in the 'content' split view from /Users/$USER$/Library/Caches/CocoaPods/Pods/Specs/External and /Users/$USER$/Library/Caches/CocoaPods/Pods/Specs/Release together. Each library will be a section, and a library section will be populated with its found versions, where a version can be taken from podspec name by dropping 'podspec.json' (for example, for 4.7.0-5ff2a.podspec.json the name will be 4.7.0-5ff2a). List structure example:

```txt
Biometrics
  16eb1722868e420ca55617a4b66f40c7
  25db7194a5851b7842c050bd150e1857
abseil
    1.20240116.2-d121d
```

When a user selects a library version, then on the details screen should show the content of *.podspec.json file for the selected library version.
Also, when a user selects a library version, then on the toolbar should show a folder button and when the user clicks on it, open the directory with source files for that selected library version

3. Add delete functionality.

When a user selects a library version, then in the toolbar should show a trash button (near existed 'folder' button). When the user clicks on it, delete that library version from the CocoaPods cache directory and reload the list. How to delete:

- delete the directory with source files for that library version
- delete the podspec file for that library version
- If all versions of the library are deleted, then delete the directories for that library from sources and specs directories