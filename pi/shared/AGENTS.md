## File Deletion Safety

To prevent accidental data loss, follow these rules whenever deleting files or directories:

1. **Never perform recursive deletion on user-owned or pre-existing directories.** Do not use commands or options that recursively delete such directories or their contents, including but not limited to:
   - `del /s`
   - `rd /s`
   - `rmdir /s`
   - `Remove-Item -Recurse`
   - `rm -r`
   - `rm -rf`

2. **Only delete explicitly specified files.** When deletion is necessary, you may delete one or more individual files by specifying their exact paths.

   Allowed example:
   ```bash
   rm a.txt b.txt
   ```

3. **Never use wildcards or dynamic path expansion for deletion.** Do not use patterns such as `*.txt`, recursive globs, or variables that could expand to an unintended set of files.

4. **AI-created directories may be deleted only under strict conditions.** You may delete a directory recursively only if:
   - You created the directory yourself during the current task.
   - You can verify that the directory is dedicated to temporary files, testing, or other task-specific artifacts.
   - The directory does not contain any pre-existing user data or files created by the user or other processes.
   - The exact target path is explicitly specified, without wildcards or ambiguous path expansion.

   If any of these conditions cannot be verified, stop and ask the user to perform the deletion manually.

5. **When in doubt, do not delete.** If the target paths, ownership, or deletion scope are ambiguous, stop and ask the user for clarification.
