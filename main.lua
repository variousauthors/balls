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

function Vector(x, y)
    return Point(x, y)
end

function Player(point)
    local p, speed, acceleration, max_speed = point, 0, 0, 500
    v = Vector(0, 0)

    slow_down = function (dt, get, set)
        if (get() == 0) then
        elseif (get() > 0) then
            set(math.max(get() - 1 * dt, 0))
        else
            set(math.min(get() + 1 * dt, 0))
        end
    end

    return {
        getX = p.getX,
        getY = p.getY,

        update = function (dt)
            local is_moving

            is_moving    = love.keyboard.isDown("down", "up", "right", "left")
            speed        = v.getX() * max_speed
            acceleration = 1 - speed / max_speed

            if (is_moving) then
                if love.keyboard.isDown("right") then
                    v.setX(math.min(v.getX() + 1 * dt, 1))
                elseif love.keyboard.isDown("left") then
                    v.setX(math.max(v.getX() - 1 * dt, -1))
                else
                    slow_down(dt, v.getX, v.setX)
                end

                if love.keyboard.isDown("down") then
                    v.setY(math.min(v.getY() + 1 * dt, 1))
                elseif love.keyboard.isDown("up") then
                    v.setY(math.max(v.getY() - 1 * dt, -1))
                else
                    slow_down(dt, v.getY, v.setY)
                end
            else
                slow_down(dt, v.getX, v.setX)
                slow_down(dt, v.getY, v.setY)
            end

            -- TODO diagonal movement needs to be sqrt(2) times harder
            -- TODO change in direction should be incremental

            p.setY(p.getY() + v.getY() * dt * 500)
            p.setX(p.getX() + v.getX() * dt * 500)
        end
    }
end

function love.draw()
    love.graphics.circle("fill", player.getX(), player.getY(), 10)
    love.graphics.circle("fill", origin.getX(), origin.getY(), 10)

    love.graphics.print(text, 420, 420)
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
