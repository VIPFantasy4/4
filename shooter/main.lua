-- from [LÖVE tutorial, part 2](http://www.headchant.com/2010/12/31/love2d-%E2%80%93-tutorial-part-2-pew-pew/)

--playerImgR1 = nil
--playerImgR2 = nil
--playerImgR3 = nil
--playerImgR4 = nil

--playerImgL1 = nil
--playerImgL2 = nil
--playerImgL3 = nil
--playerImgL4 = nil

local FORTY_FOUR = 44

local WINDOW_WIDTH = 800

local SUPREME_COMBO_COMMAND = {}
SUPREME_COMBO_COMMAND.leftrightc = 'SUPREME_FUCK'
SUPREME_COMBO_COMMAND.rightleftc = 'SUPREME_FUCK'

local SUPREME_COMBO_ANIMATION = {}

local SUPREME_COMBO_BANNER = {}
SUPREME_COMBO_BANNER.SUPREME_FUCK = { '滚', '你', '妈', '的', '开', '哦', '凸' }

local LOOP_TIME = 16

local DEFAULT_ORIENTATION = 'L'

local FREAK_COEFFICIENT = .07

local X_GRAVITY = 0
local Y_GRAVITY = 3000

local JUMP_LINEAR_VELOCITY = -500

function love.load(arg)
    --if arg and arg[#arg] == "-debug" then
    --    require("mobdebug").start()
    --end

    world = love.physics.newWorld(X_GRAVITY, Y_GRAVITY)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    love.physics.setMeter(10)

    ground = {}
    ground.body = love.physics.newBody(world, 0, 465)
    ground.shape = love.physics.newRectangleShape(WINDOW_WIDTH * 1000, FORTY_FOUR)
    ground.fixture = love.physics.newFixture(ground.body, ground.shape)
    ground.fixture:setRestitution(0)
    ground.fixture:setUserData('ground')

    geezers = {}
    geezers.body = love.physics.newBody(world, 300, 0, 'dynamic')
    geezers.shape = love.physics.newRectangleShape(148, FORTY_FOUR)
    geezers.fixture = love.physics.newFixture(geezers.body, geezers.shape)
    geezers.fixture:setUserData('geezers')

    isCollided = false

    hero = {} -- new table for the hero
    hero.x = 300 -- x,y coordinates of the hero
    hero.y = 450
    hero.width = 30
    hero.height = 15
    hero.speed = 400
    hero.shots = {} -- holds our fired shots

    enemies = {}
    for i = 0, 6 do
        local enemy = {}
        enemy.width = 40
        enemy.height = 20
        enemy.x = i * (enemy.width + 60) + 80
        enemy.y = enemy.height + 100
        table.insert(enemies, enemy)
    end

    myFont = love.graphics.newFont("assets/msyh.ttf", 16)
    love.graphics.setFont(myFont)

    playerImgR1 = love.graphics.newImage('assets/geezers1_r1.png')
    playerImgR2 = love.graphics.newImage('assets/geezers2_r2.png')
    playerImgR3 = love.graphics.newImage('assets/geezers3_r3.png')
    playerImgR4 = love.graphics.newImage('assets/geezers4_r4.png')

    playerImgL1 = love.graphics.newImage('assets/geezers1_l1.png')
    playerImgL2 = love.graphics.newImage('assets/geezers2_l2.png')
    playerImgL3 = love.graphics.newImage('assets/geezers3_l3.png')
    playerImgL4 = love.graphics.newImage('assets/geezers4_l4.png')

    SUPREME_COMBO_ANIMATION.SUPREME_FUCK_R = { playerImgR1, playerImgR2, playerImgR3, playerImgR4 }
    SUPREME_COMBO_ANIMATION.SUPREME_FUCK_L = { playerImgL1, playerImgL2, playerImgL3, playerImgL4 }

    orientation = DEFAULT_ORIENTATION
    border = WINDOW_WIDTH - playerImgR1:getWidth()

    jump = false

    quit = true
    allClear = false
    allOver = false

    animation = nil
    banner = nil
    comboName = nil
    typedTime = 0
    typedCommand = ''
    order = 0
    step = 0
    performedTime = 0
    supremeCombo = false
    isPerformingCombo = false

    timeWizard = FREAK_COEFFICIENT
end

function love.quit()
    if quit then
        love.window.setTitle("We are not ready to quit yet!")
        print("We are not ready to quit yet!")
        quit = not quit
    else
        print("Thanks for playing. Please play again soon!")
        return quit
    end
    return true
end

function love.keypressed(k)
    if k == 'escape' then
        love.event.push('quit') -- Quit the game.
    end

    if k == 'up' and isCollided then
        jump = true
    end
end

function love.keyreleased(key)
    -- in v0.9.2 and earlier space is represented by the actual space character ' ', so check for both
    --print(key)
    if (key == " " or key == "space") then
        shoot()
    end
    typedCommand = typedCommand .. key
    print(typedCommand)
end

function love.update(dt)
    if allOver then
        return
    end

    if not supremeCombo then
        CheckSupremeCombo(typedCommand)
    end

    if not supremeCombo then
        world:update(dt)

        typedTime = typedTime + dt
        if typedTime > 2 then
            typedTime = 0
            typedCommand = ''
            supremeCombo = false
        end

        -- keyboard actions for our hero
        if love.keyboard.isDown("left") then
            --hero.x = hero.x < 0 and 0 or hero.x - hero.speed * dt
            local geezersX = geezers.body:getX()
            geezers.body:setX(geezersX < 0 and 0 or geezersX - hero.speed * dt)
            orientation = 'L'
        elseif love.keyboard.isDown("right") then
            --hero.x = hero.x > border and border or hero.x + hero.speed * dt
            local geezersX = geezers.body:getX()
            geezers.body:setX(geezersX > border and border or geezersX + hero.speed * dt)
            orientation = 'R'
        end
        if jump then
            geezers.body:setAwake(true)
            geezers.body:setLinearVelocity(0, JUMP_LINEAR_VELOCITY)
            isCollided = false
            jump = false
        end

        local remEnemy = {}
        local remShot = {}

        -- update the shots
        for i, v in ipairs(hero.shots) do
            -- move them up up up
            v.y = v.y - dt * 300

            -- mark shots that are not visible for removal
            if v.y < 0 then
                table.insert(remShot, i)
            end

            -- check for collision with enemies
            for ii, vv in ipairs(enemies) do
                if CheckCollision(v.x, v.y, 2, 5, vv.x, vv.y, vv.width, vv.height) then
                    -- mark that enemy for removal
                    table.insert(remEnemy, ii)
                    -- mark the shot to be removed
                    table.insert(remShot, i)
                end
            end
        end

        -- remove the marked enemies
        for i, v in ipairs(remEnemy) do
            table.remove(enemies, v)
        end

        for i, v in ipairs(remShot) do
            table.remove(hero.shots, v)
        end

        -- update those evil enemies
        for i, v in ipairs(enemies) do
            -- let them fall down slowly
            v.y = v.y + dt

            -- check for collision with ground
            if v.y > 448 then
                -- you loose!!!
                allOver = true
            end
        end

        if not next(enemies) then
            allClear = true
        end
    else
        timeWizard = timeWizard + dt
        if timeWizard > FREAK_COEFFICIENT then
            timeWizard = timeWizard - FREAK_COEFFICIENT
            order = order + 1
            local index = order % #animation
            if index ~= order then
                if index == 0 then
                    order = #animation
                    performedTime = performedTime + 1
                    if performedTime > 1 then
                        step = math.floor(performedTime / 2)
                    end
                    if performedTime == LOOP_TIME then
                        -- release all
                        animation = nil
                        banner = nil
                        comboName = nil
                        typedTime = 0
                        typedCommand = ''
                        order = 0
                        step = 0
                        performedTime = 0
                        supremeCombo = false
                        isPerformingCombo = false
                        timeWizard = FREAK_COEFFICIENT
                        -- 暂时调试
                        allClear = true
                        enemies = {}
                    end
                else
                    order = index
                end
            end
        end
    end

    require('debug/lovebird').update()
end

function love.draw()
    -- let's draw a background
    love.graphics.setColor(255, 255, 255, 255)

    if not quit then
        love.graphics.setColor(20, 200, 0, 255)
        love.graphics.print("退你麻痹", 4, 4)
    end

    if quit then
        if not allOver and not allClear and not supremeCombo then
            love.graphics.setColor(20, 200, 0, 255)
            love.graphics.print("三个月的会议记录", 4, 4)
        end
        if supremeCombo then
            love.graphics.setColor(1, 0, 0)
            love.graphics.print("超杀 —— " .. comboName, 10, 4, 0, 2, 2)
        end
    end

    -- let's draw some ground
    love.graphics.setColor(0, 255, 0, 255)
    love.graphics.rectangle("fill", ground.body:getX(), ground.body:getY(), WINDOW_WIDTH, 150)

    if not allOver then
        if not allClear or supremeCombo then
            if not supremeCombo then
                -- let's draw our hero
                love.graphics.setColor(255, 255, 255, 255)
                --love.graphics.rectangle("fill", hero.x, hero.y, hero.width, hero.height)
                local player
                if orientation == 'R' then
                    player = playerImgR1
                else
                    player = playerImgL1
                end
                love.graphics.draw(player, geezers.body:getX(), geezers.body:getY() - 80)

                -- let's draw our heros shots
                love.graphics.setColor(255, 255, 255, 255)
                for i, v in ipairs(hero.shots) do
                    love.graphics.rectangle("fill", v.x, v.y, 2, 5)
                end
            else
                -- perform supreme animation
                love.graphics.setColor(255, 255, 255, 255)
                local player = animation[order]
                --love.graphics.draw(player, hero.x, hero.y)
                love.graphics.draw(player, geezers.body:getX(), geezers.body:getY() - 80)

                -- display supreme banner
                local _, enemy = next(enemies)
                if enemy then
                    local count = 0
                    for i, v in ipairs(banner) do
                        if count >= step then
                            break
                        end
                        love.graphics.setColor(20, 200, 0, 255)
                        love.graphics.print(v, (i - 1) * 100 + 80, enemy.y - 44, 0, 3, 3)
                        count = count + 1
                    end
                end
            end

            -- let's draw our enemies
            love.graphics.setColor(0, 255, 255, 255)
            for i, v in ipairs(enemies) do
                love.graphics.rectangle("fill", v.x, v.y, v.width, v.height)
            end
        else
            love.graphics.setColor(0, 1, 0)
            love.graphics.print("ALL CLEAR!!!", 300, 100, 0, 2, 2)
            love.graphics.print("鸡场镇大傻逼", 300, 130, 0, 2, 2)
        end
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("YOU LOSE!!!", 315, 100, 0, 2, 2)
        love.graphics.print("NOOB NIGGA", 300, 130, 0, 2, 2)
    end
end

function shoot()
    if #hero.shots >= 5 then
        return
    end
    local shot = {}
    shot.x = hero.x + hero.width / 2
    shot.y = hero.y
    table.insert(hero.shots, shot)
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
function CheckCollision(ax1, ay1, aw, ah, bx1, by1, bw, bh)
    local ax2, ay2, bx2, by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
end

function CheckSupremeCombo(command)
    local len = #command
    for k, v in pairs(SUPREME_COMBO_COMMAND) do
        local _, last = string.find(command, k)
        if last == len then
            comboName = v
            animation = SUPREME_COMBO_ANIMATION[v .. '_' .. orientation]
            banner = SUPREME_COMBO_BANNER[v]
            supremeCombo = true
            break
        end
    end
end

function beginContact(a, b, collision)
    if a == ground.fixture then
        print('ground')
        isCollided = true
    end
    if b == geezers.fixture then
        print('geezers')
    end
end

function endContact(a, b, collision)

end

function preSolve(a, b, collision)

end

function postSolve(a, b, collision)

end
