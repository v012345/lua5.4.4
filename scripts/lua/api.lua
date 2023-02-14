---comment
---@param file string
---@return integer
function GetFileLastModifiedTimestamp(file) return 0 end

---comment
---@param path string
---@return table
function GetFilesInfoInDirectory(path) return {} end

---comment
---@param path string
---@return table
function GetFilesTypeInDirectory(path) return {} end

---comment
---@param files table
---@return nil
function CopyFileMultiThreads(files) return nil end

---comment
---@param origin string
---@param target string
---@return boolean
function CopyFile(origin, target) return true end

---comment
---@return string
function GetMainLuaFilePath() return "" end

---comment
---@param file string
---@return string
function GetFileMd5(file) return "" end

---comment
---@param file any
---@return boolean
function IsFileExist(file) return true end

---命令行参数
argv = {}
