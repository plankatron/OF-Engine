--[[!<
    Sound related functions. Relevant only clientside.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

if SERVER then return {} end

local capi = require("capi")

local play = capi.sound_play
local vec3 = require("core.lua.geom").Vec3

--! Module: sound
return {
    --[[!
        Plays a sound.

        Arguments:
            - name - the sound name.
            - pos - the sound position (a value with x, y, z, defaults to
              0, 0, 0).
            - vol - an optional volume that defaults to 100.
    ]]
    play = function(name, pos, vol)
        if not name then return end
        pos = pos or vec3(0)
        play(name, pos.x, pos.y, pos.z, vol or 100)
    end,

    --[[!
        Stops a sound.

        Arguments:
            - name - the sound name.
            - vol - an optional volume that defaults to 100.
    ]]
    stop = function(name, vol) capi.sound_stop(name, vol or 100) end,

    --[[! Function: preload_map
        Preloads a map sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.

        Arguments:
            - name - the sound name.
            - vol - an optional volume that defaults to 100.

        See also:
            - $preload_game
    ]]
    preload_map = function(name, vol)
        return capi.sound_preload_map(name, vol or 100)
    end,

    --[[! Function: preload_game
        Preloads a game sound so that it doesn't have to be loaded on the fly
        later. That leads to better performance.

        Arguments:
            - name - the sound name.
            - vol - an optional volume that defaults to 100.

        See also:
            - $preload_map
    ]]
    preload_game = function(name, vol)
        return capi.sound_preload_game(name, vol or 100)
    end
}
