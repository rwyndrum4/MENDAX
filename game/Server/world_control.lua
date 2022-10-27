local world_control = {}

local nk = require("nakama")

local SPAWN_POSITION = {1800.0, 1280.0}
local SPAWN_HEIGHT = 463.15
local WORLD_WIDTH = 1500

-- Custom operation codes. Nakama specific codes are <= 0.
local OpCodes = {
        update_position = 0,
        update_input = 1,
        do_spawn = 2
}

-- Command pattern table for functions that will use data and state
local commands = {}

-- Updates the position in the game state
commands[OpCodes.update_position] = function(data, state)
    local id = data.id
    local position = data.pos
    if state.positions[id] ~= nil then
        state.positions[id] = position
    end
end

--updates the input in the game state
commands[OpCodes.update_input] = function(data, state)
        local id = data.id
        local input = data.inp
        if state.inputs[id] ~= nil then
                state.inputs[id] = input
        end
end

-- When the match is initialized. Creates empty tables in the game state that will be populated by
-- clients.
function world_control.match_init(_, _)
    local gamestate = {
        presences = {},
        inputs = {},
        positions = {},
        jumps = {},
        names = {}
    }
    local tickrate = 10
    local label = "Game world"
    return gamestate, tickrate, label
end

-- When someone tries to join the match. Checks if someone is already logged in and blocks them from
-- doing so if so.
function world_control.match_join_attempt(_, _, _, state, presence, _)
    if state.presences[presence.user_id] ~= nil then
        return state, false, "User already logged in."
    end
    return state, true
end

-- When someone does join the match. Initializes their entries in the game state tables with dummy
-- values until they spawn in.
function world_control.match_join(_, dispatcher, _, state, presences)
    for _, presence in ipairs(presences) do
        state.presences[presence.user_id] = presence

        state.positions[presence.user_id] = {
            ["x"] = 0,
            ["y"] = 0
        }

        state.inputs[presence.user_id] = {
            ["dir"] = 0,
            ["jmp"] = 0
        }

        state.names[presence.user_id] = "User"
    end

    return state
end

-- When someone leaves the match. Clears their entries in the game state tables, but saves their
-- position to storage for next time.
function world_control.match_leave(_, _, _, state, presences)
    for _, presence in ipairs(presences) do
        local new_objects = {
            {
                collection = "player_data",
                key = "position_" .. state.names[presence.user_id],
                user_id = presence.user_id,
                value = state.positions[presence.user_id]
            }
        }
        nk.storage_write(new_objects)

        state.presences[presence.user_id] = nil
        state.positions[presence.user_id] = nil
        state.inputs[presence.user_id] = nil
        state.jumps[presence.user_id] = nil
        state.names[presence.user_id] = nil
    end
    return state
end

-- Called `tickrate` times per second. Handles client messages and sends game state updates. Uses
-- boiler plate commands from the command pattern except when specialization is required.
function world_control.match_loop(_, dispatcher, _, state, messages)
    for _, message in ipairs(messages) do
        local op_code = message.op_code

        local decoded = nk.json_decode(message.data)

        -- Run boiler plate commands (state updates.)
        local command = commands[op_code]
        if command ~= nil then
            commands[op_code](decoded, state)
        end

        -- A client has selected a character and is spawning. Get or generate position data,
        -- send them initial state, and broadcast their spawning to existing clients.
        if op_code == OpCodes.do_spawn then
            local object_ids = {
                {
                    collection = "player_data",
                    key = "position_" .. decoded.nm,
                    user_id = message.sender.user_id
                }
            }

            local position
            for _, object in ipairs(objects) do
                position = object.value
                if position ~= nil then
                    state.positions[message.sender.user_id] = position
                    break
                end
            end

            if position == nil then
                state.positions[message.sender.user_id] = {
                    ["x"] = SPAWN_POSITION[1],
                    ["y"] = SPAWN_POSITION[2]
                }
            end

            state.names[message.sender.user_id] = decoded.nm

            local data = {
                ["pos"] = state.positions,
                ["inp"] = state.inputs,
                ["col"] = state.colors,
                ["nms"] = state.names
            }

            local encoded = nk.json_encode(data)
            dispatcher.broadcast_message(OpCodes.initial_state, encoded, {message.sender})

            dispatcher.broadcast_message(OpCodes.do_spawn, message.data)
        elseif op_code == OpCodes.update_color then
            dispatcher.broadcast_message(OpCodes.update_color, message.data)
        end
    end

    local data = {
        ["pos"] = state.positions,
        ["inp"] = state.inputs
    }
    local encoded = nk.json_encode(data)

    dispatcher.broadcast_message(OpCodes.update_state, encoded)

    for _, input in pairs(state.inputs) do
        input.jmp = 0
    end

    return state
end

-- Called when the match handler receives a runtime signal.
function world_control.match_signal(_, _, _, state, data)
        return state, data
end

return world_control