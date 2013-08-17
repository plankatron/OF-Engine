
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "network_system.h"

#ifndef SERVER
    #include "client_system.h"
#endif

#include "message_system.h"
#include "of_tools.h"
#include "of_world.h"


// Enable to let *server* do physics for players - useful for debugging. Must also be defined in client.cpp!
#define SERVER_DRIVEN_PLAYERS 0

namespace game
{
    VAR(useminimap, 0, 0, 1); // do we want the minimap? Set from JS.

    int gamemode = 0;

    int following = -1, followdir = 0;

    fpsent *player1 = NULL;         // our client
    vector<fpsent *> players;       // other clients
    fpsent lastplayerstate;

    void follow(char *arg)
    {
        if(arg[0] ? player1->state==CS_SPECTATOR : following>=0)
        {
            following = arg[0] ? parseplayer(arg) : -1;
            if(following==player1->clientnum) following = -1;
            followdir = 0;
            conoutf("follow %s", following>=0 ? "on" : "off");
        }
    }

    void nextfollow(int dir)
    {
        if(player1->state!=CS_SPECTATOR || players.empty())
        {
            stopfollowing();
            return;
        }
        int cur = following >= 0 ? following : (dir < 0 ? players.length() - 1 : 0);
        loopv(players)
        {
            cur = (cur + dir + players.length()) % players.length();
            if(players[cur])
            {
                if(following<0) conoutf("follow on");
                following = cur;
                followdir = dir;
                return;
            }
        }
        stopfollowing();
    }

    static string clientmap = "";
    const char *getclientmap()
    {
        if (!world::curr_map_id[0]) return clientmap;
        string buf;
        copystring(buf, world::curr_map_id);
        buf[strlen(world::curr_map_id) - 7] = '\0';
        formatstring(clientmap, "%s/map", buf);
        return clientmap;
    }

    fpsent *spawnstate(fpsent *d)              // reset player state not persistent accross spawns
    {
        d->respawn();
        return d;
    }

    void stopfollowing()
    {
        if(following<0) return;
        following = -1;
        followdir = 0;
        conoutf("follow off");
    }

    fpsent *followingplayer()
    {
        if(player1->state!=CS_SPECTATOR || following<0) return NULL;
        fpsent *target = getclient(following);
        if(target && target->state!=CS_SPECTATOR) return target;
        return NULL;
    }

    fpsent *hudplayer()
    {
        if(thirdperson) return player1;
        fpsent *target = followingplayer();
        return target ? target : player1;
    }

    void setupcamera()
    {
        fpsent *target = followingplayer();
        if(target)
        {
            player1->yaw = target->yaw;    // Kripken: needed?
            player1->pitch = target->state==CS_DEAD ? 0 : target->pitch; // Kripken: needed?
            player1->o = target->o;
            player1->resetinterp();
        }
    }

    bool detachcamera()
    {
        fpsent *d = hudplayer();
        return d->state==CS_DEAD;
    }

    bool collidecamera()
    {
        switch(player1->state)
        {
            case CS_EDITING: return false;
            case CS_SPECTATOR: return followingplayer()!=NULL;
        }
        return true;
    }

    VARP(smoothmove, 0, 75, 100);
    VARP(smoothdist, 0, 32, 64);

    void predictplayer(fpsent *d, bool move)
    {
        d->o = d->newpos;
        d->yaw = d->newyaw;
        d->pitch = d->newpitch;
        if(move)
        {
            moveplayer(d, 1, false);
            d->newpos = d->o;
        }
        float k = 1.0f - float(lastmillis - d->smoothmillis)/smoothmove;
        if(k>0)
        {
            d->o.add(vec(d->deltapos).mul(k));
            d->yaw += d->deltayaw*k;
            if(d->yaw<0) d->yaw += 360;
            else if(d->yaw>=360) d->yaw -= 360;
            d->pitch += d->deltapitch*k;
        }
    }

