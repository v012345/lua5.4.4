---comment
---@param file string
---@return integer
function GetFileLastModifiedTimestamp(file) return 0 end

---递归出给出文件夹的全部文件
---@param folder string 文件夹
---@param exclude table 排除的文件夹
---@return table
function GetFilesInFolder(folder, exclude) return {} end

---返回编译后的操作指令
---@return table
function GetOpCodes() return {} end

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
---@return nil
function DeleteFile(file) return nil end

---comment
---@param file any
---@return boolean
function IsFileExist(file) return true end

---comment
---@param ... unknown
---@return nil
function StackDump(...) return nil end

---comment
---@param files table
---@return table
function GetFilesMd5(files) return {} end

---comment
---@param files table
---@return table
function GetFilesLastModifiedTimestamp(files) return {} end

---comment
---@param from_state any
---@param by_label any
---@param to_state any
---@param ... unknown
---@return FA_State_Matrix_Entry
function FA_State_Matrix_Entry(from_state, by_label, to_state, ...) end

---comment
---@param files string
---@return table
function ChunkDump(files) return {} end

_Lua_function = {}
