local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local timer = timer
local string = string
local tonumber = tonumber
local os    = {
    getenv = os.getenv,
    execute = os.execute
}
local io = {
    popen = io.popen,
    open  = io.open,
    close  = io.close
}
local table = {
    insert  = table.insert
}
local volume_widget = {}

local img = nil
local tb = nil

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

function volume_widget.init(a_mode, a_channel)
    img = wibox.widget.imagebox()
    tb = wibox.widget.textbox("N/A%")

    mode = a_mode
    channel = a_channel

    if mode == "oss" then
        up = "ossmix " .. channel .. " +2"
        down = "ossmix " .. channel .. " -- -2"
        mute = "ossmix " .. channel .. " 0"
        unmute = "ossmix " .. channel .. " "
        value = function() return io.popen("ossmix " .. channel):match("(%d+)"):read() end

        initialized = true
    elseif mode == "alsa" then
        up = "amixer sset " .. channel .. " 2%+"
        down = "amixer sset " .. channel .. " 2%-"
        mute = "amixer sset " .. channel .. " 0"
        unmute = "amixer sset " .. channel .. " "
        unmute2 = "%"
        value = function() return io.popen("amixer get " .. channel):read():match("(%d+)%%") end

        initialized = true
    end
    volume_widget.volume(display)

    local but = awful.util.table.join(
    awful.button({ }, 3, function () volume_widget.volume("mute") end),
    awful.button({ }, 4, function () volume_widget.volume("up") end),
    awful.button({ }, 5, function () volume_widget.volume("down") end)
    )
    tb:buttons(but)
    img:buttons(but)

    local timer = timer { timeout = 7 }
    timer:connect_signal("timeout", function() volume_widget.volume("display") end)
    timer:start()
end


function volume_widget.volume(mode)
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
    img:set_image(beautiful["vol_" .. vol_lvl])
    tb:set_text(volume .."%")
end

function volume_widget.textbox()
    return tb
end
function volume_widget.imagebox()
    return img
end

return volume_widget
