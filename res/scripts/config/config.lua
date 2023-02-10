local SVN_TRUNK = "D:/Closers.cocos/client/trunk/Resources/"
local SVN_TEST = "D:/Closers.cocos/client/branches/test/Resources/"
local SVN_ONLINE = "D:/Closers.cocos/client/branches/online/Resources/"

local GIT_TRUNK = "D:/BlackMoonExtend/Client/GameCode/Resources/"
local GIT_TEST = "D:/BlackMoonExtend/Client/GameCode/Resources/"
local GIT_ONLINE = "D:/BlackMoonExtend/Client/GameCode/Resources/"


local config = {
    trunk = {
        svn = {
            src = SVN_TRUNK .. "src",
            res = SVN_TRUNK .. "res",
            src_md5 = "trunk_svn_src_md5",
            res_md5 = "trunk_svn_res_md5"
        },
        git = {
            src = GIT_TRUNK .. "src",
            res = GIT_TRUNK .. "res",
            src_md5 = "trunk_git_src_md5",
            res_md5 = "trunk_git_res_md5"
        }
    },
    test = {
        svn = {
            src = SVN_TEST .. "src",
            res = SVN_TEST .. "res",
            src_md5 = "test_svn_src_md5",
            res_md5 = "test_svn_res_md5"
        },
        git = {
            src = GIT_TEST .. "src",
            res = GIT_TEST .. "res",
            src_md5 = "test_git_src_md5",
            res_md5 = "test_git_res_md5"
        }
    },
    online = {
        svn = {
            src = SVN_ONLINE .. "src",
            res = SVN_ONLINE .. "res",
            src_md5 = "online_svn_src_md5",
            res_md5 = "online_svn_res_md5"
        },
        git = {
            src = GIT_ONLINE .. "src",
            res = GIT_ONLINE .. "res",
            src_md5 = "online_git_src_md5",
            res_md5 = "online_git_res_md5"
        }
    }
}



return config
