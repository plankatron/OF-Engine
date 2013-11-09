--[[! File: lua/core/network/init.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        See COPYING.txt for licensing information.

    About: Purpose
        OctaForge standard library loader (network code).

        Everything networking related.
]]

local log = require("core.logger")

log.log(log.DEBUG, ":::: Messages.")
require("core.network.msg")
