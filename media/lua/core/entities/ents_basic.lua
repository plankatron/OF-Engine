--[[! File: lua/core/entities/ents_basic.lua

    About: Author
        q66 <quaker66@gmail.com>

    About: Copyright
        Copyright (c) 2013 OctaForge project

    About: License
        This file is licensed under MIT. See COPYING.txt for more information.

    About: Purpose
        Implements a basic entity set. Injects directly into the "ents" module.
]]

local sound = require("core.engine.sound")
local model = require("core.engine.model")
local frame = require("core.events.frame")
local actions = require("core.events.actions")
local signal = require("core.events.signal")
local svars = require("core.entities.svars")
local ents = require("core.entities.ents")
local msg = require("core.network.msg")
local table2 = require("core.lua.table")
local var = require("core.lua.var")
local conv = require("core.lua.conv")

local hextorgb = conv.hex_to_rgb

local var_get = var.get

local bit = require("bit")

local set_external = _C.external_set

local Entity = ents.Entity

local band, bor, bnot, lsh, rsh = bit.band, bit.bor, bit.bnot, bit.lshift, 
    bit.rshift
local assert, unpack, tonumber, tostring = assert, unpack, tonumber, tostring
local connect, emit = signal.connect, signal.emit
local format = string.format
local abs = math.abs
local tconc = table.concat
local min, max = math.min, math.max
local clamp = require("core.lua.math").clamp
local map = table2.map

local set_attachments = _C.set_attachments

-- physics state flags
local MASK_MAT = 0x3
local FLAG_WATER = lsh(1, 0)
local FLAG_LAVA  = lsh(2, 0)
local MASK_LIQUID = 0xC
local FLAG_ABOVELIQUID = lsh(1, 2)
local FLAG_BELOWLIQUID = lsh(2, 2)
local MASK_GROUND = 0x30
local FLAG_ABOVEGROUND = lsh(1, 4)
local FLAG_BELOWGROUND = lsh(2, 4)

