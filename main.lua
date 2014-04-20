local origin, player, orbiter
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
    local speed, p = 500
    v = Vector(0, 0)
    p = Point(point.getX(), point.getY())

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

            p.setY(p.getY() + v.getY() * dt * speed)
            p.setX(p.getX() + v.getX() * dt * speed)
        end
    }
end

-- @param x and y are the birthplace of the collider
function Collider(vector, x, y, speed)
    local v = Vector(vector.getX(), vector.getY())
    local p = Point(x, y)

    return {
        getX = v.getX,
        getY = v.getY,

        update = function (dt)

            p.setY(p.getY() + v.getY() * dt * speed)
            p.setX(p.getX() + v.getX() * dt * speed)
        end,

        draw = function ()
            love.graphics.circle("fill", p.getX(), p.getY(), 10)
        end
    }
end

-- @param x, y are the initial position of the producer
-- @param amp_x, amp_y, are the amplitude of x and y as they drift
--        back and forth along their axis
function Orbiter(origin, amp_x, amp_y, x, y)
    local t, index, colliders, debounce = 0, 0, {}, false
    local origin = Point(origin.getX(), origin.getY())

    orbX = function ()
        return amp_x * math.sin(t + math.pi / 2) + x
    end

    orbY = function ()
        return amp_y * math.sin(t) + y
    end

    return {
        -- sinusoidal function on time
        -- we can adjust the excentricity by adding to the denominator
        getX = orbX,
        getY = orbY,

        update = function (dt)
            for i, collider in ipairs(colliders) do
                collider.update(dt)
            end

            t = (t + dt) % (2 * math.pi)

            -- possibly add a collider to the table
            if (t % (math.pi / 5) < 0.1) then
                if (debounce == false) then
                    debounce = true
                    colliders[index] = Collider(Vector(1, 1), orbX(), orbY(), 100)

                    index = index + 1
                end
            else
                debounce = false
            end

            -- possibly remove a collider from the table
        end,

        draw = function () 
            for i, collider in ipairs(colliders) do
                collider.draw()
            end

            love.graphics.circle("fill", orbiter.getX(), orbiter.getY(), 10)
        end
    }
end

function love.draw()
    love.graphics.circle("fill", player.getX(), player.getY(), 10)
    love.graphics.circle("fill", origin.getX(), origin.getY(), 10)

    orbiter.draw()

    love.graphics.print(text, 420, 420)
end

function love.load()
   -- image = love.graphics.newImage("cake.jpg")
   love.graphics.setNewFont(12)
   love.graphics.setColor(0,0,0)
   love.graphics.setBackgroundColor(255,255,255)

   origin  = Point(love.window.getWidth() / 2, love.window.getHeight() / 2)
   player  = Player(origin)
   orbiter = Orbiter(origin, 300, 300, origin.getX(), origin.getY())
end

function love.focus(f) gameIsPaused = not f end

function love.update(dt)
    player.update(dt)
    orbiter.update(dt)
end
