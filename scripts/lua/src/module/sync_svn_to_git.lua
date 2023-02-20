local sync = {}
function sync:run()
    local config = require "config"
    print("sync src ...")
    local gitSrc = config["git"][argv["branch"]]["src"]
    local svnSrc = config["svn"][argv["branch"]]["src"]

    local gitSrcInfo = GetFilesMd5(GetFilesInFolder(gitSrc))
    local svnSrcInfo = GetFilesMd5(GetFilesInFolder(svnSrc))

    local isSame = true
    for gitSrcFileName, gitSrcFileMd5 in pairs(gitSrcInfo) do
        local svnSrcFileName = string.gsub(gitSrcFileName, gitSrc, svnSrc, 1)

        local svnSrcFileMd5 = svnSrcInfo[svnSrcFileName]
        if gitSrcFileMd5 == svnSrcFileMd5 then
            gitSrcInfo[gitSrcFileName] = nil
            svnSrcInfo[svnSrcFileName] = nil
        else
            isSame = false
        end
    end
    if not isSame then
        local count = 0
        for gitSrcFileName, _ in pairs(gitSrcInfo) do
            local svnSrcFileName = string.gsub(gitSrcFileName, gitSrc, svnSrc, 1)

            local svnSrcFileMd5 = svnSrcInfo[svnSrcFileName]
            if svnSrcFileMd5 then
                print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " is different")
                CopyFile(svnSrcFileName, gitSrcFileName)
                gitSrcInfo[gitSrcFileName] = nil
                svnSrcInfo[svnSrcFileName] = nil
                count = count + 1
            end
        end
        for gitSrcFileName, _ in pairs(gitSrcInfo) do
            -- print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " only exists in git")
            DeleteFile(gitSrcFileName)
        end
        for svnSrcFileName, _ in pairs(svnSrcInfo) do
            -- print(string.gsub(svnSrcFileName, svnSrc, "", 1) .. " only exists in svn")
            CopyFile(svnSrcFileName, string.gsub(svnSrcFileName, svnSrc, gitSrc, 1))
        end
    end


    print("sync res ...")
    gitSrc = config["git"][argv["branch"]]["res"]
    svnSrc = config["svn"][argv["branch"]]["res"]

    gitSrcInfo = GetFilesMd5(GetFilesInFolder(gitSrc))
    svnSrcInfo = GetFilesMd5(GetFilesInFolder(svnSrc))

    isSame = true
    for gitSrcFileName, gitSrcFileMd5 in pairs(gitSrcInfo) do
        local svnSrcFileName = string.gsub(gitSrcFileName, gitSrc, svnSrc, 1)

        local svnSrcFileMd5 = svnSrcInfo[svnSrcFileName]
        if gitSrcFileMd5 == svnSrcFileMd5 then
            gitSrcInfo[gitSrcFileName] = nil
            svnSrcInfo[svnSrcFileName] = nil
        else
            isSame = false
        end
    end
    if not isSame then
        local count = 0
        for gitSrcFileName, _ in pairs(gitSrcInfo) do
            local svnSrcFileName = string.gsub(gitSrcFileName, gitSrc, svnSrc, 1)

            local svnSrcFileMd5 = svnSrcInfo[svnSrcFileName]
            if svnSrcFileMd5 then
                print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " is different")
                CopyFile(svnSrcFileName, gitSrcFileName)
                gitSrcInfo[gitSrcFileName] = nil
                svnSrcInfo[svnSrcFileName] = nil
                count = count + 1
            end
        end
        for gitSrcFileName, _ in pairs(gitSrcInfo) do
            -- print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " only exists in git")
            DeleteFile(gitSrcFileName)
        end
        for svnSrcFileName, _ in pairs(svnSrcInfo) do
            -- print(string.gsub(svnSrcFileName, svnSrc, "", 1) .. " only exists in svn")
            CopyFile(svnSrcFileName, string.gsub(svnSrcFileName, svnSrc, gitSrc, 1))
        end
    end
end

return sync
