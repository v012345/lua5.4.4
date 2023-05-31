
local file_path ="C:/Users/Meteor/Desktop/v2-1495b2ab24e5a03635e1b82cbd97b91e_r.jpg"

-- 获取文件大小
local file_size = lfs.attributes(file_path, "size")
print("文件大小：" .. file_size .. " bytes")

-- 获取文件修改日期
local modification_time = lfs.attributes(file_path, "modification")
print("文件修改日期：" .. os.date("%Y-%m-%d %H:%M:%S", modification_time))