    void otherplayers(int curtime)
    {
        loopv(players) if(players[i] && LogicSystem::getUniqueId(players[i]) >= 0) // Need a complete entity for this
        {
            fpsent *d = players[i];
            if(d == player1 || d->ai) continue;

            if (d->uid < 0) continue;

            #ifdef SERVER
                if (d->serverControlled)
                    continue; // On the server, 'other players' are only PCs
            #endif

            logger::log(logger::INFO, "otherplayers: moving %d from %f,%f,%f", d->uid, d->o.x, d->o.y, d->o.z);

            // TODO: Currently serverside physics for otherplayers run like clientside physics - if
            // there is *ANY* lag, run physics. But we can probably save a lot of CPU on the server
            // if we don't run physics if the lag is 'reasonable'. Note that this is already sort of
            // done by having say lower fps on the server - if the last update was recent enough
            // then the frame decision system may decide we need 0 frames at the moment. But, it
            // might be better to also add an explicit condition, that we don't just check for 0
            // lagtime as below, but also for lagtime within say 1-2 frames at the server's fps rate.
#if (SERVER_DRIVEN_PLAYERS == 0)
            const int lagtime = totalmillis-d->lastupdate; // Change to '1' to have server ALWAYS run physics
#else
            const int lagtime = 1;
#endif

            if(!lagtime) continue;
            if(lagtime>1000 && d->state==CS_ALIVE)
            {
                d->state = CS_LAGGED;
                continue;
            }

            // Ignore intentions to move, if immobile
            if ( !LogicSystem::getLogicEntity(d)->canMove )
                d->turn_move = d->move = d->look_updown_move = d->strafe = d->jumping = 0;

            if(d->state==CS_ALIVE || d->state==CS_EDITING)
            {
                crouchplayer(d, 10, false);
#if (SERVER_DRIVEN_PLAYERS == 0)
                if(smoothmove && d->smoothmillis>0) predictplayer(d, true); // Disable to force server to always move clients
                else moveplayer(d, 1, false);
#else
                moveplayer(d, 1, false);
#endif
            }
            else if(d->state==CS_DEAD && lastmillis-d->lastpain<2000) moveplayer(d, 1, true);

            logger::log(logger::INFO, "                                      to %f,%f,%f", d->o.x, d->o.y, d->o.z);

#if (SERVER_DRIVEN_PLAYERS == 1)
            // Enable this to let server drive client movement
            lua::push_external("entity_set_attr");
            lua::push_external("entity_get");
            lua_pushinteger(lua::L, d->uid);
            lua_call       (lua::L, 1, 1);
            lua_pushliteral(lua::L, "position");
            lua::push_external("entity_get_attr");
            lua_pushvalue  (lua::L, -3);
            lua_pushliteral(lua::L, "position");
            lua_call       (lua::L, 2, 1);
            lua_call       (lua::L,  3, 0);
#endif
        }
    }

