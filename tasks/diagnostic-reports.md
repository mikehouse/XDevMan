
Add a new feature called DiagnosticReports

First must read how to add a feature at the file ../AGENTS.md

What DiagnosticReports feature should look like.

1. Logic behind the feature.

macOS has a directory '/Users/$USER/Library/Logs/DiagnosticReports' with the text files that contain the diagnostic reports. Also, there is a subdirectory 'Retired' that contains the old reports. We want to show in the app the content of diagnostic reports files.

2. When a user selects the 'DiagnosticReports' feature from a menu, then on 'content' we should show a list of files names with rules:

- Show progress when loading the list of files
- Do not show hidden files
- First, show files from the main directory in the list section called 'Reports'
- The next section called 'Retired' should show files from the subdirectory 'Retired'
- As files have long names, they should be truncated in the middle (option of a text ui component).
- In the toolbar show the open folder button to open the DiagnosticReports directory in Finder.
- Sort the files by creation. First, show the most recent files.
- In the toolbar show the 'Refresh' button to refresh the list.

3. When a user selects a file from the list

- On 'details' show creation date (year, month, day, hour, minute, second)
- The below date should show the full file name (it can be multiline)
- After that show the content of the file.
- In the toolbar show the 'Trash' button to delete the file. On click you delete the file without confirmation to the trash bin that a user is able to restore it later if needed.
