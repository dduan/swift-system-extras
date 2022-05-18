# main

- Add `FileMetadata` type to reperesent file metadata
- Add `FilePath.metadata()` method to retrieve file metadata
- Add `FilePath.workingDirectory()` static method for returning current working directory.
- Add `FilePath.setWorkingDirectory()` static method for setting current working directory.
- Add `FilePath.exists()` method that checks whether a path exists.
- Add `FilePath.makeDirectory(withParants:permissions:)` method that creates a directory and its parents.
- Add `FilePath.searchForTemporaryDirectory()` static method that finds default temporary directory in an OS.
- Add `FilePath.defaultTemporaryDirectory` static variable that dictates root of all temporary directories.
- Add `FilePath.makeTemporaryDirectory()` static method that makes temporary directory with writable access.
- Add `FilePath.asWorkingDirectory()` method which execute a closure with `self` as the working directory, and
  then restores the original working directory.
- Add `FilePath.directoryContent(recursive:)` method. This method returns a `Sequence` `DirectoryContent`,
  whose element is a 2-tuple of file path and type in `self`, if `self` is a directory.
