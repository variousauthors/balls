require "vector"

local Collision = function (callback)
    local index, collisions = 1, {}

    local clear = function ()
        collisions = {}
        index = 1
    end

    return {
        -- adds a collision to be handled at update
        add = function (collision)
            collisions[index] = collision
            index = index + 1
        end,

        -- clears all collisions
        clear = clear,

        resolve = function ()
            for i, collision in ipairs(collisions) do
                callback(collision)
            end

            clear()
        end
    }
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

    local collisions = Collision(function (collision)
        power = power - collision.damage
    end)

    return {
        getX = p.getX,
        getY = p.getY,
        getPower = function ()
            return power
        end,

        setPower = function (p)
            power = p
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
local Collider = function (vector, x, y, speed, color, size, sfx)
    local v, active, visible = Vector(vector.getX(), vector.getY()), true, false
    local p = Point(x, y)
    local was_off_screen = false

    local setActive = function (bool)
        active = bool
    end

    local setVisible = function (bool)
        visible = bool
    end
    
    local isVisible = function ()
        return visible;
    end

    local isOffScreen = function ()
        return p.getX() > love.window.getWidth()
            or p.getX() < 0
            or p.getY() > love.window.getHeight()
            or p.getY() < 0
    end

    return {
        getX = p.getX,
        getY = p.getY,

        setActive = setActive,

        isActive = function ()
            return active
        end,

        setVisible = setVisible,
        isVisible  = isVisible,

        isOffScreen = isOffScreen,

        update = function (dt, player)
            local to_player = Vector(p.getX() - player.getX(), p.getY() - player.getY())

            if (to_player.length() < size) then
                if (sfx) then
                    love.audio.play(sfx)
                end
                player.addCollision({ damage = size })
                setActive(false)
            end

            local is_off_screen = isOffScreen()

            -- determine if the collider just entered the screen
            if (not is_off_screen and was_off_screen) then
                setVisible(true)
            end

            was_off_screen = isOffScreen()

            p.setY(p.getY() + v.getY() * dt * speed)
            p.setX(p.getX() + v.getX() * dt * speed)
        end,

        draw = function ()
            if (isVisible()) then
                love.graphics.setColor(color)
                love.graphics.circle("fill", p.getX(), p.getY(), size)
            end
        end
    }
end

-- @param x, y are the initial position of the producer
-- @param period the number of radians between launching a collider
-- @param amp_x, amp_y, are the amplitude of x and y as they drift
--        back and forth along their axis
local Orbiter = function (origin, amp_x, amp_y, period, speed, color, size, sfx)
    local t, index, colliders, debounce = 0, 0, {}, false
    local origin = Point(origin.getX(), origin.getY())

    local orbX = function ()
        debug = amp_x
        return amp_x * math.sin(t + math.pi / 2) + origin.getX()
    end

    local orbY = function ()
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

                    if (collider.isVisible() and collider.isOffScreen()) then
                        colliders[i].setActive(false)
                    else
                        collider.update(dt, player)
                    end
                end
            end

            t = (t + dt) % (2 * math.pi)

            -- possibly add a collider to the table
            if (t % period < 0.1) then
                if (debounce == false) then
                    debounce = true

                    local dx, dy = orbX() - player.getX(), orbY() - player.getY()
                    local v      = Vector(-dx, -dy)

                    colliders[index] = Collider(v.to_unit(), orbX(), orbY(), speed, color, size, sfx)

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

            -- we don't actually draw the orbiter
            love.graphics.circle("fill", orbX(), orbY(), 10)
        end
    }
end

Entities = {
    Player   = Player,
    Collider = Collider,
    Orbiter  = Orbiter,
}