    void moveControlledEntities()
    {
#ifndef SERVER
        if (ClientSystem::playerLogicEntity)
        {
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX,
                ClientSystem::playerLogicEntity->lua_ref);
            lua_getfield(lua::L, -1, "initialized");
            bool b = lua_toboolean(lua::L, -1);
            lua_pop(lua::L, 2);
            if (b)
            {
                logger::log(logger::INFO, "Player %d (%p) is initialized, run moveplayer(): %f,%f,%f.",
                    player1->uid, (void*)player1,
                    player1->o.x,
                    player1->o.y,
                    player1->o.z
                );

                // Ignore intentions to move, if immobile
                if ( !ClientSystem::playerLogicEntity->canMove )
                {
                    player1->turn_move = player1->move = player1->look_updown_move = player1->strafe = player1->jumping = 0;
                }

//                if(player1->ragdoll && !(player1->anim&ANIM_RAGDOLL)) cleanragdoll(player1); XXX Needed? See below
                crouchplayer(player1, 10, true);
#if (SERVER_DRIVEN_PLAYERS == 0)
                moveplayer(player1, 10, true); // Disable this to stop play from moving by client command
#endif

                logger::log(logger::INFO, "                              moveplayer(): %f,%f,%f.",
                    player1->o.x,
                    player1->o.y,
                    player1->o.z
                );

                swayhudgun(curtime);
            } else
                logger::log(logger::INFO, "Player is not yet initialized, do not run moveplayer() etc.");
        }
        else
            logger::log(logger::INFO, "Player does not yet exist, or scenario not started, do not run moveplayer() etc.");

#else // SERVER
    #if 1
        // Loop over NPCs we control, moving and sending their info c2sinfo for each.
        loopv(players)
        {
            fpsent* npc = players[i];
            if (!npc->serverControlled || npc->uid == DUMMY_SINGLETON_CLIENT_UNIQUE_ID)
                continue;

            // We do this so lua need not worry in the NPC behaviour code
            while(npc->yaw < -180.0f) npc->yaw += 360.0f;
            while(npc->yaw > +180.0f) npc->yaw -= 360.0f;

            while(npc->pitch < -180.0f) npc->pitch += 360.0f;
            while(npc->pitch > +180.0f) npc->pitch -= 360.0f;

            // Apply physics to actually move the player
            moveplayer(npc, 10, false); // FIXME: Use Config param for resolution and local. 1, false does seem ok though

            logger::log(logger::INFO, "updateworld, server-controlled client %d: moved to %f,%f,%f", i,
                                            npc->o.x, npc->o.y, npc->o.z);

            //?? Dummy singleton still needs to send the messages vector. XXX - do we need this even without NPCs? XXX - works without it
        }
    #endif
#endif
    }

    void updateworld()        // main game update loop
    {
        logger::log(logger::INFO, "updateworld(?, %d)", curtime);
        INDENT_LOG(logger::INFO);

        // SERVER used to initialize turn_move, move, look_updown_move and strafe to 0 for NPCs here

        if(!curtime)
        {
#ifndef SERVER
            gets2c();
            if(player1->clientnum>=0) c2sinfo();
#endif
            return;
        }

#ifndef SERVER
        bool runWorld = ClientSystem::scenarioStarted();
#else
        bool runWorld = (lua::L != NULL);
#endif
        //===================
        // Run physics
        //===================


        if (runWorld)
        {
            #ifndef SERVER
                game::otherplayers(curtime); // Server doesn't need smooth interpolation of other players
            #endif

            game::moveControlledEntities();

            loopv(game::players)
            {
                fpsent* fpsEntity = game::players[i];
                CLogicEntity *entity = LogicSystem::getLogicEntity(fpsEntity);
                if (!entity) continue;

                #ifndef SERVER
                    // Ragdolls
                    int aflags = entity->getAnimationFlags();
                    if (fpsEntity->ragdoll && !(aflags&ANIM_RAGDOLL))
                    {
                        cleanragdoll(fpsEntity);
                    }
                    if (fpsEntity->ragdoll && (aflags&ANIM_RAGDOLL))
                    {
                        moveragdoll(fpsEntity);
                    }
                #endif
            }
            LogicSystem::manageActions(curtime);
        }

#ifndef SERVER
        //================================================================
        // Get messages - *AFTER* otherplayers, which applies smoothness,
        // and after actions, since gets2c may destroy the engine
        //================================================================

        gets2c();
#endif

        //============================================
        // Send network updates, last for least lag
        //============================================

#ifndef SERVER
        // clientnum might be -1, if we have yet to get S2C telling us our clientnum, i.e., we are only partially connected
        if(player1->clientnum>=0) c2sinfo(); //player1, // do this last, to reduce the effective frame lag
#else // SERVER
        c2sinfo(); // Send all the info for all the NPCs
#endif
    }

    void spawnplayer(fpsent *d)   // place at random spawn. also used by monsters!
    {
        spawnstate(d);
        #ifndef SERVER
            d->state = spectator ? CS_SPECTATOR : (d==player1 && editmode ? CS_EDITING : CS_ALIVE);
        #else // SERVER
            d->state = CS_ALIVE;
        #endif
    }

    // inputs

    void doattack(bool on)
    {
    }

    bool canjump()
    {
        return true; // Handled ourselves elsewhere
    }

    bool cancrouch()
    {
        return true; // Handled ourselves elsewhere
    }

    bool allowmove(physent *d)
    {
        return true; // Handled ourselves elsewhere
    }

    vector<fpsent *> clients;

    fpsent *newclient(int cn)   // ensure valid entity
    {
        logger::log(logger::DEBUG, "fps::newclient: %d", cn);

        if(cn < 0 || cn > max(0xFF, MAXCLIENTS)) // + MAXBOTS))
        {
            neterr("clientnum", false);
            return NULL;
        }

#ifndef SERVER // INTENSITY
        if(cn == player1->clientnum)
        {
            player1->uid = -5412; // Wipe uid of new client
            return player1;
        }
#endif

        while(cn >= clients.length()) clients.add(NULL);

        fpsent *d = new fpsent;
        d->clientnum = cn;
        assert(clients[cn] == NULL); // XXX FIXME This fails if a player logged in exactly while the server was downloading assets
        clients[cn] = d;
        players.add(d);

        return clients[cn];
    }

    fpsent *getclient(int cn)   // ensure valid entity
    {
#ifndef SERVER // INTENSITY
        if(cn == player1->clientnum) return player1;
#endif
        return clients.inrange(cn) ? clients[cn] : NULL;
    }

    void clientdisconnected(int cn, bool notify)
    {
        logger::log(logger::DEBUG, "fps::clientdisconnected: %d", cn);

        if(!clients.inrange(cn)) return;
        if(following==cn)
        {
            if(followdir) nextfollow(followdir);
            else stopfollowing();
        }
        fpsent *d = clients[cn];
        if(!d) return;
        if(notify && d->name[0]) conoutf("player %s disconnected", colorname(d));
//        removeweapons(d);
#ifndef SERVER
        removetrackedparticles(d);
        removetrackeddynlights(d);
#endif
        players.removeobj(d);
        DELETEP(clients[cn]);
        cleardynentcache();
    }

    void initclient()
    {
        player1 = spawnstate(new fpsent);
#ifndef SERVER
        players.add(player1);
#endif
    }

    void preload() { }; // We use our own preloading system, but need to add the above projectiles etc.

    void startmap(const char *name)   // called just after a map load
    {
//        if(multiplayer(false) && m_sp) { gamemode = 0; conoutf(CON_ERROR, "coop sp not supported yet"); } Kripken
//        clearmovables();
//        clearprojectiles();
//        clearbouncers();

#ifndef SERVER
        spawnplayer(player1);
        disablezoom();
#endif
//        if(*name) conoutf(CON_GAMEINFO, "\f2game mode is %s", fpsserver::modestr(gamemode));

        //execident("mapstart");

#ifdef SERVER
        server::resetScenario();
#endif
    }

    void physicstrigger(physent *d, bool local, int floorlevel, int waterlevel, int material)
    {
        if (lua::push_external("physics_state_change")) {
            lua_rawgeti(lua::L, LUA_REGISTRYINDEX, LogicSystem::getLogicEntity(d)->lua_ref);
            lua_pushboolean(lua::L, local);
            lua_pushinteger(lua::L, floorlevel);
            lua_pushinteger(lua::L, waterlevel);
            lua_pushinteger(lua::L, material);
            lua_call(lua::L, 5, 0);
        }
    }

    int numdynents()
    {
        return players.length();
    } //+movables.length(); }

    dynent *iterdynents(int i)
    {
        if(i<players.length()) return players[i];
//        i -= players.length();
//        if(i<movables.length()) return (dynent *)movables[i];
        return NULL;
    }

    const char *scriptname(fpsent *d)
    {
        lua::push_external("entity_get_attr_uid");
        lua_pushinteger(lua::L, LogicSystem::getUniqueId(d));
        lua_pushliteral(lua::L, "character_name");
        lua_call       (lua::L,  2, 1);
        const char *ret = lua_tostring(lua::L, -1); lua_pop(lua::L, 1);
        return ret;
    }

    char *colorname(fpsent *d, char *name, const char *prefix)
    {
        if(!name) name = (char*)scriptname(d);
        const char* color = (d != player1) ? "" : "\f1";
        static string cname;
        formatstring(cname, "%s%s", color, name);
        return cname;
    }

