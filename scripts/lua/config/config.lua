local SVN_TRUNK = "D:/Closers.cocos/client/trunk/Resources/"
local SVN_TEST = "D:/Closers.cocos/client/branches/test/Resources/"
local SVN_ONLINE = "D:/Closers.cocos/client/branches/online/Resources/"

local GIT_TRUNK = "D:/BlackMoonExtend/Client/GameCode/Resources/"
local GIT_TEST = "D:/BlackMoon/Client/Resources/"
local GIT_ONLINE = "D:/BlackMoon/Client/Resources/"
local config = {
    git = {
        online = {
            src = GIT_ONLINE .. "src",
            res = GIT_ONLINE .. "res",
            src_md5 = "git_online_src_md5",
            res_md5 = "git_online_res_md5"
        },
        test = {
            src = GIT_TEST .. "src",
            res = GIT_TEST .. "res",
            src_md5 = "git_test_src_md5",
            res_md5 = "git_test_res_md5"
        },
        trunk = {
            src = GIT_TRUNK .. "src",
            res = GIT_TRUNK .. "res",
            src_md5 = "git_trunk_src_md5",
            res_md5 = "git_trunk_res_md5"
        }
    },
    svn = {
        online = {
            src = SVN_ONLINE .. "src",
            res = SVN_ONLINE .. "res",
            src_md5 = "svn_online_src_md5",
            res_md5 = "svn_online_res_md5"
        },
        test = {
            src = SVN_TEST .. "src",
            res = SVN_TEST .. "res",
            src_md5 = "svn_test_src_md5",
            res_md5 = "svn_test_res_md5"
        },
        trunk = {
            src = SVN_TRUNK .. "src",
            res = SVN_TRUNK .. "res",
            src_md5 = "svn_trunk_src_md5",
            res_md5 = "svn_trunk_res_md5"
        }
    }
}

return config
