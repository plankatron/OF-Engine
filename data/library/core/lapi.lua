return {
    Math = {
        make_vec3 = function(x, y, z)
            return math.Vec3(x, y, z)
        end,
        make_vec4 = function(x, y, z, w)
            return math.Vec4(x, y, z, w)
        end
    },
    Input = {
        Events = {
            Client = {
                mouse_move = function(yaw, pitch)
                    if not do_mousemove then
                        return { yaw = yaw, pitch = pitch }
                    end

                    return do_mousemove(yaw, pitch)
                end,
                click = function(num, down, pos, ent, x, y)
                    if client_click then
                        return client_click(num, down, pos, ent, x, y)
                    end

                    if ent and ent.client_click then
                        return ent:client_click(num, down, pos, x, y)
                    end
                end,
                yaw = function(dir, down)
                    if do_yaw then
                        return do_yaw(dir, down)
                    end
                    ents.get_player().yawing = dir
                end,
                pitch = function(dir, down)
                    if do_pitch then
                        return do_pitch(dir, down)
                    end
                    ents.get_player().pitching = dir
                end,
                move = function(dir, down)
                    if do_movement then
                        return do_movement(dir, down)
                    end
                    ents.get_player().move = dir
                end,
                strafe = function(dir, down)
                    if do_strafe then
                        return do_strafe(dir, down)
                    end
                    ents.get_player().strafe = dir
                end,
                jump = function(down)
                    if do_jump then
                        return do_jump(down)
                    end
                    if down then
                        ents.get_player():jump()
                    end
                end
            },
            Server = {
                click = function(num, down, pos, ent)
                    if click then
                        return click(num, down, pos, ent)
                    end

                    if ent and ent.click then
                        ent:click(num, down, pos)
                    end
                end
            }
        },
        get_local_bind = function(name)
            return input.per_map_keys[name]
        end
    },
    World = {
        Events = {
            Client = {
                off_map = function(ent)
                    if not client_on_ent_offmap then
                        return nil
                    end

                    return client_on_ent_offmap(ent)
                end
            },
            Server = {
                off_map = function(ent)
                    if not on_ent_offmap then
                        return nil
                    end

                    return on_ent_offmap(ent)
                end,
                player_login = function(ent)
                end
            },
            text_message = function(uid, text)
                if handle_textmsg then
                    return handle_textmsg(uid, text)
                end

                return false
            end
        },
        Entity = {
            Properties = {
                position     = "position",
                id           = "uid",
                cn           = "cn",
                facing_speed = "facing_speed",
                can_edit     = "can_edit",
                name         = "_name",
                collision_w  = "collision_radius_width",
                collision_h  = "collision_radius_height",
                initialized  = "initialized",
                rendering_hash_hint = "rendering_hash_hint"
            },
            create_state_data_dict = function(ent)
                return ent:build_sdata()
            end,
            add_sauer = ents.add_sauer,
            clear_actions = function(ent)
                return ent.action_system:clear()
            end,
            set_state_data = ents.set_sdata,
            make_player    = ents.init_player,
            update_complete_state_data = function(ent, sd)
                return  ent:set_sdata_full(sd)
            end,
            set_local_animation = function(ent, anim)
                return ent:set_local_animation (anim)
            end
        },
        Entities = {
            Classes = {
                get            = ents.get_class,
                get_sauer_type = function(cn)
                    return ents.get_class(cn).sauer_type
                end
            },
            add        = ents.add,
            new        = ents.new,
            delete     = ents.remove,
            delete_all = ents.remove_all,
            save_all   = ents.save,
            get        = ents.get,
            get_all    = ents.get_all,
            send       = ents.send,
            gen_id     = ents.gen_uid,
            render     = ents.render
        },
        scenario_started  = ents.scene_is_ready,
        render_hud        = ents.render_hud,
        manage_collisions = ents.handle_triggers,
        handle_frame      = frame.handle_frame,
        start_frame       = frame.start_frame
    },
    Table = {
        serialize   = table.serialize,
        deserialize = table.deserialize
    },
    Library = {
        is_unresettable = function(name)
            return false
        end,
        reset = library.reset
    }
}
