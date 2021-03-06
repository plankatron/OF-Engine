
// Copyright 2010 Alon Zakai ('kripken'). All rights reserved.
// This file is part of Syntensity/the Intensity Engine, an open source project. See COPYING.txt for licensing.

#include "cube.h"
#include "engine.h"
#include "game.h"

#include "message_system.h"

#include "targeting.h"

#include "client_system.h"
#include "of_world.h"

int            ClientSystem::playerNumber       = -1;
CLogicEntity  *ClientSystem::playerLogicEntity  = NULL;
bool           ClientSystem::loggedIn           = false;
bool           ClientSystem::editingAlone       = false;
int            ClientSystem::uniqueId           = -1;
/* the buffer is large enough to hold the uuid */
string         ClientSystem::currScenarioCode   = "";

bool _scenarioStarted = false;
bool _mapCompletelyReceived = false;

void ClientSystem::connect(const char *host, int port)
{
    editingAlone = false;

    connectserv((char *)host, port, "");
}

void ClientSystem::login(int clientNumber)
{
    logger::log(logger::DEBUG, "ClientSystem::login()");

    playerNumber = clientNumber;

    MessageSystem::send_LoginRequest();
}

void ClientSystem::finishLogin(bool local)
{
    editingAlone = local;
    loggedIn = true;

    logger::log(logger::DEBUG, "Now logged in, with unique_ID: %d", uniqueId);
}

void ClientSystem::doDisconnect()
{
    disconnect();
}

void ClientSystem::onDisconnect()
{
    editingAlone = false;
    playerNumber = -1;
    loggedIn     = false;
    _scenarioStarted  = false;
    _mapCompletelyReceived = false;

    // it's also useful to stop all mapsounds and gamesounds (but only for client that disconnects!)
    stopsounds();

    // we also must get the lua system into clear state
    LogicSystem::clear(true);
}

bool ClientSystem::scenarioStarted()
{
    if (!_mapCompletelyReceived)
        logger::log(logger::INFO, "Map not completely received, so scenario not started");

    // If not already started, test if indeed started
    if (_mapCompletelyReceived && !_scenarioStarted)
    {
        if (lua::L) {
            lua::pop_external_ret(lua::call_external_ret("scene_is_ready", "",
                "b", &_scenarioStarted));
        }
    }

    return _mapCompletelyReceived && _scenarioStarted;
}

extern void cursor_get_position(float &x, float &y);
extern int cursor_exists;

void ClientSystem::frameTrigger(int curtime)
{
    if (scenarioStarted())
    {
        float delta = float(curtime)/1000.0f;

        /* turn if mouse is at borders */
        float x, y;
        cursor_get_position(x, y);

        /* do not scroll with mouse */
        if (cursor_exists) x = y = 0.5;

        /* turning */
        gameent *fp = (gameent*)player;
        float fs;
        lua::pop_external_ret(lua::call_external_ret("entity_get_attr", "is",
            "f", ClientSystem::playerLogicEntity->getUniqueId(), "facing_speed", &fs));
        if (fp->turn_move || fabs(x - 0.5) > 0.495)
        {
            player->yaw += fs * (
                fp->turn_move ? fp->turn_move : (x > 0.5 ? 1 : -1)
            ) * delta;
        }

        if (fp->look_updown_move || fabs(y - 0.5) > 0.495)
        {
            player->pitch += fs * (
                fp->look_updown_move ? fp->look_updown_move : (y > 0.5 ? -1 : 1)
            ) * delta;
        }

        /* normalize and limit the yaw and pitch values to appropriate ranges */
        extern void fixcamerarange();
        fixcamerarange();

        TargetingControl::determineMouseTarget();
    }
}

void ClientSystem::finishLoadWorld()
{
    extern bool finish_load_world();
    finish_load_world();

    _mapCompletelyReceived = true; // We have the original map + static entities (still, scenarioStarted might want more stuff)

    ClientSystem::editingAlone = false; // Assume not in this mode

    lua::call_external("gui_clear", ""); // (see prepareForMap)
}

void ClientSystem::prepareForNewScenario(const char *sc)
{
    _mapCompletelyReceived = false; // We no longer have a map. This implies scenarioStarted will return false, thus
                                    // stopping sending of position updates, as well as rendering

    mainmenu = 1; // Keep showing GUI meanwhile (in particular, to show the message about a new map on the way

    // Clear the logic system, as it is no longer valid - were it running, we might try to process messages from
    // the new map being set up on the server, even though they are irrelevant to the existing engine, set up for
    // another map with its Classes etc.
    LogicSystem::clear();

    copystring(currScenarioCode, sc);
}

bool ClientSystem::isAdmin()
{
    if (!loggedIn) return false;
    if (!playerLogicEntity) return false;

    bool b;
    lua::pop_external_ret(lua::call_external_ret("entity_get_attr", "is",
        "b", playerLogicEntity->getUniqueId(), "can_edit", &b));
    return b;
}

