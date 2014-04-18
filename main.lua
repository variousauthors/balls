local origin, player
local text = "nothing"

function Point(x, y)
    local x, y = x, y
    
    return {
        getX = function ()
            return x
        end,

        getY = function ()
            return y
        end,

        setX = function (n)
            x = n
        end,

        setY = function (n)
            y = n
        end
    }
end

function Player(point)
    local p = point

    return {
        getX = p.getX,
        getY = p.getY,

        update = function ()
            if love.keyboard.isDown("down") then
                p.setY(p.getY() + 1)
            end

            if love.keyboard.isDown("up") then
                p.setY(p.getY() - 1)
            end

            if love.keyboard.isDown("right") then
                p.setX(p.getX() + 1)
            end

            if love.keyboard.isDown("left") then
                p.setX(p.getX() - 1)
            end
        end
    }
end

function love.draw()
    love.graphics.circle("fill", player.getX(), player.getY(), 10)
    love.graphics.circle("fill", origin.getX(), origin.getY(), 10)
end

function love.load()
   -- image = love.graphics.newImage("cake.jpg")
   love.graphics.setNewFont(12)
   love.graphics.setColor(0,0,0)
   love.graphics.setBackgroundColor(255,255,255)

   origin = Point(love.window.getWidth() / 2, love.window.getHeight() / 2)
   player = Player(origin)
end

function love.focus(f) gameIsPaused = not f end

function love.update(dt)
    player.update(dt)
end
