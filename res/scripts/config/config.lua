local SVN_TRUNK = "D:\\Closers.cocos\\client\\trunk\\Resources\\"
local SVN_TEST = "D:\\Closers.cocos\\client\\branches\\test\\Resources\\"
local SVN_ONLINE = "D:\\Closers.cocos\\client\\branches\\online\\Resources\\"

local GIT_TRUNK = "D:\\BlackMoonExtend\\Client\\GameCode\\Resources\\"
local GIT_TEST = "D:\\BlackMoonExtend\\Client\\GameCode\\Resources\\"
local GIT_ONLINE = "D:\\BlackMoonExtend\\Client\\GameCode\\Resources\\"


local config = {
    trunk = {
        svn = {
            src = SVN_TRUNK .. "src",
            res = SVN_TRUNK .. "res",
            imports = SVN_TRUNK .. "src\\imports",
        },
        git = {
            src = GIT_TRUNK .. "src",
            res = GIT_TRUNK .. "res",
            imports = GIT_TRUNK .. "src\\imports",
        }
    },
    test = {
        svn = {
            src = SVN_TEST .. "src",
            res = SVN_TEST .. "res",
            imports = SVN_TEST .. "src\\imports",
        },
        git = {
            src = GIT_TEST .. "src",
            res = GIT_TEST .. "res",
            imports = GIT_TEST .. "src\\imports",
        }
    },
    online = {
        svn = {
            src = SVN_ONLINE .. "src",
            res = SVN_ONLINE .. "res",
            imports = SVN_ONLINE .. "src\\imports",
        },
        git = {
            src = GIT_ONLINE .. "src",
            res = GIT_ONLINE .. "res",
            imports = GIT_ONLINE .. "src\\imports",
        }
    }
}



return config
