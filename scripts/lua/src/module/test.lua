local test = {}
function test:run()
    WriteConfigTableToFile("./config/files_timestamp.lua", GetFilesLastModifiedTimestamp(GetFilesInFolder("D:/Closers.cocos/client/trunk/Resources/res",
        { ".vscode", ".vs", ".svn", ".git", "imports" })))
end

return test
