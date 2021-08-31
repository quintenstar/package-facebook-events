gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

-- TODO unify with tile.lua more
-- tile = require("tile")

local x1, y1, x2, y2 = 0, 0, NATIVE_WIDTH, NATIVE_HEIGHT

local font
local bg_color

local pages
local page_name
local image
local fallback_asset
local events

local playlist = {}

util.json_watch(
    "config.json",
    function(config)
        bg_color = config.background_color
        font = resource.load_font(config.font.asset_name)

        image =
            resource.load_image {
            file = config.default_image.asset_name,
            mipmap = true
        }

        pages = config.pages

        page_name = pages[1].name
    end
)

function create_playlist(page)
    playlist = {}
    for idx = 1, #page do
        print(idx)
        local event = page[idx]
        print("event name", event.name)
        print("image file", event.cover)

        local cover

        if event.cover == nil or event.cover == 0 then
            cover = image
        else
            cover =
                resource.load_image {
                file = event.cover,
                mipmap = true
            }
        end

        playlist[idx] = {
            name = event.name,
            cover = cover,
            start_time = event.start_time,
            end_time = event.end_time
        }
    end
    print("create playlist", idx, #playlist)
    return playlist
end

util.json_watch(
    "events.json",
    function(events_json)
        events = events_json
        print("events", events)

        local page = events[page_name]
        playlist = create_playlist(page)
        print("page_name", page_name)

        for key, page_options in pairs(pages) do
            print(page_options.name, page_options.id, page_options.fallback_asset)
            if page_options.name == page_name then
                fallback_asset =
                    resource.load_image {
                    file = page_options.fallback_asset.asset_name,
                    mipmap = true
                }
                break
            end
        end
    end
)

function node.render()
    print("start node render")
    print(events, page_name)
    gl.clear(bg_color.r, bg_color.g, bg_color.b, bg_color.a) -- green

    font:write(120, 320, "WIP ...", 100, 1, 1, 1, 1)

    if #events[page_name] == 0 then
        fallback_asset:draw(x1, y1, x2, y2)
    else
        --local event = event_gen.next()
        gl.clear(bg_color.r, bg_color.g, bg_color.b, bg_color.a) -- green
        print("start drawing", #playlist)
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
    end
    -- fallback_asset:dispose()
end
