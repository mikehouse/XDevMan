
Add a new feature called Fastlane

First, must read how to add a feature here '../AGENTS.md'

What Fastlane feature should look like

The main idea is. As Fastlane is a tool to run scripts (lanes) described in a fastlane/Fastfile file. I want to run fastlane lanes from this app into the built-in macOS Terminal app. That is when the user clicks on a line to run, then the app opens macOS Terminal.app, prefills it with lane run command and run it. No result needed to listen from Terminal. After we opened Terminal, then full responsibility is on the user as our app just helps quickly run a script.

1. Implement open Fastlane source directory

When a user selects Fastlane from a feature menu, then for 'content' view should show a folder button that allows a user to select a directory with fastlane. On 'details' show 'No lane has selected' text. To get correct public lines, we need two files:

```bash
/bin/ls
fastlane/Fastfile
fastlane/README.md
```

where fastlane/README.md contains a list of public (can be run from terminal) available lanes, and fastlane/Fastfile contains source code for all lanes. That is why we want to select a directory instead of just a Fastfile file.
Be prepared that a user may choose a directory that contains a 'fastlane' directory or a user may choose the 'fastlane' directory itself. This all means that you need to check the existence of (when the user selects the root directory):

```bash
/bin/ls
fastlane/Fastfile
fastlane/README.md
```

or existence of (when the user selects the 'fastlane' directory):

```bash
/bin/ls
Fastfile
README.md
```

Only if these files exist, then a selected directory is valid to continue work flow else show an error that the app could not find fastlane files.

2. When a user has selected a valid directory, then show a spinner on 'content' and start scanning the files. The first file to scan is fastlane/README.md as it contains a list of public lanes. File looks like this:

```markdown
fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed

# Available Actions

### make_ipa

[bundle exec] fastlane make_ipa

## iOS

### ios crowdin_upload

[bundle exec] fastlane ios crowdin_upload

----

This README.md is auto-generated and will be re-generated every time

```

as you can see after 'Available Actions' there is a list of public lanes/actions. You must parse each action/lane name, from the example above there are two public actions `make_ipa` and `ios crowdin_upload` available.

After you found all public lanes, then we need to find these lanes in the Fastfile source file to know what arguments each lane supports. For example, the lane 'make_ipa' in Fastfile has such code:

```ruby
lane :make_ipa do |options|
  # set any Xcode version you comfortable with.
  xcodes(version: "16.2", select_for_current_build_only: true)
  build_app(
    scheme: "Some App",
    workspace: "Some App.xcworkspace",
    export_method: "development",
    configuration: "Release"
  )
end
```

as you can see it has `options` parameter, but there is no read operation from it, that means this lane does not care about input parameters, that means it does not support input parameters when invoke this lane from terminal.

Second lane from example `ios crowdin_upload` has such source code: 

```ruby
platform :ios do
  
  lane :crowdin_upload do |options|
    if git_branch != "develop"
      UI.user_error!("'" + git_branch + "' is not a proper branch for crowdin upload, please use 'develop' branch")
    end
    sh('cd ..; sh ./crowdin_upload.sh protection')

    verbose = options[:verbose].nil? ? false : options[:verbose]
    next unless verbose

    sleep 10

    crowdin_download(options)
  end

  private_lane :crowdin_download  do |options|
    git_bot_action(options[:slack]) {
      crowdin_create_MR(options)
    }
  end

  def git_bot_action(slack)
    if slack == true
      slack_send(e.message, true)
    end
  end
  
end
```

where you can see that from `options` the boolean value `verbose` is read, that means this lane supports input with boolean type and called `verbose`. Also, you can see that `options` passed to lane `crowdin_download` where from `options` read `slack` value, we also need to mark this as input parameter `slack`, but to know its type we need to go to function `git_bot_action` from where we understand that `slack` is boolean type. After all of this scanning from examples we got that lane `make_ipa` has no input arguments, lane `crowdin_upload` has two boolean arguments `verbose` and `slack`. We collect this info when parsing because later we will suggest to a user to input these fields. If you cannot determine the type of input parameter, then mark it as `String` type, in this case do not scan other files to determine the type of input parameter to keep parser code less complex.

3. After scanning when some lanes/ actions are found, then on 'content' show a list of these lanes without its input parameters. If no lanes are found, then show again folder button to open a directory and error that no fastlane actions found. Also, add a folder button to the toolbar to open a directory that the user has selected in case the user wants to see the results of a lane run.

4. When a user selects an action from the list, then on 'details' should show a template for the whole lane command like this:

```txt
CheckBox '[bundle exec]' ${LANE_NAME} #{LANE_INPUT_1_NAME} TextView #{LANE_INPUT_2_NAME} TextView [run in terminal]
```

where `CheckBox` view means that for the lane command to run we need to add `bundle exec` prefix, by default is checked. TextView means TextField like a view in one line where a user may enter value for the input parameter, placeholder should describe the type of input parameter. If the input parameter is boolean, then show a checkbox instead of TextView, by default, is unchecked.

`[run in terminal]` is a button that opens macOS Terminal.app, prefills it with the whole lane run command that got constucted from template and user input. To run a command in the terminal seems better to use bash command like:

```bash
osascript -e 'tell app "Terminal" to do script "#{LANE_COMMAND}"'
```

Example after template filled and user clicks on `[run in terminal]` the command in Terminal.app will be:

```bash
# when checkbox is checked for '[bundle exec]', 'verbose' and 'slack'
bundle exec fastlane ios crowdin_upload verbose:true slack:true
# when all is unchecked
fastlane ios crowdin_upload verbose:false slack:false
```


