print("jiii")
local file_path = "C:\\Users\\MH\\Desktop\\日语单词\\0117.xlsx"
local lfs = require "lfs"
-- 获取文件大小
local file_size = lfs.attributes(file_path, "size")
print("文件大小：" .. file_size .. " bytes")

-- 获取文件修改日期
local modification_time = lfs.attributes(file_path, "modification")
print("文件修改日期：" .. os.date("%Y-%m-%d %H:%M:%S", modification_time))