--[[! Class: Character
    Represents the base class for any character (NPC, player etc.). Players
    use the <Player> entity class that inherits from this one.
    Inherited property model_name defaults to "player".

    This entity class defines several more properties that do not belong to any
    state variable. These mostly correspond to client_state == <State>.*.
    More will be defined later as needed.

    Non-svar properties:
        ping - the client ping.
        plag - the client plag.
        editing - client_state == EDITING.
        lagged - client_state == LAGGED.

    Properties:
        animation [<svars.State_Array_Integer>] - the entity's current
        animation.
        animation_flags [<svars.State_Integer>] - the entity's current anim
        flags.
        start_time [<svars.State_Integer>] - an internal property used for
        animation timing.
        model_name [<svars.State_String>] - name of the model associated with
        this entity.
        attachments [<svars.State_Array>] - an array of model attachments.
        Those are strings in format "tagname,attachmentname".
        character_name [<svars.State_String>] - name of the character.
        facing_speed [<svars.State_Integer>] - how fast can the character
        change facing (yaw/pitch) in degrees per second. Defaults to 120.
        movement_speed [<svars.State_Float>] - how fast the character can move.
        Defaults to 50.
        yaw [<svars.State_Float>] - the current character yaw in degrees.
        pitch [<svars.State_Float>] - the current character pitch in degrees.
        roll [<svars.State_Float>] - the current character roll in degrees.
        move [<svars.State_Integer>] - -1 when moving backwards, 0 when not
        moving, 1 when forward.
        strafe [<svars.State_Integer>] - -1 when strafing left, 0 when not
        strafing, 1 when right.
        yawing [<svars.State_Integer>] - -1 when turning left, 1 when right,
        0 when not at all.
        pitching [<svars.State_Integer>] - -1 when looking down, 1 when up,
        0 when not.
        crouching [<svars.State_Integer>] - -1 when crouching down, 1 when up,
        0 when not.
        jumping [<svars.State_Boolean>] - true when the character has jumped,
        false otherwise.
        position [<svars.State_Vec3>] - the current position. Defaults to
        { 512, 512, 550 }.
        velocity [<svars.State_Vec3>] - the current velocity.
        falling [<svars.State_Vec3>] - the character's gravity falling.
        radius [<svars.State_Float>] - the character's bounding box radius.
        Defaults to 3.0.
        above_eye [<svars.State_Float>] - the height of the character above
        its eyes. Defaults to 1.0.
        eye_height [<svars.State_Float>] - the distance from the ground to
        the eye position. Defaults to 14.0.
        max_height [<svars.State_Float>] - the maximum distance from the
        ground to the eye position. Defaults to 14.0. Used when crouching.
        crouch_height [<svars.State_Float>] - the fraction from max_height
        to use when crouched, defaults to 0.75.
        crouch_time [<svars.State_Integer>] - the time in milliseconds spent
        to crouch, adjust to change the speed.
        jump_velocity [<svars.State_Float>] - the vertical velocity to apply
        when jumping, defaults to 125.
        gravity [<svars.State_Float>] - a custom character gravity to override
        the global defaults. By default it's -1, which means the character
        will use the global gravity.
        blocked [<svars.State_Boolean>] - true when the character is currently
        blocked from moving. Floor is not considered an obstacle.
        can_move [<svars.State_Boolean>] - when false, the character can't
        move. Defaults to true.
        map_defined_position_data [<svars.State_Integer>] - position protocol
        data specific to the current map, see fpsent (TODO: make unsigned).
        client_state [<svars.State_Integer>] - see <State>.
        physical_state [<svars.State_Integer>] - see <Physical_State>.
        in_liquid [<svars.State_Integer>] - either 0 (in the air) or the
        liquid material id (water, lava).
        time_in_air [<svars.State_Integer>] - time in milliseconds spent in
        the air (TODO: unsigned).
]]
local Character = Entity:clone {
    name = "Character",

    -- so that it isn't nonsauer
    sauer_type = -1,

    --[[! Variable: State
        Defines the "client states". 0 is ALIVE, 1 is DEAD, 2 is SPAWNING,
        3 is LAGGED, 4 is EDITING, 5 is SPECTATOR.
    ]]
    State = {
        ALIVE = 0, DEAD = 1, SPAWNING = 2, LAGGED = 3, EDITING = 4,
        SPECTATOR = 5
    },

    --[[! Variable: Physical_State
        Defines the "physical states". 0 is FLOATING, 1 is FALLING,
        2 is SLIDING, 3 is SLOPING, 4 is ON_FLOOR, 5 is STEPPING_UP,
        6 is STEPPING_DOWN, 7 is BOUNCING.
    ]]
    Physical_State = {
        FLOATING = 0, FALLING = 1, SLIDING = 2, SLOPING = 3,
        ON_FLOOR = 4, STEPPING_UP = 5, STEPPING_DOWN = 6, BOUNCING = 7
    },

    properties = {
        animation = svars.State_Array_Integer {
            setter = function(self, val)
                local pv = val[1] or 0
                local sv = val[2]
                _C.set_animation(self, sv and bor(pv,
                    lsh(sv, model.anims.SECONDARY)) or pv)
            end, client_set = true
        },
        animation_flags = svars.State_Integer {
            setter = "_C.set_animflags", client_set = true
        },
        start_time  = svars.State_Integer { getter = "_C.get_start_time"   },
        model_name  = svars.State_String  { setter = "_C.set_model_name"   },
        attachments = svars.State_Array   {
            setter = function(self, val)
                return set_attachments(self, map(val, function(str)
                    return str:split(",")
                end))
            end
        },

        character_name = svars.State_String(),
        facing_speed   = svars.State_Integer(),

        movement_speed = svars.State_Float {
            getter = "_C.get_maxspeed", setter = "_C.set_maxspeed"
        },
        yaw = svars.State_Float {
            getter = "_C.get_yaw", setter = "_C.set_yaw",
            custom_sync = true
        },
        pitch = svars.State_Float {
            getter = "_C.get_pitch", setter = "_C.set_pitch",
            custom_sync = true
        },
        roll = svars.State_Float {
            getter = "_C.get_roll", setter = "_C.set_roll",
            custom_sync = true
        },
        move = svars.State_Integer {
            getter = "_C.get_move", setter = "_C.set_move",
            custom_sync = true
        },
        strafe = svars.State_Integer {
            getter = "_C.get_strafe", setter = "_C.set_strafe",
            custom_sync = true
        },
        yawing = svars.State_Integer {
            getter = "_C.get_yawing", setter = "_C.set_yawing",
            custom_sync = true
        },
        pitching = svars.State_Integer {
            getter = "_C.get_pitching", setter = "_C.set_pitching",
            custom_sync = true
        },
        crouching = svars.State_Integer {
            getter = "_C.get_crouching", setter = "_C.set_crouching",
            custom_sync = true
        },
        jumping = svars.State_Boolean {
            getter = "_C.get_jumping", setter = "_C.set_jumping",
            custom_sync = true
        },
        position = svars.State_Vec3 {
            getter = "_C.get_dynent_position",
            setter = "_C.set_dynent_position",
            custom_sync = true
        },
        velocity = svars.State_Vec3 {
            getter = "_C.get_dynent_velocity",
            setter = "_C.set_dynent_velocity",
            custom_sync = true
        },
        falling = svars.State_Vec3 {
            getter = "_C.get_dynent_falling",
            setter = "_C.set_dynent_falling",
            custom_sync = true
        },
        radius = svars.State_Float {
            getter = "_C.get_radius", setter = "_C.set_radius"
        },
        above_eye = svars.State_Float {
            getter = "_C.get_aboveeye", setter = "_C.set_aboveeye"
        },
        eye_height = svars.State_Float {
            getter = "_C.get_eyeheight", setter = "_C.set_eyeheight"
        },
        max_height = svars.State_Float {
            getter = "_C.get_maxheight", setter = "_C.set_maxheight"
        },
        crouch_height = svars.State_Float {
            getter = "_C.get_crouchheight", setter = "_C.set_crouchheight"
        },
        crouch_time = svars.State_Integer {
            getter = "_C.get_crouchtime", setter = "_C.set_crouchtime"
        },
        jump_velocity = svars.State_Float {
            getter = "_C.get_jumpvel", setter = "_C.set_jumpvel"
        },
        gravity = svars.State_Float {
            getter = "_C.get_gravity", setter = "_C.set_gravity"
        },
        blocked = svars.State_Boolean {
            getter = "_C.get_blocked", setter = "_C.set_blocked"
        },
        can_move = svars.State_Boolean {
            setter = "_C.set_can_move", client_set = true
        },
        map_defined_position_data = svars.State_Integer {
            getter = "_C.get_mapdefinedposdata",
            setter = "_C.set_mapdefinedposdata",
            custom_sync = true
        },
        client_state = svars.State_Integer {
            getter = "_C.get_clientstate", setter = "_C.set_clientstate",
            custom_sync = true
        },
        physical_state = svars.State_Integer {
            getter = "_C.get_physstate", setter = "_C.set_physstate",
            custom_sync = true
        },
        in_liquid = svars.State_Integer {
            getter = "_C.get_inwater", setter = "_C.set_inwater",
            custom_sync = true
        },
        time_in_air = svars.State_Integer {
            getter = "_C.get_timeinair", setter = "_C.set_timeinair",
            custom_sync = true
        },

        physics_trigger = svars.State_Integer(),

        jumping_sound = svars.State_String(),
        landing_sound = svars.State_String()
    },

    --[[! Function: jump
        A handler called when the character is about to jump. It takes the
        "down" parameter as an argument. By default sets "jumping" to "down".
    ]]
    jump = function(self, down)
        self:set_attr("jumping", down)
    end,

    --[[! Function: crouch
        A handler called when the character is about to crouch. It takes the
        "down" parameter as an argument. By default checks if "down" is true
        and if it is, sets "crouching" to -1, otherwise sets "crouching" to
        abs(crouching).
    ]]
    crouch = function(self, down)
        if down then
            self:set_attr("crouching", -1)
        else
            self:set_attr("crouching", abs(self:get_attr("crouching")))
        end
    end,

    get_plag = _C.get_plag,
    get_ping = _C.get_ping,
    get_editing = function(self) return self:get_attr("client_state") == 4 end,
    get_lagged = function(self) return self:get_attr("client_state") == 3 end,

    init = SERVER and function(self, uid, kwargs)
        Entity.init(self, uid, kwargs)

        self:set_attr("model_name", "")
        self:set_attr("attachments", {})
        self:set_attr("animation", { bor(model.anims.IDLE, model.anims.LOOP) })
        self:set_attr("animation_flags", 0)

        self.cn = kwargs and kwargs.cn or -1
        self:set_attr("character_name", "none")
        self:set_attr("model_name", "player")
        self:set_attr("eye_height", 14.0)
        self:set_attr("max_height", 14.0)
        self:set_attr("crouch_height", 0.75)
        self:set_attr("crouch_time", 150)
        self:set_attr("jump_velocity", 125)
        self:set_attr("gravity", -1)
        self:set_attr("above_eye", 1.0)
        self:set_attr("movement_speed", 50.0)
        self:set_attr("facing_speed", 120)
        self:set_attr("position", { 512, 512, 550 })
        self:set_attr("radius", 3.0)
        self:set_attr("can_move", true)

        self:set_attr("physics_trigger", 0)
        self:set_attr("jumping_sound", "gk/jump2.ogg")
        self:set_attr("landing_sound", "olpc/AdamKeshen/kik.wav")
    end or nil,

    activate = SERVER and function(self, kwargs)
        self.cn = kwargs and kwargs.cn or -1
        assert(self.cn >= 0)
        _C.setup_character(self)

        Entity.activate(self, kwargs)

        self:set_attr("model_name", self:get_attr("model_name"))

        self:flush_queued_svar_changes()
    end or function(self, kwargs)
        Entity.activate(self, kwargs)

        self.cn = kwargs and kwargs.cn or -1
        _C.setup_character(self)

        self.render_args_timestamp = -1

        -- see world.lua for field meanings
        connect(self, "physics_trigger_changed", function(self, val)
            if val == 0 then return nil end
            self:set_attr("physics_trigger", 0)

            local pos = (self ~= ents.get_player())
                and self:get_attr("position") or nil

            local lst = band(val, MASK_LIQUID)
            if lst == FLAG_ABOVELIQUID then
                if band(val, MASK_MAT) ~= FLAG_LAVA then
                    sound.play("yo_frankie/amb_waterdrip_2.wav", pos)
                end
            elseif lst == FLAG_BELOWLIQUID then
                sound.play(band(val, MASK_MAT) == FLAG_LAVA
                    and "yo_frankie/DeathFlash.wav"
                    or "yo_frankie/watersplash2.wav", pos)
            end

            local gst = band(val, MASK_GROUND)
            if gst == FLAG_ABOVEGROUND then
                sound.play(self:get_attr("jumping_sound"), pos)
            elseif gst == FLAG_BELOWGROUND then
                sound.play(self:get_attr("landing_sound"), pos)
            end
        end)
    end,

    deactivate = function(self)
        _C.destroy_character(self)
        Entity.deactivate(self)
    end,

    --[[! Function: render
        Clientside and run per frame. It renders the character model. Decides
        all the parameters, including animation etc., but not every frame -
        they're cached by self.render_args_timestamp (they're only
        recomputed when this timestamp changes).

        When rendering HUD (determined by the paramters hudpass, which
        determines whether we're rendering HUD right now, and needhud,
        which determines whether we're in first person mode), the member
        hud_model_offset (vec3) is used to offset the HUD model (if available).
    ]]
    render = (not SERVER) and function(self, hudpass, needhud)
        if not self.initialized then return nil end
        if not hudpass and needhud then return nil end

        local ra = self.render_args
        local fr = frame.get_frame()
        if self.render_args_timestamp ~= fr then
            local state = self:get_attr("client_state")
            -- spawning or spectator
            if state == 5 or state == 2 then return nil end
            local mdn = (hudpass and needhud)
                and self:get_attr("hud_model_name")
                or  self:get_attr("model_name")

            local yaw, pitch, roll = self:get_attr("yaw"),
                self:get_attr("pitch"),
                self:get_attr("roll")
            local o = self:get_attr("position"):copy()

            if hudpass and needhud and self.hud_model_offset then
                o:add(self.hud_model_offset)
            end

            local pstate = self:get_attr("physical_state")
            local bt, iw = self:get_attr("start_time"),
                self:get_attr("in_liquid")
            local mv, sf = self:get_attr("move"), self:get_attr("strafe")

            local vel, fall = self:get_attr("velocity"):copy(),
                self:get_attr("falling"):copy()
            local tia = self:get_attr("time_in_air")

            local cr = self:get_attr("crouching")

            local anim, animflags = self:decide_animation(state, pstate, mv,
                sf, cr, vel, fall, iw, tia)
            local flags = self:get_render_flags(hudpass, needhud)

            if not ra then
                ra = { self, "", true, true, true, true, true, true, true }
                self.render_args = ra
            end

            ra[2], ra[3], ra[4], ra[5], ra[6], ra[7], ra[8], ra[9], ra[10] =
                mdn, anim, animflags, o, yaw, pitch, roll, flags, bt
            self.render_args_timestamp = fr
        end
        if (ra and ra[2] ~= "") then model.render(unpack(ra)) end
    end or nil,

    --[[! Function: get_render_flags
        Returns the rendering flags used when rendering the character. By
        default, it enables some occlusion stuff. Override as needed,
        the parameters are hudpass (whether we're rendering HUD right now)
        and needhud (whether we're in first person mode). Called from <render>.
        Clientside.
    ]]
    get_render_flags = (not SERVER) and function(self, hudpass, needhud)
        local flags = model.render_flags.FULLBRIGHT
        if self ~= ents.get_player() then
            flags = bor(model.render_flags.CULL_VFC,
                model.render_flags.CULL_OCCLUDED,
                model.render_flags.CULL_QUERY)
        end
        return flags
    end or nil,

    --[[! Function: decide_animation
        Decides the current animation for the character. Starts with
        <get_animation>, then adjusts it to take things like moving,
        strafing, swimming etc into account. Returns the animation
        and animation flags (by default 0).

        Passed arguments are client_state, physical_state, move, strafe,
        crouching, velocity, falling, in_liquid and time_in_air (same as the
        state variables).
    ]]
    decide_animation = (not SERVER) and function(self, state, pstate, move,
    strafe, crouching, vel, falling, inwater, tinair)
        local anim = self:get_attr("animation")
        local pa = anim[1]
        local sa = anim[2]
        if sa then pa = bor(pa, lsh(sa, model.anims.SECONDARY)) end
        anim = pa

        -- editing or spectator
        if state == 4 or state == 5 then
            anim = bor(model.anims.EDIT, model.anims.LOOP)
        -- lagged
        elseif state == 3 then
            anim = bor(model.anims.LAG, model.anims.LOOP)
        else
            -- in water and floating or falling
            if inwater ~= 0 and pstate <= 1 then
                anim = bor(anim, lsh(
                    bor(((move or strafe) or ((vel.z + falling.z) > 0))
                        and model.anims.SWIM or model.anims.SINK,
                    model.anims.LOOP),
                    model.anims.SECONDARY))
            -- jumping animation
            elseif tinair > 250 then
                anim = bor(anim, lsh(bor(model.anims.JUMP, model.anims.END),
                    model.anims.SECONDARY))
            -- moving or strafing
            elseif move ~= 0 or strafe ~= 0 then
                if move > 0 then
                    anim = bor(anim, lsh(bor(model.anims.FORWARD,
                        model.anims.LOOP), model.anims.SECONDARY))
                elseif strafe ~= 0 then
                    anim = bor(anim, lsh(bor((strafe > 0 and model.anims.LEFT
                        or model.anims.RIGHT), model.anims.LOOP),
                        model.anims.SECONDARY))
                elseif move < 0 then
                    anim = bor(anim, lsh(bor(model.anims.BACKWARD,
                        model.anims.LOOP), model.anims.SECONDARY))
                end
            end

            if crouching ~= 0 then
                local v = band(rsh(anim, model.anims.SECONDARY),
                    model.anims.INDEX)
                if v == model.anims.IDLE then
                    anim = band(anim, bnot(lsh(model.anims.INDEX,
                        model.anims.SECONDARY)))
                    anim = bor(anim, lsh(model.anims.CROUCH,
                        model.anims.SECONDARY))
                elseif v == model.anims.JUMP then
                    anim = band(anim, bnot(lsh(model.anims.INDEX,
                        model.anims.SECONDARY)))
                    anim = bor(anim, lsh(model.anims.CROUCH_JUMP,
                        model.anims.SECONDARY))
                elseif v == model.anims.SWIM then
                    anim = band(anim, bnot(lsh(model.anims.INDEX,
                        model.anims.SECONDARY)))
                    anim = bor(anim, lsh(model.anims.CROUCH_SWIM,
                        model.anims.SECONDARY))
                elseif v == model.anims.SINK then
                    anim = band(anim, bnot(lsh(model.anims.INDEX,
                        model.anims.SECONDARY)))
                    anim = bor(anim, lsh(model.anims.CROUCH_SINK,
                        model.anims.SECONDARY))
                elseif v == 0 then
                    anim = bor(anim, lsh(bor(model.anims.CROUCH,
                        model.anims.LOOP), model.anims.SECONDARY))
                elseif v == model.anims.FORWARD or v == model.anims.BACKWARD
                or v == model.anims.LEFT or v == model.anims.RIGHT then
                    anim = anim + lsh((model.anims.CROUCH_FORWARD
                        - model.anims.FORWARD), model.anims.SECONDARY)
                end
            end

            if band(anim, model.anims.INDEX) == model.anims.IDLE and
            band(rsh(anim, model.anims.SECONDARY), model.anims.INDEX) ~= 0 then
                anim = rsh(anim, model.anims.SECONDARY)
            end
        end

        if band(rsh(anim, model.anims.SECONDARY), model.anims.INDEX) == 0 then
            anim = bor(anim, lsh(bor(model.anims.IDLE, model.anims.LOOP),
                model.anims.SECONDARY))
        end
        return anim, 0
    end or nil,

    --[[! Function: get_center
        Gets the center position of a character, something like gravity center
        (approximate). Useful for e.g. bots (better to aim at this position,
        the actual "position" is feet position). Override if you need this
        non-standard. By default it's 0.75 * eye_height above feet.
    ]]
    get_center = function(self)
        local r = self:get_attr("position"):copy()
        r.z = r.z + self:get_attr("eye_height") * 0.75
        return r
    end,

    --[[! Function: get_targeting_origin
        Given an origin position (e.g. from an attachment tag), this method
        is supposed to fix it so that it corresponds to where player actually
        targeted from. By default just returns origin.
    ]]
    get_targeting_origin = function(self, origin)
        return origin
    end,

    --[[! Function: set_local_animation
        Sets the animation property locally, without notifying the other side.
        Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation = function(self, anim)
        local pv = anim[1] or 0
        local sv = anim[2]
        _C.set_animation(self, sv and bor(pv,
            lsh(sv, model.anims.SECONDARY)) or pv)
        self.svar_values["animation"] = anim
    end,

    --[[! Function: set_local_animation_flags
        Sets the animation_flags property locally, without notifying the other
        side. Useful when allowing actions to animate the entity (as we mostly
        don't need the changes to reflect elsewhere).
    ]]
    set_local_animation_flags = function(self, animflags)
        _C.set_animflags(self, animflags)
        self.svar_values["animation_flags"] = animflags
    end,

    --[[! Function: set_local_model_name
        Sets the model name property locally, without notifying the other side.
    ]]
    set_local_model_name = function(self, mname)
        _C.set_model_name(self, mname)
        self.svar_values["model_name"] = mname
    end
}
ents.Character = Character

--[[! Function: physics_collide_client
    An external called when two clients collide. Takes both entities. By
    default emits the "collision" signal on both clients, passing the other
    one as an argument. The client we're testing collisions against gets
    the first emit.
]]
set_external("physics_collide_client", function(cl1, cl2)
    emit(cl1, "collision", cl2)
    emit(cl2, "collision", cl1)
end)

--[[! Class: Player
    The default entity class for player. Inherits from <Character>. Adds
    two new properties.

    Properties:
        can_edit [false] - if player can edit, it's true (private edit mode).
        hud_model_name [""] - the first person model to use for the player.
]]
local Player = Character:clone {
    name = "Player",

    properties = {
        can_edit = svars.State_Boolean(),
        hud_model_name = svars.State_String()
    },

    init = SERVER and function(self, uid, kwargs)
        Character.init(self, uid, kwargs)

        self:set_attr("can_edit", false)
        self:set_attr("hud_model_name", "")
    end or nil
}
ents.Player = Player

ents.register_class(Character)
ents.register_class(Player)

local c_get_attr = _C.get_attr
local c_set_attr = _C.set_attr

local gen_attr = function(i, name)
    i = i - 1
    return svars.State_Integer {
        getter = function(ent)      return c_get_attr(ent, i)      end,
        setter = function(ent, val) return c_set_attr(ent, i, val) end,
        gui_name = name, alt_name = name
    }
end

--[[! Class: Static_Entity
    A base for any static entity. Inherits from <Entity>. Unlike
    dynamic entities (such as <Character>), static entities usually don't
    invoke their "run" method per frame. To re-enable that, set the
    per_frame member to true (false by default for efficiency).

    Static entities are persistent by default, so they set the "persistent"
    inherited property to true.

    This entity class is never registered, the inherited ones are.

    Properties:
        position [<svars.State_Vec3>] - the entity position.
        attr1 [<svars.State_Integer>] - the first "sauer" entity attribute.
        attr2 [<svars.State_Integer>] - the second "sauer" entity attribute.
        attr3 [<svars.State_Integer>] - the third "sauer" entity attribute.
        attr4 [<svars.State_Integer>] - the fourth "sauer" entity attribute.
        attr5 [<svars.State_Integer>] - the fifth "sauer" entity attribute.
]]
local Static_Entity = Entity:clone {
    name = "Static_Entity",

    --[[! Variable: edit_icon
        The icon that'll be displayed in edit mode.
    ]]
    edit_icon = "media/interface/icon/edit_generic",

    per_frame = false,
    sauer_type = 0,
    attr_num   = 0,

    properties = {
        position = svars.State_Vec3 {
            getter = "_C.get_extent_position",
            setter = "_C.set_extent_position"
        }
    },

    init = function(self, uid, kwargs)
        #log(DEBUG, "Static_Entity.init")

        kwargs = kwargs or {}
        kwargs.persistent = true

        Entity.init(self, uid, kwargs)
        if not kwargs.position then
            self:set_attr("position", { 511, 512, 513 })
        else
            self:set_attr("position", {
                tonumber(kwargs.position.x),
                tonumber(kwargs.position.y),
                tonumber(kwargs.position.z)
            })
        end

        #log(DEBUG, "Static_Entity.init complete")
    end,

    activate = SERVER and function(self, kwargs)
        kwargs = kwargs or {}

        #log(DEBUG, "Static_Entity.activate")
        Entity.activate(self, kwargs)

        #log(DEBUG, "Static_Entity: extent setup")
        _C.setup_extent(self, self.sauer_type)

        #log(DEBUG, "Static_Entity: flush")
        self:flush_queued_svar_changes()

        self:set_attr("position", self:get_attr("position"))
        for i = 1, self.attr_num do
            local an = "attr" .. i
            self:set_attr(an, self:get_attr(an))
        end
    end or function(self, kwargs)
        _C.setup_extent(self, self.sauer_type)
        return Entity.activate(self, kwargs)
    end,

    deactivate = function(self)
        _C.destroy_extent(self)
        return Entity.deactivate(self)
    end,

    send_notification_full = SERVER and function(self, cn)
        local acn = msg.ALL_CLIENTS
        cn = cn or acn

        local cns = (cn == acn) and map(ents.get_players(), function(p)
            return p.cn end) or { cn }

        local uid = self.uid
        #log(DEBUG, "Static_Entity.send_notification_full: "
        #    .. cn .. ", " .. uid)

        local scn, sname = self.cn, self.name
        for i = 1, #cns do
            local n = cns[i]
            msg.send(n, _C.extent_notification_complete, uid, sname,
                self:build_sdata({ target_cn = n, compressed = true }))
        end

        #log(DEBUG, "Static_Entity.send_notification_full: done")
    end or nil,

    --[[! Function: get_center
        See <Character.get_center>. By default this is the entity position.
        May be overloaded for other entity types.
    ]]
    get_center = function(self)
        return self:get_attr("position"):copy()
    end,

    --[[! Function: get_edit_color
        Returns the color of the entity icon in edit mode. If an invalid
        value is returned, it defaults to 255, 255, 255 (white). This is
        useful for e.g. light entity that is colored.
    ]]
    get_edit_color = function(self)
        return 255, 255, 255
    end,

    --[[! Function: get_edit_info
        Returns any piece of information displayed in in the edit HUD in
        addition to the entity name. Overload for different entity types.
    ]]
    get_edit_info = function(self)
        return nil
    end,

    --[[! Function: get_attached_entity
        Returns the currently attached entity. Useful mainly for spotlights.
        This refers to the "internally attached" entity that the core engine
        works with.
    ]]
    get_attached_entity = function(self)
        return _C.get_attached_entity(self)
    end,

    --[[! Function: get_edit_drop_height
        Returns the height above the floor to use when dropping the entity
        to the floor. By default returns 4, may be useful to overload (for
        say, mapmodels).
    ]]
    get_edit_drop_height = function(self)
        return 4
    end
}
ents.Static_Entity = Static_Entity

--[[! Function: entity_get_edit_info
    An external. Returns ent.edit_icon, ent:get_edit_color().
]]
set_external("entity_get_edit_icon_info", function(ent)
    return ent.edit_icon, ent:get_edit_color()
end)

--[[! Function: entity_get_edit_info
    An external. Returns the entity name and the return value of
    <Static_Entity.get_edit_info>.
]]
set_external("entity_get_edit_info", function(ent)
    return ent.name, ent:get_edit_info()
end)

--[[! Function: entity_get_edit_drop_height
    An external, see <Entity.get_edit_drop_height>.
]]
set_external("entity_get_edit_drop_height", function(ent)
    return ent:get_edit_drop_height()
end)

--[[! Class: Marker
    A generic marker without orientation. It doesn't have any default
    additional properties.
]]
local Marker = Static_Entity:clone {
    name = "Marker",

    edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 1,

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
    end
}
ents.Marker = Marker

--[[! Class: Oriented_Marker
    A generic (oriented) marker with a wide variety of uses. Can be used as
    a base for various position markers (e.g. playerstarts). It has two
    properties, attr1 alias yaw, attr2 alias pitch.

    An example of world marker usage is a cutscene system. Different marker
    types inherited from this one can represent different nodes.
]]
local Oriented_Marker = Static_Entity:clone {
    name = "Oriented_Marker",

    edit_icon = "media/interface/icon/edit_marker",

    sauer_type = 2,
    attr_num   = 2,

    properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch")
    },

    --[[! Function: place_entity
        Places an entity on this marker's position.
    ]]
    place_entity = function(self, ent)
        ent:set_attr("position", self:get_attr("position"))
        ent:set_attr("yaw", self:get_attr("yaw"))
        ent:set_attr("pitch", self:get_attr("pitch"))
    end,

    get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d", self:get_attr("yaw"),
            self:get_attr("pitch"))
    end
}
ents.Oriented_Marker = Oriented_Marker

local lightflags = setmetatable({
    [0] = "dynamic (0)",
    [1] = "none (1)",
    [2] = "static (2)"
}, {
    __index = function(self, i)
        return ("invalid (%d)"):format(i)
    end
})

--[[! Class: Light
    A regular point light. In the extension library there are special light
    entity types that are e.g. triggered, flickering and so on.

    Properties:
        attr1 - light radius. (0 to N, alias "radius", default 100 - 0 or
        lower means the light is off)
        attr2 - red value (can be any range, even negative - typical values
        are 0 to 255, negative values make a negative light, alias "red",
        default 128)
        attr3 - green value (alias "green", default 128)
        attr4 - blue value (alias "blue", default 128)
        attr5 - shadow type, 0 means dnyamic, 1 disabled, 2 static (default 0).
]]
local Light = Static_Entity:clone {
    name = "Light",

    edit_icon = "media/interface/icon/edit_light",

    sauer_type = 3,
    attr_num   = 5,

    properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "red"),
        attr3 = gen_attr(3, "green"),
        attr4 = gen_attr(4, "blue"),
        attr5 = gen_attr(5, "shadow")
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("red", 128)
        self:set_attr("green", 128)
        self:set_attr("blue", 128)
        self:set_attr("radius", 100)
        self:set_attr("shadow", 0)
    end,

    get_edit_color = function(self)
        return self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue")
    end,

    get_edit_info = function(self)
        return format("red :\f2 %d \f7| green :\f2 %d \f7| blue :\f2 %d\n\f7"
            .. "radius :\f2 %d \f7| shadow :\f2 %s",
            self:get_attr("red"), self:get_attr("green"),
            self:get_attr("blue"), self:get_attr("radius"),
            lightflags[self:get_attr("shadow")])
    end
}
ents.Light = Light

--[[! Class: Spot_Light
    A spot light. It's attached to the nearest <Light>. It has just one
    property, attr1 (alias "radius") which defaults to 90 and is in degrees
    (90 is a full hemisphere, 0 is a line).

    Properties such as color are inherited from the attached light entity.
]]
local Spot_Light = Static_Entity:clone {
    name = "Spot_Light",

    edit_icon = "media/interface/icon/edit_spotlight",

    sauer_type = 4,
    attr_num   = 1,

    properties = {
        attr1 = gen_attr(1, "radius")
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("radius", 90)
    end,

    get_edit_color = function(self)
        local ent = self:get_attached_entity()
        if not ent then return 255, 255, 255 end
        return ent:get_attr("red"), ent:get_attr("green"), ent:get_attr("blue")
    end,

    get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}
ents.Spot_Light = Spot_Light

--[[! Class: Envmap
    An environment map entity class. Things reflecting on their surface using
    environment maps can generate their envmap from the nearest envmap entity
    instead of using skybox and reflect geometry that way (statically).

    It has one property, radius, which specifies the distance it'll still
    have effect in.
]]
local Envmap = Static_Entity:clone {
    name = "Envmap",

    edit_icon = "media/interface/icon/edit_envmap",

    sauer_type = 5,
    attr_num   = 1,

    properties = {
        attr1 = gen_attr(1, "radius")
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("radius", 128)
    end,

    get_edit_info = function(self)
        return format("radius :\f2 %d", self:get_attr("radius"))
    end
}
ents.Envmap = Envmap

--[[! Class: Sound
    An ambient sound in the world. Repeats the given sound at entity position.

    Properties:
        attr1 - the sound radius (alias "radius", default 100)
        attr2 - the sound size, if this is 0, the sound is a point source,
        otherwise the sound volume will always be max until the distance
        specified by this property and then it'll start fading off
        (alias "size", default 0).
        attr3 - the sound volume, from 0 to 100 (alias "volume", default 100).
        sound_name [<svars.State_String>] - the  path to the sound in
        media/sound (default "").
]]
local Sound = Static_Entity:clone {
    name = "Sound",

    edit_icon = "media/interface/icon/edit_sound",

    sauer_type = 6,
    attr_num   = 3,

    properties = {
        attr1 = gen_attr(1, "radius"),
        attr2 = gen_attr(2, "size"),
        attr3 = gen_attr(3, "volume"),
        sound_name = svars.State_String()
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("radius", 100)
        self:set_attr("size", 0)
        self:set_attr("volume", 100)
        self:set_attr("sound_name", "")
    end,

    activate = (not SERVER) and function(self, ...)
        Static_Entity.activate(self, ...)
        local f = _C.sound_stop_map
        connect(self, "sound_name_changed", f)
        connect(self, "radius_changed", f)
        connect(self, "size_changed", f)
        connect(self, "volume_changed", f)
    end or nil,

    get_edit_info = function(self)
        return format("radius :\f2 %d \f7| size :\f2 %d \f7| volume :\f2 %d"
            .. "\n\f7name :\f2 %s",
            self:get_attr("radius"), self:get_attr("size"),
            self:get_attr("volume"), self:get_attr("sound_name"))
    end,

    play_sound = function(self)
        _C.sound_play_map(self, self:get_attr("sound_name"),
            self:get_attr("volume"))
    end
}
ents.Sound = Sound

set_external("sound_play_map", function(ent)
    ent:play_sound()
end)

local PART_TEXT = 0
local PART_ICON = 1
local PART_METER = 2
local PART_METER_VS = 3
local PART_BLOOD = 4
local PART_WATER = 5
local PART_SMOKE = 6
local PART_STEAM = 7
local PART_FLAME = 8
local PART_FIREBALL1 = 9
local PART_FIREBALL2 = 10
local PART_FIREBALL3 = 11
local PART_STREAK = 12
local PART_LIGHTNING = 13
local PART_EXPLOSION = 14
local PART_EXPLOSION_BLUE = 15
local PART_SPARK = 16
local PART_SNOW = 17
local PART_MUZZLE_FLASH1 = 18
local PART_MUZZLE_FLASH2 = 19
local PART_MUZZLE_FLASH3 = 20
local PART_LENS_FLARE = 21

local typemap = { PART_STREAK, -1, -1, PART_LIGHTNING, -1, PART_STEAM,
    PART_WATER, -1, -1, PART_SNOW }
local sizemap = { 0.28, 0, 0, 1, 0, 2.4, 0.6, 0, 0, 0.5 }
local gravmap = { 0, 0, 0, 0, 0, -20, 2, 0, 0, 20 }

local part_draw_1 = function(pt, x, y, z, a1, a2, a3, a4)
    local tp = typemap[pt - 3]
    local sz = sizemap[pt - 3]
    local gv = gravmap[pt - 3]
    local r, g, b = hextorgb(a3)
    if a1 >= 256 then
        _C.particle_shape(tp, x, y, z, max(1 + a2, 1), a1 - 256, 5, r / 255,
            g / 255, b / 255, a4 > 0 and min(a4, 10000) or 200, sz, gv, 200)
    else
        local dx, dy, dz = _C.particle_offset_vec(x, y, z, a1, max(1 + a2, 0))
        _C.particle_new(tp, x, y, z, dx, dy, dz, r / 255, g / 255, b / 255,
            1, sz, gv)
    end
end

local part_draw_2 = function(pt, x, y, z, a1, a2, a3, a4)
    local r, g, b = hextorgb(a2)
    local r2, g2, b2 = hextorgb(a3)
    _C.particle_meter(pt == 5 and PART_METER or PART_METER_VS, x, y, z,
        a1 / 100, r / 255, g / 255, b / 255, r2 / 255,
        g2 / 255, b2 / 255, 1, 2)
end

local part_draw_3 = function(pt, x, y, z, a1, a2, a3, a4)
    local r, g, b = hextorgb(a1)
    _C.particle_lensflare(PART_LENS_FLARE, x, y, z,
        band(pt, 0x02) ~= 0, band(pt, 0x01) ~= 0, r / 255, g / 255, b / 255)
end

local part_draw_default = function(pt, x, y, z, a1, a2, a3, a4)
    if var_get("editing") == 0 then
        _C.particle_text(PART_TEXT, x, y, z, ("particles %d?"):format(pt),
            0x64 / 255, 0x96 / 255, 0xFF / 255, 1, 2, 0)
    end
end

local rand = math.random

local part_draw_tbl = setmetatable({
    -- fire and smoke - radius, height, rgb
    [0] = function(pt, x, y, z, a1, a2, a3, a4)
        local radius = a1 ~= 0 and a1 / 100 or 1.5
        local height = a2 ~= 0 and a2 / 100 or 0.5
        local r, g, b = hextorgb(a3 ~= 0 and a3 or 0x903020)
        _C.particle_flame(PART_FLAME, x, y, z, radius, height, 3,
            r / 255, g / 255, b / 255, 600, 2, 200, -15)
        _C.particle_flame(PART_SMOKE, x, y, z + 4 * min(radius, height),
            radius, height, 1, 0x30 / 255, 0x30 / 255, 0x20 / 255,
            2000, 4, 100, -20)
    end,
    -- steam vent - dir
    [1] = function(pt, x, y, z, a1, a2, a3, a4)
        x, y, z = _C.particle_offset_vec(x, y, z, a1, rand(9))
        _C.particle_splash(PART_STEAM, x, y, z, 50, 1, 0x89 / 255, 0x76 / 255,
            0x61 / 255, 200, 2.4, -20, 0)
    end,
    -- water fountain - dir
    [2] = function(pt, x, y, z, a1, a2, a3, a4)
        local color
        if a2 > 0 then color = a2
        elseif a2 == 0 then
            color = var_get("waterfallcolor")
            if color == 0 then color = var_get("watercolor") end
        else
            local mat = clamp(-a2, 2, 4)
            color = var_get("water" .. mat .. "fallcolor")
            if color == 0 then color = var_get("water" .. mat .. "color") end
        end
        x, y, z = _C.particle_offset_vec(x, y, z, a1, rand(9))
        local r, g, b = hextorgb(color)
        _C.particle_splash(PART_WATER, x, y, z, 150, 4, r / 255, g / 255,
            b / 255, 200, 0.6, 2, 0)
    end,
    -- fireball - size, rgb
    [3] = function(pt, x, y, z, a1, a2, a3, a4)
        local r, g, b = hextorgb(a2)
        _C.particle_new(PART_EXPLOSION, x, y, z, 0, 0, 1, r / 255, g / 255,
            b / 255, 1, 4, 0):set_val(1 + a1)
    end,
    [4] = part_draw_1, -- tape - dir, length, rgb
    [7] = part_draw_1, -- lightning
    [9] = part_draw_1, -- steam
    [10] = part_draw_1, -- water
    [13] = part_draw_1, -- snow
    [5] = part_draw_2, -- meter - percent, rgb, rgb2
    [6] = part_draw_2, -- metervs
    -- flame - radius, height, rgb
    [11] = function(pt, x, y, z, a1, a2, a3, a4)
        local r, g, b = hextorgb(a3)
        _C.particle_flame(PART_FLAME, x, y, z, a1 / 100, a2 / 100, 3,
            r / 255, g / 255, b / 255, 600, 2, 200, -15)
    end,
    -- smoke plume - radius, height, rgb
    [12] = function(pt, x, y, z, a1, a2, a3, a4)
        local r, g, b = hextorgb(a3)
        _C.particle_flame(PART_SMOKE, x, y, z, a1 / 100, a2 / 100, 1,
            r / 255, g / 255, b / 255, 2000, 4, 100, -20)
    end,
    [32] = part_draw_3,
    [33] = part_draw_3,
    [34] = part_draw_3,
    [35] = part_draw_3
}, {
    __index = function() return part_draw_default end
})

--[[! Class: Particle_Effect
    A particle effect entity class. You can derive from this to create
    your own effects.

    Particle types (and their values):

    0 (fire with smoke):
        radius - 0 is default, that equals 100.
        height - 0 is default, that equals 100.
        rgb - 0x000000 is default, that equals 0x903020.

    1 (steam vent):
        direction - 0 to 5.

    2 (water fountain):
        direction - 0 to 5, its color inherits from the water color.

    3 (explosion / fireball):
        size - 0 to 40.
        rgb - 0x000000 to 0xFFFFFF.

    4 (streak / flare):
        direction - 0 to 5.
        length - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    4 (multiple streaks / flares):
       direction - 256 + effect.
       length - 0 to 100.
       rgb - 0x000000 to 0xFFFFFF.

    4 effects:
        0 to 2 - circular.
        3 to 5 - cylinderical shell.
        6 to 11 - conic shell.
        12 to 14 - cubic volume.
        15 to 20 - planar surface.
        21 - sphere.

    5 (capture meter, rgb vs black):
        percentage - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    6 (vs capture meter, rgb vs bgr):
        percentage - 0 to 100.
        rgb - 0x000000 to 0xFFFFFF.

    7 (lightning):
        direction, length, rgb - see 4.

    9 (steam):
        direction, length, rgb - see 4.

    10 (water):
        direction, length, rgb - see 4.

    11 (flames):
        radius, height, rgb, see 0.

    12 (smoke plume):
        radius, height, rgb, see 0.

    32 (plain lens flare):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    33 (lens flare with sparkle center):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    34 (sun lens flare, i.e. fixed size regardless of distance):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.

    35 (sun lens flare with sparkle center):
        red - 0 to 255.
        green - 0 to 255.
        blue - 0 to 255.
]]
local Particle_Effect = Static_Entity:clone {
    name = "Particle_Effect",

    edit_icon  = "media/interface/icon/edit_particles",
    sauer_type = 7,

    properties = {
        particle_type = svars.State_Integer(),
        a = svars.State_Integer(),
        b = svars.State_Integer(),
        c = svars.State_Integer(),
        d = svars.State_Integer()
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("particle_type", 0)
        self:set_attr("a", 0)
        self:set_attr("b", 0)
        self:set_attr("c", 0)
        self:set_attr("d", 0)
    end,

    get_edit_info = function(self)
        local pt = self:get_attr("particle_type")
        if pt == 0 or pt == 4 or pt == 7 or pt == 8 or pt == 9 or pt == 10
        or pt == 11 or pt == 12 or pt == 13 then
            return format("pt :\f2 %d \f7| a :\f2 %d \f7| b :\f2 %d \f7|"
                .. " c :\f2 0x%.6X \f7| d :\f2 %d", pt,
                self:get_attr("a"), self:get_attr("b"), self:get_attr("c"),
                self:get_attr("d"))
        elseif pt == 3 then
            return format("pt :\f2 %d \f7| a :\f2 %d \f7| b :\f2 0x%.6X \f7|"
                .. " c :\f2 %d \f7| d :\f2 %d", pt,
                self:get_attr("a"), self:get_attr("b"), self:get_attr("c"),
                self:get_attr("d"))
        elseif pt == 5 or pt == 6 then
            return format("pt :\f2 %d \f7| a :\f2 %d \f7| b :\f2 0x%.6X \f7|"
                .. " c :\f2 0x%.6X \f7| d :\f2 %d", pt,
                self:get_attr("a"), self:get_attr("b"), self:get_attr("c"),
                self:get_attr("d"))
        end
    end,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end,

    --[[! Function: emit_particles
        A particle emitter entry point. Overload as needed.
    ]]
    emit_particles = function(self)
        local attr1 = self:get_attr("particle_type")
        local attr2 = self:get_attr("a")
        local attr3 = self:get_attr("b")
        local attr4 = self:get_attr("c")
        local attr5 = self:get_attr("d")
        local pos = self:get_attr("position")
        part_draw_tbl[attr1](attr1, pos.x, pos.y, pos.z,
            attr2, attr3, attr4, attr5)
    end
}
ents.Particle_Effect = Particle_Effect

set_external("particle_entity_emit", function(e)
    e:emit_particles()
end)

--[[! Class: Mapmodel
    A model in the world. All attrs default to 0. On mapmodels and all
    entity types derived from mapmodels, the engine emits the "collision"
    signal with the collider entity passed as an argument when collided.

    Properties:
        animation [<svars.State_Array_Integer>] - the mapmodel's current
        animation.
        animation_flags [<svars.State_Integer>] - the mapmodel's current anim
        flags.
        start_time [<svars.State_Integer>] - an internal property used for
        animation timing.
        model_name [<svars.State_String>] - name of the model associated with
        this mapmodel.
        attachments [<svars.State_Array>] - an array of model attachments.
        Those are strings in format "tagname,attachmentname".
        attr1 - the model yaw, alias "yaw".
        attr2 - the model pitch, alias "pitch".
        attr3 - the model roll, alias "roll".
        attr4 - the model scale, alias "scale".
]]
local Mapmodel = Static_Entity:clone {
    name = "Mapmodel",

    edit_icon = "media/interface/icon/edit_mapmodel",

    sauer_type = 8,
    attr_num   = 4,

    properties = {
        animation = svars.State_Array_Integer {
            setter = function(self, val)
                local pv = val[1] or 0
                local sv = val[2]
                _C.set_animation(self, sv and bor(pv,
                    lsh(sv, model.anims.SECONDARY)) or pv)
            end, client_set = true
        },
        animation_flags = svars.State_Integer {
            setter = "_C.set_animflags", client_set = true
        },
        start_time  = svars.State_Integer { getter = "_C.get_start_time"   },
        model_name  = svars.State_String  { setter = "_C.set_model_name"   },
        attachments = svars.State_Array   {
            setter = function(self, val)
                return set_attachments(self, map(val, function(str)
                    return str:split(",")
                end))
            end
        },

        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "scale")
    },

    init = SERVER and function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)

        self:set_attr("model_name", "")
        self:set_attr("attachments", {})
        self:set_attr("animation", { bor(model.anims.IDLE, model.anims.LOOP) })
        self:set_attr("animation_flags", 0)
    end or nil,

    activate = SERVER and function(self, kwargs)
        Static_Entity.activate(self, kwargs)
        self:set_attr("model_name", self:get_attr("model_name"))
    end or nil,

    get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d \f7|"
            .. " scale :\f2 %d\n\f7name :\f2 %s",
            self:get_attr("yaw"), self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("scale"),
            self:get_attr("model_name"))
    end,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end,

    --[[! Function: set_local_animation
        See <Character.set_local_animation>.
    ]]
    set_local_animation = Character.set_local_animation,

    --[[! Function: set_local_animation_flags
        See <Character.set_local_animation_flags>.
    ]]
    set_local_animation_flags = Character.set_local_animation_flags,

    --[[! Function: set_local_model_name
        See <Character.set_local_model_name>.
    ]]
    set_local_model_name = Character.set_local_model_name
}
ents.Mapmodel = Mapmodel

--[[! Function: physics_collide_mapmodel
    An external called when a client collides with a mapmodel. Takes the
    collider entity (the client) and the mapmodel entity. By default emits
    the "collision" signal on both entities, passing the other one as an
    argument. The mapmodel takes precedence.
]]
set_external("physics_collide_mapmodel", function(collider, entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

--[[! Class: Obstacle
    An entity class that emits a "collision" signal on itself when a client
    (player, NPC...) collides with it. It has its own yaw (attr1), dimensions
    (attr2 alias a, attr3 alias b, attr4 alias c) and the solid property
    (attr5) which makes the obstacle solid when it isn't 0.
]]
local Obstacle = Static_Entity:clone {
    name = "Obstacle",

    sauer_type = 9,
    attr_num   = 7,

    properties = {
        attr1 = gen_attr(1, "yaw"),
        attr2 = gen_attr(2, "pitch"),
        attr3 = gen_attr(3, "roll"),
        attr4 = gen_attr(4, "a"),
        attr5 = gen_attr(5, "b"),
        attr6 = gen_attr(6, "c"),
        attr7 = gen_attr(7, "solid")
    },

    init = function(self, uid, kwargs)
        Static_Entity.init(self, uid, kwargs)
        self:set_attr("yaw", 0)
        self:set_attr("pitch", 0)
        self:set_attr("roll", 0)
        self:set_attr("a", 10)
        self:set_attr("b", 10)
        self:set_attr("c", 10)
        self:set_attr("solid", 0)
    end,

    get_edit_info = function(self)
        return format("yaw :\f2 %d \f7| pitch :\f2 %d \f7| roll :\f2 %d\n\f7"
            .. "a :\f2 %d \f7| b :\f2 %d \f7| c :\f2 %d \f7| solid :\f2 %d",
            self:get_attr("yaw"),  self:get_attr("pitch"),
            self:get_attr("roll"), self:get_attr("a"),
            self:get_attr("b"),    self:get_attr("c"), self:get_attr("solid"))
    end,

    --[[! Function: get_edit_drop_height
        Returns 0.
    ]]
    get_edit_drop_height = function(self)
        return 0
    end
}
ents.Obstacle = Obstacle

--[[! Function: physics_collide_area
    An external called when a client collides with an area. Takes the
    collider entity (the client) and the area entity.  By default emits
    the "collision" signal on both entities, passing the other one as an
    argument. The obstacle takes precedence.
]]
set_external("physics_collide_area", function(collider, entity)
    emit(entity, "collision", collider)
    emit(collider, "collision", entity)
end)

ents.register_class(Marker)
ents.register_class(Oriented_Marker)
ents.register_class(Light)
ents.register_class(Spot_Light)
ents.register_class(Envmap)
ents.register_class(Sound)
ents.register_class(Particle_Effect)
ents.register_class(Mapmodel)
ents.register_class(Obstacle)
