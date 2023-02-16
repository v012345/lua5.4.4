local compare = {}
function compare:run()
    local config = require "config"
    local gitSrc = config["git"][argv["branch"]]["src"]
    local svnSrc = config["svn"][argv["branch"]]["src"]

    local gitSrcInfo = GetFilesInfoInDirectoryRecursivelyMultiThreads(gitSrc)
    local svnSrcInfo = GetFilesInfoInDirectoryRecursivelyMultiThreads(svnSrc)

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
    if isSame then
        print("-------------- no different --------------")
        return
    end
    local count = 0
    for gitSrcFileName, _ in pairs(gitSrcInfo) do
        local svnSrcFileName = string.gsub(gitSrcFileName, gitSrc, svnSrc, 1)

        local svnSrcFileMd5 = svnSrcInfo[svnSrcFileName]
        if svnSrcFileMd5 then
            print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " is different")
            gitSrcInfo[gitSrcFileName] = nil
            svnSrcInfo[svnSrcFileName] = nil
            count = count + 1
        end
    end
    if count > 0 then
        print(count .. " files are different")
        print()
        print()
    end
    for gitSrcFileName, _ in pairs(gitSrcInfo) do
        print(string.gsub(gitSrcFileName, gitSrc, "", 1) .. " only exists in git")
    end
    for svnSrcFileName, _ in pairs(svnSrcInfo) do
        print(string.gsub(svnSrcFileName, svnSrc, "", 1) .. " only exists in svn")
    end
end

return compare
