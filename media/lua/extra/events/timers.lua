--[[!<
    Timer objects for general use.

    Author:
        q66 <quaker66@gmail.com>

    License:
        See COPYING.txt.
]]

--! Module: timers
local M = {}

--[[! Object: timers.Timer
    A general use timer. It's not automatically managed - you have to simulate
    it yourself using the provided methods. That makes it flexible for various
    scenarios (where the timing is not managed by the general event loop).
]]
M.Timer = require("core.lua.table").Object:clone {
    name = "Timer",

    --[[!
        A timer constructor.

        Arguments:
            - interval - time in milliseconds the timer should take until
              the next repeated action.
            - carry_over - a boolean specifying whether to carry potential
              extra time to next iteration (if you $tick with a too large
              value, the sum will be larger than the interval), defaults
              to false.
    ]]
    __ctor = function(self, interval, carry_over)
        self.interval   = interval
        self.carry_over = carry_over or false
        self.sum        = 0
    end,

    --[[!
        Performs one timer tick.

        Arguments:
            - millis - the value in milliseconds to add to the internal sum.
              If this is larger than the interval, sum is reset to either zero
              or "sum - interval" (if carry_over is true).

        Returns:
            True if the interval was reached, false otherwise.
    ]]
    tick = function(self, millis)
        local sum = self.sum + millis
        local interval = self.interval
        if sum >= interval then
            self.sum = self.carry_over and (sum - interval) or 0
            return true
        else
            self.sum = sum
            return false
        end
    end,

    --! Manually sets sum to interval.
    prime = function(self)
        self.sum = self.interval
    end
}

return M
