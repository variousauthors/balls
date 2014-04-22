require "vector"

local origin, player, orbiter
local debug   = "nothing"
local status  = "happy"
local count = 0

function love.draw()
    love.graphics.circle("fill", player.getX(), player.getY(), 10)
    love.graphics.circle("fill", origin.getX(), origin.getY(), 10)

    orbiter.draw()

    love.graphics.print(player.getPower(), 420, 420)
    love.graphics.print(debug, 220, 220)
    love.graphics.print(status, 320, 320)
end

function love.load()
   -- image = love.graphics.newImage("cake.jpg")
   love.graphics.setNewFont(12)
   love.graphics.setColor(0,0,0)
   love.graphics.setBackgroundColor(255,255,255)

   origin  = Point(love.window.getWidth() / 2, love.window.getHeight() / 2)
   player  = Entities.Player(origin)
   orbiter = Entities.Orbiter(origin, 300, 300)
end

function love.focus(f) gameIsPaused = not f end

function love.update(dt)
    orbiter.update(dt, player)
    player.update(dt)
end

local Player = function (point)
    local speed, power, p = 500, 100
    v = Vector(0, 0)
    p = Point(point.getX(), point.getY())

    slowDown = function (dt, get, set)
        if (get() == 0) then
        elseif (get() > 0) then
            set(math.max(get() - 1 * dt, 0))
        else
            set(math.min(get() + 1 * dt, 0))
        end
    end

    local collisions = (function (callback) 
        local index, collisions = 1, {}

        local clear = function ()
            collisions = {}
            index = 1
        end

        return {
            -- adds a collision to be handled at update
            add = function () 
                collisions[index] = true
                index = index + 1
            end,

            -- clears all collisions
            clear = clear,

            resolve = function ()
                for i, collision in ipairs(collisions) do
                    callback()
                end

                clear()
            end
        }
    end)(function () 
        power = power - 10
    end)

    return {
        getX = p.getX,
        getY = p.getY,
        getPower = function ()
            return power
        end,

        addCollision = collisions.add,

        update = function (dt)
            local is_moving

            is_moving    = love.keyboard.isDown("down", "up", "right", "left")

            if (is_moving) then
                if love.keyboard.isDown("right") then
                    v.setX(math.min(v.getX() + 1 * dt, 1))
                elseif love.keyboard.isDown("left") then
                    v.setX(math.max(v.getX() - 1 * dt, -1))
                else
                    slowDown(dt, v.getX, v.setX)
                end

                if love.keyboard.isDown("down") then
                    v.setY(math.min(v.getY() + 1 * dt, 1))
                elseif love.keyboard.isDown("up") then
                    v.setY(math.max(v.getY() - 1 * dt, -1))
                else
                    slowDown(dt, v.getY, v.setY)
                end
            else
                slowDown(dt, v.getX, v.setX)
                slowDown(dt, v.getY, v.setY)
            end

            -- TODO diagonal movement needs to be sqrt(2) times harder

            p.setY(p.getY() + v.getY() * dt * speed)
            p.setX(p.getX() + v.getX() * dt * speed)

            collisions.resolve()
        end
    }
end

-- @param x and y are the birthplace of the collider
local Collider = function (vector, x, y, speed)
    local v, active = Vector(vector.getX(), vector.getY()), true
    local p = Point(x, y)

    local setActive = function (bool)
        active = bool
    end

    return {
        getX = p.getX,
        getY = p.getY,

        setActive = setActive,

        isActive = function ()
            return active
        end,

        update = function (dt, player)
            local to_player = Vector(p.getX() - player.getX(), p.getY() - player.getY())

            if (to_player.length() < 10) then
                player.addCollision()
                setActive(false)
            end

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
local Orbiter = function (origin, amp_x, amp_y)
    local t, index, colliders, debounce = 0, 0, {}, false
    local origin = Point(origin.getX(), origin.getY())

    orbX = function ()
        return amp_x * math.sin(t + math.pi / 2) + origin.getX()
    end

    orbY = function ()
        return amp_y * math.sin(t) + origin.getY()
    end

    return {
        -- sinusoidal function on time
        -- we can adjust the excentricity by adding to the denominator
        getX = orbX,
        getY = orbY,

        update = function (dt, player)
            for i, collider in ipairs(colliders) do
                if (collider.isActive()) then

                    if (collider.getX() > love.window.getWidth() 
                        or collider.getX() < 0
                        or collider.getY() > love.window.getHeight()
                        or collider.getY() < 0) then

                        colliders[i].setActive(false)
                    else
                        collider.update(dt, player)
                    end
                end
            end

            t = (t + dt) % (2 * math.pi)

            -- possibly add a collider to the table
            if (t % (math.pi / 5) < 0.1) then
                if (debounce == false) then
                    debounce = true

                    local dx, dy = orbX() - player.getX(), orbY() - player.getY()
                    local v      = Vector(-dx, -dy)

                    colliders[index] = Collider(v.to_unit(), orbX(), orbY(), 100)

                    index = index + 1
                end
            else
                debounce = false
            end

            -- possibly remove a collider from the table
            -- if its distance from origin exceeds the amp_x/amp_y
        end,

        draw = function ()
            for i, collider in ipairs(colliders) do
                if (collider.isActive()) then
                    collider.draw()
                end
            end

            love.graphics.circle("fill", orbX(), orbY(), 10)
        end
    }
end

Entities = {
    Player   = Player,
    Collider = Collider,
    Orbiter  = Orbiter,
}
