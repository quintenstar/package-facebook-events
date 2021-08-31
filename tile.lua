local api, CHILDS, CONTENTS = ...

-- local json = require "json"

local M = {}
local font
local image
local bg_color
local pages

function M.updated_config_json(config) -- if page child settings are updated
    font = resource.load_font(api.localized(config.font.asset_name))
    image =
        resource.load_image {
        file = api.localized(config.default_image.asset_name),
        mipmap = true
    }

    bg_color = config.background_color

    pages = config.pages

    node.gc() -- force garbace collection on node
end

local events
function M.updated_events_json(events_json)
    print("events", events)
    events = events_json
end

local playlist = {}
local function create_playlist(page)
    for idx = 1, #page do
        print(idx)
        local event = page[idx]
        print("event name", event.name)
        print("image file", event.cover)

        local cover
        cover =
            resource.load_image {
            file = api.localized(event.cover),
            mipmap = true
        }
        if cover == nil then
            cover = image
        end

        print("create playlist")
        playlist[idx] = {
            name = event.name,
            cover = cover,
            start_time = event.start_time,
            end_time = event.end_time
        }
    end
    return playlist
end

-- local event_gen =
--     util.generator(
--     function()
--         return playlist
--     end
-- )

function M.task(starts, ends, config, x1, y1, x2, y2) -- render child node
    print("start en end", starts, ends)
    print("page_name from config", config.page_name)

    local width = x2 - x1
    local height = y2 - y1

    -- TODO load and select fallback asset outside task
    if #events[config.page_name] == 0 then
        local fallback_asset

        print("Use fallback image", starts, ends)
        api.wait_t(starts - 5)

        for key, page_options in pairs(pages) do
            print(page_options.name, page_options.id, page_options.fallback_asset)
            if page_options.name == config.page_name then
                fallback_asset =
                    resource.load_image {
                    file = api.localized(page_options.fallback_asset.asset_name),
                    mipmap = true
                }
                break
            end
        end

        for now in api.frame_between(starts, ends) do
            api.screen.set_scissor(x1, y1, x2, y2)
            fallback_asset:draw(x1, y1, x2, y2)
        end

        fallback_asset:dispose()
    else
        local page = events[config.page_name]
        print("page json content", page)
        playlist = create_playlist(page)

        print("Draw events", starts, ends)
        api.wait_t(starts - 5)

        for now in api.frame_between(starts, ends) do
            --local event = event_gen.next()

            api.screen.set_scissor(x1, y1, x2, y2)
            gl.clear(bg_color.r, bg_color.g, bg_color.b, bg_color.a) -- green

            for idx = 1, #playlist do
                local event = playlist[idx]

                font:write(x1 + 360, y1 + 150 * (idx - 1) + 40, event.name, 50, 0, 0, 0, 1)

                if event.end_time == 0 then -- No end_time provided
                    font:write(
                        x1 + 360,
                        y1 + 150 * (idx - 1) + 90,
                        os.date("%A %d %b %H:%M", event.start_time),
                        40,
                        0,
                        0,
                        0,
                        1
                    )
                else -- display end_time
                    font:write(
                        x1 + 360,
                        y1 + 150 * (idx - 1) + 90,
                        os.date("%A %d %b %H:%M", event.start_time) .. " - " .. os.date("%H:%M", event.end_time),
                        40,
                        0,
                        0,
                        0,
                        1
                    )
                end
                -- TODO case for end time >24h (display date)
                event.cover:draw(x1 + 80, y1 + 150 * (idx - 1) + 30, x1 + 311, y1 + 150 * (idx - 1) + 30 + 130)
            end

            api.screen.set_scissor()
        end

        -- TODO don't clean up when same frame after each other
        -- clean up
        print("cleaning up", starts, ends, sys.now())
        api.wait_t(ends + 5)
        print("cleaning up after", starts, ends, sys.now())
        for idx = 1, #playlist do
            local event = playlist[idx]
            event.cover:dispose()
        end
        playlist = {}
    end
end

function M.unload()
    print "sub module is unloaded"
end

function M.content_update(name)
    print("sub module content update", name)
end

function M.content_remove(name)
    print("sub module content delete", name)
end

return M
