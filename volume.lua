local awful = awful
local beautiful = beautiful
local widget = widget
local timer = timer
local string = string
local tonumber = tonumber
local image = image
local os    = {
    getenv = os.getenv,
    execute = os.execute
}
local io = {
    open  = io.open,
    close  = io.close
}
local table = {
    insert  = table.insert
}
module("iniquitous.volume")

local img = widget({ type = "imagebox" })
local tb = widget({ type = "textbox" })
tb.text = "N/A%"

local initialized = false

local channel = ""
local mode = ""

local mute = ""
local unmute = ""
local unmute2 = ""

local up = ""
local down = ""
local value = nil

local vol = 0

function init(a_mode, a_channel)
    mode = a_mode
    channel = a_channel

    if mode == "oss" then
        up = "ossmix " .. channel .. " +2"
        down = "ossmix " .. channel .. " -- -2"
        mute = "ossmix " .. channel .. " 0"
        unmute = "ossmix " .. channel .. " "
        value = function() return awful.util.pread("ossmix " .. channel):match("(%d+)") end

        initialized = true
    elseif mode == "alsa" then
        up = "amixer sset " .. channel .. " 2%+"
        down = "amixer sset " .. channel .. " 2%-"
        mute = "amixer sset " .. channel .. " 0"
        unmute = "amixer sset " .. channel .. " "
        unmute2 = "%"
        value = function() return awful.util.pread("amixer get " .. channel):match("(%d+)%%") end

        initialized = true
    end
    volume(display)

    local but = awful.util.table.join(
    awful.button({ }, 3, function () volume("mute") end),
    awful.button({ }, 4, function () volume("up") end),
    awful.button({ }, 5, function () volume("down") end)
    )
    tb:buttons(but)
    img:buttons(but)

    local timer = timer { timeout = 7 }
    timer:add_signal("timeout", function() volume("display") end)
    timer:start()
end


function volume(mode)
    if mode == "up" then
        os.execute(up .. " >/dev/null")
    elseif mode == "down" then
        os.execute(down .. " >/dev/null")
    elseif mode == "mute" then
        --The mute option is useless without ossvol, ossmix does not navitely support muting
        --awful.util.spawn("ossvol -t")
        local volume = value()

        volume = tonumber(volume)
        if volume == 0 then
            os.execute(unmute .. vol .. unmute2 .. " >/dev/null")
        else
            vol = volume
            os.execute(mute .. " >/dev/null")
        end
    end

    local volume = tonumber(value())
    display(volume)
end

function display(volume)
    if volume == nil then
        vol_lvl = "mute"
        volume = 0
    elseif volume == 0 then
        vol_lvl = "mute"
    elseif volume < 25 then
        vol_lvl = "low"
    elseif volume < 50 then
        vol_lvl = "med"
    elseif volume < 75 then
        vol_lvl = "med2"
    else
        vol_lvl = "high"
    end
    img.image = image(beautiful["vol_" .. vol_lvl])
    tb.text = volume .."%"
end

function textbox()
    return tb
end
function imagebox()
    return img
end
