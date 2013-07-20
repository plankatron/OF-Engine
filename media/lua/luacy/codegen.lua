--[[ Luacy 0.1 codegen

    Author: Daniel "q66" Kolesa <quaker66@gmail.com>
    Available under the terms of the MIT license.
]]

local tconc = table.concat
local space = " "
local tinsert = table.insert

local init = function(ls, debug)
    return {
        ls = ls,
        buffer    = {},
        saved     = {},
        debug     = debug,
        enabled   = true,
        last_line = 1,
        append = function(cs, str, idkw, saved)
            local sbuf = cs.saved
            local apos
            if saved == true then
                apos = (sbuf[#sbuf] or 0) + 1
            elseif saved then
                apos = saved + 1
            end

            local linenum = cs.ls.line_number
            local lastln  = cs.last_line
            local buffer  = cs.buffer
            if (linenum - lastln) > 0 then
                buffer[#buffer + 1] = ("\n"):rep(linenum - lastln)
                cs.last_line = linenum
                lastln = linenum
            end

            if not cs.enabled then return nil end
            if idkw then
                if cs.was_idkw == lastln then
                    buffer[#buffer + 1] = space
                else
                    cs.was_idkw = lastln
                end
            elseif not saved then
                cs.was_idkw = nil
            end
            if apos then
                tinsert(buffer, apos, str)
            else
                buffer[#buffer + 1] = str
            end
            cs.last_append = #buffer
        end,
        save = function(cs)
            tinsert(cs.saved, #cs.buffer)
        end,
        unsave = function(cs)
            cs.saved[#cs.saved] = nil
        end,
        offset_saved = function(cs, off)
            local sbuf = cs.saved
            for i = 1, #sbuf do sbuf[i] = sbuf[i] + off end
        end,
        build = function(cs)
            return tconc(cs.buffer)
        end
    }
end

return { init = init }