local test = {}
function test:run()
    GetFilesMd5(GetFilesInFolder("D:/Closers.cocos/client/branches/test",
        { ".vscode", ".vs", ".svn", ".git", "imports" }))
end

return test
