local test = {}
function test:run()
    WriteConfigTableToFile("./config/files_timestamp.lua", GetFilesLastModifiedTimestamp(GetFilesInFolder("D:/ZZM",
        { ".vscode", ".vs", ".svn", ".git", "imports" })))
end

return test
