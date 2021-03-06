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
- Add `FilePath.delete(recursive:)` which deletes the content at `self`.
- Add `FilePath.withTemproraryDirectory(run:)` which runs a closure with a newly created temporary directory
  as the working directory, and removes the temporary directory, restores original working directories
  afterwards.
- Add the following convenient method for reading and writing on a file path:
    * `FilePath.readBytes(fromAbsoluteOffset:)`: read bytes from `self`
    * `FilePath.readString(as:)`: read bytes and encode to string with a specified encoding.
    * `FilePath.readUTF8String()`: read bytes and encode to UTF-8 string.
    * `FilePath.write(:options:permissions:)`: write sequence of bytes to `self`.
    * `FilePath.write(utf8:options:permissions:)`: write a string decoded with UTF-8 to `self`.

Add `FilePath.set(_:)` method, which sets new `FilePermission` at `self`.
