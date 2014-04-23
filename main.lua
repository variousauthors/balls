require "entities"

local origin, player, orbiter
local debug   = "nothing"
local status  = "happy"
local time    = 0
local score   = 0

local RED    = { 200, 55, 0 }
local GREEN  = { 0, 200, 55 }
local BLUE   = { 55, 0, 200 }

local W_WIDTH  = love.window.getWidth()
local W_HEIGHT = love.window.getHeight()

local SCORE_FONT     = love.graphics.newFont("assets/Audiowide-Regular.ttf", 14)
local COUNTDOWN_FONT = love.graphics.newFont("assets/Audiowide-Regular.ttf", 256)
local SPACE_FONT     = love.graphics.newFont("assets/Audiowide-Regular.ttf", 64)

local countdown = 3.5
local gameOver  = false
local bgm

do
    -- will hold the currently playing sources
    local sources = {}

    -- check for sources that finished playing and remove them
    -- add to love.update
    function love.audio.update()
        local remove = {}
        for _,s in pairs(sources) do
            if s:isStopped() then
                remove[#remove + 1] = s
            end
        end

        for i,s in ipairs(remove) do
            sources[s] = nil
        end
    end

    -- overwrite love.audio.play to create and register source if needed
    local play = love.audio.play
    function love.audio.play(what, how, loop)
        local src = what
        if type(what) ~= "userdata" or not what:typeOf("Source") then
            src = love.audio.newSource(what, how)
            src:setLooping(loop or false)
        end

        play(src)
        sources[src] = src
        return src
    end

    -- stops a source
    local stop = love.audio.stop
    function love.audio.stop(src)
        if not src then return end
        stop(src)
        sources[src] = nil
    end
end

local debounce = false

function love.draw()
    if (countdown < 0) then
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("fill", player.getX(), player.getY(), 10)
    end

    if (countdown > 0 and countdown < 3) then
        local ceil = math.ceil(countdown)

        -- draw the countdown
        love.graphics.setColor(200, 0, 0)
        love.graphics.setFont(COUNTDOWN_FONT)
        love.graphics.printf(ceil, -10, W_HEIGHT / 2 - 175, W_WIDTH, "center")
        
        if (ceil < countdown + 0.1 and ceil > countdown - 0.1) then
            if (debounce == false) then
                debounce = true
                love.audio.play("assets/countdown.wav")
            end
        else
            debounce = false
        end
    end

    for i, orbiter in ipairs(orbiters) do
        orbiter.draw()
    end

    local increment = (W_WIDTH - 100) / 100
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("fill", 50, W_HEIGHT - 50, math.max(player.getPower() * increment, 0), 20);

    -- draw the timer
    love.graphics.setFont(SCORE_FONT)
    love.graphics.print(score, 50, 50)

    if (gameOver) then
        -- draw the prompt
        love.graphics.setColor(0, 0, 0)
        love.graphics.setFont(SPACE_FONT)
        love.graphics.printf("press space", -10, W_HEIGHT / 2 - 175, W_WIDTH, "center")
    end

end

function love.load()
    -- image = love.graphics.newImage("cake.jpg")
    love.graphics.setBackgroundColor(200, 200, 200)

    bgm = love.audio.play("assets/Jarek_Laaser_-_Pump_It_Up.mp3", "stream", true) -- stream and loop background music

    origin  = Point(W_WIDTH / 2, W_HEIGHT / 2)
    player  = Entities.Player(origin)
    orbiters = {
        Entities.Orbiter(origin, W_WIDTH * 5, W_WIDTH * 5, math.pi / 20, 200, RED, 10, "assets/126029__strahlenkater__anp-proc-kick9.wav"),
        Entities.Orbiter(origin, W_WIDTH * 2, W_HEIGHT * 2, math.pi / 5, 300, GREEN, 20, "assets/8113__bliss__brownnoisesplinedkick1.wav"),
        Entities.Orbiter(origin, W_WIDTH, W_HEIGHT, math.pi / 3, 100, BLUE, 40, "assets/47693__jarryd19__b-kick.wav")
    }
end

function love.focus(f) gameIsPaused = not f end

-- if the game is over, press space to go again!
function love.keyreleased(key)
    if (key == "escape") then
        love.event.quit()
    end

    if (key == " ") then
        gameOver  = false
        countdown = 4
        score     = 0
        time      = 0
        player = Entities.Player(origin)
        orbiters = {
            Entities.Orbiter(origin, W_WIDTH * 5, W_WIDTH * 5, math.pi / 20, 200, RED, 10, "assets/126029__strahlenkater__anp-proc-kick9.wav"),
            Entities.Orbiter(origin, W_WIDTH * 2, W_HEIGHT * 2, math.pi / 5, 300, GREEN, 20, "assets/8113__bliss__brownnoisesplinedkick1.wav"),
            Entities.Orbiter(origin, W_WIDTH, W_HEIGHT, math.pi / 3, 100, BLUE, 40, "assets/47693__jarryd19__b-kick.wav")
        }
        love.audio.stop(bgm)
        love.audio.play(bgm)
    end
end

function love.update(dt)
    if gameIsPaused then return end

    love.audio.update()

    time = time + dt

    if (countdown > 0) then
        countdown = countdown - dt * 2
    end

    if (player.getPower() > 0) then
        score = time

        for i, orbiter in ipairs(orbiters) do
            orbiter.update(dt, player)
        end

        player.update(dt)
    else
        gameOver = true
    end
end


