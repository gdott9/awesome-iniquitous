local awful = require("awful")
local naughty = require("naughty")
local wibox = require("wibox")

local timer = timer
local string = string
local os    = {
    getenv = os.getenv,
    execute = os.execute
}
local io = {
    open  = io.open,
    close  = io.close,
    popen = io.popen
}
local table = {
    insert  = table.insert
}
local tonumber = tonumber

local mpc = {}

function music_current_short()
    local music = io.popen('mpc -f "[%artist%]##[%track%]##[%title%]##[%time%]##" | head -2 | sed "s/^\\[\\(playing\\|paused\\)\\] \\+#[0-9]\\+\\/[0-9]\\+ \\+\\([0-9]\\+:[0-9]\\+\\)\\/.*$/\\1#\\2#/" | tr -d "\\n"'):read("*a")
    --print(music)

    local len_max = 20
    local t = {}
    for k in string.gmatch(music, "[^#]*#") do
        k = string.sub(k, 1, string.len(k)-1)
        if(string.len(k) > len_max) then
            k = string.sub(k, 1, len_max).."..."
        end
        table.insert(t, k)
    end

    local res
    if(#t >= 6) then
        res = t[1].. " - " ..t[2].. " - " ..t[3].. " # " .. t[6] .. "/" ..t[4].. " ["..t[5].."]"
    else
        res = "Mpd Daemon is not runnig"
    end

    return awful.util.escape(res)
end
function music_current_full()
    local music = io.popen("mpc -f  \"[%artist%]\\n%album%\\n%track% - %title%\\n## %time%\" | head -4"):read("*a")

    if(string.len(music) == 0) then
        music = "Mpd Daemon is not runnig"
    else
        music = string.sub(music, 1, string.len(music)-1)
    end

    return awful.util.escape(music)
end
function music_cover()
    local cover = os.getenv("HOME") .. "/.album/default.png"
    local music = io.popen("mpc -f \"%artist%-%album%\""):read("*a")
    --local dir = awful.util.pread("qdbus org.gnome.Rhythmbox /org/gnome/Rhythmbox/Player \"org.gnome.Rhythmbox.Player.getPlayingUri\"")
    --local dir_format = url_decode(dir:sub(8, dir:find("\/[^\/]+$")))
    --print(dir_format)

    local dir = "/home/gdott9/Music/" .. io.popen("dirname \"`mpc -f '%file%' | head -1`\""):read("*a")

    if(string.len(music) > 0) then
        music = string.gsub(string.sub(music, 1, string.len(music)-1), "[/?%*:|\"<>]", "_")
        --local file = os.getenv("HOME") .. "/.album/".. music ..".jpg"
        local file = string.sub(dir, 1, string.len(dir)-1) .. "/cover.jpg"
        local test = io.open(file)
    --print(file)

        if(test ~= nil) then
            --print("good")
            io.close(test)
            cover = file
        else
            file = os.getenv("HOME") .. "/.album/".. music ..".jpg"
            test = io.open(file)
            if(test ~= nil) then
                io.close(test)
                cover = file
            end
            --print("bad")
        end
    end

    return cover
    --local cover = awful.util.pread("conkyRhythmbox -d CA")

    --return (cover.len > 0) and cover or os.getenv("HOME") .. "/.album/default.png"
end
function notify()
    naughty.notify({
        icon=music_cover(),
        icon_size=50,
        text=music_current_full(),
        position="bottom_right",
        timeout=2
    })
end

function url_decode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)",
      function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

function mpc.init()
    tb = wibox.widget.textbox("loading")
    tb:buttons(awful.util.table.join(
    awful.button({ }, 1, function () notify() end),
    awful.button({ }, 3, function ()
        os.execute("mpc toggle >/dev/null")
        tb:set_text(music_current_short())
    end)
    ))

    local timer = timer { timeout = 2 }
    timer:connect_signal("timeout", function() tb:set_text(music_current_short()) end)
    timer:start()

    tb:set_text(music_current_short())
    return tb
end

return mpc