#ifndef SERVER
    void drawhudmodel(fpsent *d, int anim, float speed = 0, int base = 0)
    {
        logger::log(logger::WARNING, "Rendering hudmodel is deprecated for now");
    }

    void drawhudgun()
    {
        logger::log(logger::WARNING, "Rendering hudgun is deprecated for now");
    }

    bool needminimap() // you have to enable the minimap inside your map script.
    {
        return (!mainmenu && useminimap);
    }

    float abovegameplayhud()
    {
        return 1650.0f/1800.0f;
    }

    void gameplayhud(int w, int h)
    {
    }
#endif

    void particletrack(physent *owner, vec &o, vec &d)
    {
#ifndef SERVER
        if(owner->type!=ENT_PLAYER) return;
//        fpsent *pl = (fpsent *)owner;
        float dist = o.dist(d);
        o = vec(0,0,0); //pl->muzzle;
        if(dist <= 0) d = o;
        else
        {
            vecfromyawpitch(owner->yaw, owner->pitch, 1, 0, d);
            float newdist = raycube(owner->o, d, dist, RAY_CLIPMAT|RAY_ALPHAPOLY);
            d.mul(min(newdist, dist)).add(owner->o);
        }
#else // SERVER
        assert(0);
#endif
    }

    void newmap(int size)
    {
        // Generally not used, as we fork emptymap, but useful to clear and resize
    }

    // any data written into this vector will get saved with the map data. Must take care to do own versioning, and endianess if applicable. Will not get called when loading maps from other games, so provide defaults.
    void writegamedata(vector<char> &extras) {}
    void readgamedata(vector<char> &extras) {}

    const char *gameident() { return "fps"; }
    const char *defaultmap() { return "login"; }
    const char *savedservers() { return NULL; } //"servers.cfg"; }

    // Dummies

    void parseoptions(vector<const char *> &args)
    {
        loopv(args)
        {
            const char* arg = args[i];
            printf("parseoptions: %c\r\n", arg[1]);
            #ifdef INTENSITY_PLUGIN
                if (arg[1] == 'P')
                {
                    PluginListener::initialize();
                }
            #endif
        }
    }

    const char *getmapinfo()
    {
        return "";
    }

    float clipconsole(float w, float h)
    {
        return 0;
    }

    void loadconfigs()
    {
    }

    bool ispaused() { return false; };

    void dynlighttrack(physent *owner, vec &o, vec &hud)
    {
        return;
    }
}
