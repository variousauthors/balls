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

local countdown = 3
local gameOver  = false

function love.draw()
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle("fill", player.getX(), player.getY(), 10)

    if (countdown > 0) then
        -- draw the countdown
        love.graphics.setColor(200, 0, 0)
        love.graphics.setFont(COUNTDOWN_FONT)
        love.graphics.printf(math.ceil(countdown), -10, W_HEIGHT / 2 - 175, W_WIDTH, "center")
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

    src1 = love.audio.newSource("assets/126029__strahlenkater__anp-proc-kick9.wav", "static")

    src1:setVolume(0.7) -- 90% of ordinary volume
    src1:setPitch(0.5) -- one octave lower

    src2 = love.audio.newSource("assets/47693__jarryd19__b-kick.wav", "static")

    src2:setVolume(0.7) -- 90% of ordinary volume
    src2:setPitch(0.5) -- one octave lower

    origin  = Point(W_WIDTH / 2, W_HEIGHT / 2)
    player  = Entities.Player(origin)
    orbiters = {
        Entities.Orbiter(origin, W_WIDTH, W_WIDTH, math.pi / 10, 200, RED, 10, src1),
        Entities.Orbiter(origin, W_WIDTH * 2, W_HEIGHT * 2, math.pi / 5, 300, GREEN, 20),
        Entities.Orbiter(origin, W_WIDTH, W_HEIGHT, math.pi / 3, 100, BLUE, 40, src2)
    }
end

function love.focus(f) gameIsPaused = not f end

-- if the game is over, press space to go again!
function love.keyreleased(key)
    debug = key
    if (gameOver == true and key == " ") then
        gameOver  = false
        countdown = 3
        score     = 0
        time      = 0
        player = Entities.Player(origin)
        orbiters = {
            Entities.Orbiter(origin, W_WIDTH, W_WIDTH, math.pi / 10, 200, RED, 10),
            Entities.Orbiter(origin, W_WIDTH * 2, W_HEIGHT * 2, math.pi / 5, 300, GREEN, 20),
            Entities.Orbiter(origin, W_WIDTH, W_HEIGHT, math.pi / 3, 100, BLUE, 40)
        }
    end
end

function love.update(dt)
    if gameIsPaused then return end

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


