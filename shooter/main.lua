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

local JUMP_LINEAR_VELOCITY = -600
local STUNT_LINEAR_VELOCITY = -300
local HURT_LINEAR_VELOCITY = -200
local SHOOT_LINEAR_VELOCITY = -100

local JUMP_ANIMATION = {}
local STUNT_ANIMATION = {}

local ANIMATION = {}
ANIMATION.JUMP = JUMP_ANIMATION
ANIMATION.STUNT = STUNT_ANIMATION

function love.load(arg)
    --if arg and arg[#arg] == "-debug" then
    --    require("mobdebug").start()
    --end

    world = love.physics.newWorld(X_GRAVITY, Y_GRAVITY)
    world:setCallbacks(beginContact, endContact, preSolve, postSolve)
    love.physics.setMeter(10)

    ground = {}
    ground.body = love.physics.newBody(world, WINDOW_WIDTH * 1000 / 2, 600 - FORTY_FOUR / 2)
    ground.shape = love.physics.newRectangleShape(WINDOW_WIDTH * 1000, FORTY_FOUR)
    ground.fixture = love.physics.newFixture(ground.body, ground.shape)
    ground.fixture:setRestitution(0)
    ground.fixture:setUserData('ground')

    geezers = {}
    geezers.body = love.physics.newBody(world, 300, 0, 'dynamic')
    --geezers.shape = love.physics.newRectangleShape(FORTY_FOUR, FORTY_FOUR * 1.6)
    geezers.shape = love.physics.newCircleShape(FORTY_FOUR / 2)
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
        enemy.body = love.physics.newBody(world, i * (40 + 60) + 80 + 40 / 2, 20 + 100 + 20 / 2)
        enemy.shape = love.physics.newRectangleShape(40, 20)
        enemy.fixture = love.physics.newFixture(enemy.body, enemy.shape)
        enemy.fixture:setRestitution(0)
        enemy.fixture:setUserData('enemy')
        table.insert(enemies, enemy)
    end

    myFont = love.graphics.newFont("assets/msyh.ttf", 16)
    love.graphics.setFont(myFont)

    bloodBg = love.graphics.newImage('assets/blood_bg.png')

    playerImgR1 = love.graphics.newImage('assets/geezers1_r1.png')
    playerImgR2 = love.graphics.newImage('assets/geezers2_r2.png')
    playerImgR3 = love.graphics.newImage('assets/geezers3_r3.png')
    playerImgR4 = love.graphics.newImage('assets/geezers4_r4.png')

    playerImgL1 = love.graphics.newImage('assets/geezers1_l1.png')
    playerImgL2 = love.graphics.newImage('assets/geezers2_l2.png')
    playerImgL3 = love.graphics.newImage('assets/geezers3_l3.png')
    playerImgL4 = love.graphics.newImage('assets/geezers4_l4.png')

    playerImgR1Jump2 = love.graphics.newImage('assets/geezers1_r1_2.png')
    playerImgR1Jump3 = love.graphics.newImage('assets/geezers1_r1_3.png')
    playerImgR1Jump4 = love.graphics.newImage('assets/geezers1_r1_4.png')

    playerImgL1Jump2 = love.graphics.newImage('assets/geezers1_l1_2.png')
    playerImgL1Jump3 = love.graphics.newImage('assets/geezers1_l1_3.png')
    playerImgL1Jump4 = love.graphics.newImage('assets/geezers1_l1_4.png')

    playerImgR2Stunt1 = love.graphics.newImage('assets/geezers2_r2_stunt1.png')
    playerImgR3Stunt2 = love.graphics.newImage('assets/geezers3_r3_stunt2.png')

    playerImgL2Stunt1 = love.graphics.newImage('assets/geezers2_l2_stunt1.png')
    playerImgL3Stunt2 = love.graphics.newImage('assets/geezers3_l3_stunt2.png')

    shotImg = love.graphics.newImage('assets/shot.png')

    SUPREME_COMBO_ANIMATION.SUPREME_FUCK_R = { playerImgR1, playerImgR2, playerImgR3, playerImgR4 }
    SUPREME_COMBO_ANIMATION.SUPREME_FUCK_L = { playerImgL1, playerImgL2, playerImgL3, playerImgL4 }

    JUMP_ANIMATION.JUMP_R = { playerImgR1Jump2, playerImgR1Jump3, playerImgR1Jump4, playerImgR1 }
    JUMP_ANIMATION.JUMP_L = { playerImgL1Jump2, playerImgL1Jump3, playerImgL1Jump4, playerImgL1 }
    STUNT_ANIMATION.STUNT_R = { playerImgR1Jump4, playerImgR2Stunt1, playerImgR3Stunt2 }
    STUNT_ANIMATION.STUNT_L = { playerImgL1Jump4, playerImgL2Stunt1, playerImgL3Stunt2 }

    orientation = DEFAULT_ORIENTATION
    xBorder = (playerImgR1:getWidth() - FORTY_FOUR) / 2
    yBorder = WINDOW_WIDTH - (playerImgR1:getWidth() + FORTY_FOUR) / 2

    jump = false
    stunt = 1

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
    isPerformingAnimation = false

    timeWizard = FREAK_COEFFICIENT

    hurt = nil
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

    if k == 'up' and isCollided and not isPerformingAnimation then
        jump = true
    end

    if k == 'up' and stunt == 1 then
        stunt = 0
    end

    if k == 'down' then
        isPerformingAnimation = false
    end
end

function love.keyreleased(key)
    -- in v0.9.2 and earlier space is represented by the actual space character ' ', so check for both
    --print(key)
    if (key == " " or key == "space") then
        shoot()
    end
    typedCommand = typedCommand .. key
    --print(typedCommand)
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

        if not hurt then
            -- keyboard actions for our hero
            if love.keyboard.isDown("left") then
                --hero.x = hero.x < 0 and 0 or hero.x - hero.speed * dt
                local geezersX = geezers.body:getX()
                geezers.body:setX(geezersX < xBorder and xBorder or geezersX - hero.speed * dt)
                orientation = 'L'
            elseif love.keyboard.isDown("right") then
                --hero.x = hero.x > yBorder and yBorder or hero.x + hero.speed * dt
                local geezersX = geezers.body:getX()
                geezers.body:setX(geezersX > yBorder and yBorder or geezersX + hero.speed * dt)
                orientation = 'R'
            end
        else
            if hurt == 1 then
                geezers.body:setLinearVelocity(0, HURT_LINEAR_VELOCITY)

                hurt = 0
            end
        end

        if jump then
            geezers.body:setAwake(true)
            geezers.body:setLinearVelocity(0, JUMP_LINEAR_VELOCITY)

            comboName = 'JUMP'
            order = 0
            isPerformingAnimation = true
            isCollided = false
            stunt = 1
            jump = false
        end
        if stunt == 0 then
            geezers.body:setLinearVelocity(0, STUNT_LINEAR_VELOCITY)

            comboName = 'STUNT'
            order = 0
            isPerformingAnimation = true
            stunt = -1
        end

        if isPerformingAnimation then
            timeWizard = timeWizard + dt
            if timeWizard > FREAK_COEFFICIENT then
                timeWizard = timeWizard - FREAK_COEFFICIENT
                order = order + 1
            end
        else
            comboName = nil
            order = 0
            timeWizard = FREAK_COEFFICIENT
        end

        local remEnemy = {}
        local remShot = {}

        -- update the shots
        for i, shot in ipairs(hero.shots) do
            -- move them up up up
            shot.body:setAwake(true)
            shot.body:setLinearVelocity(0, SHOOT_LINEAR_VELOCITY)
            --shot.y = shot.y - dt * 300

            -- mark shots that are not visible for removal
            local _, _, _, _, _, y = shot.body:getWorldPoints(shot.shape:getPoints())
            if y < 0 then
                table.insert(remShot, i)
            end

            -- check for collision with enemies
            for ii, enemy in ipairs(enemies) do
                if shot.body:isTouching(enemy.body) then
                    --if CheckCollision(shot.x, shot.y, 2, 5, enemy.x, enemy.y, enemy.width, enemy.height) then
                    -- mark that enemy for removal
                    table.insert(remEnemy, ii)
                    -- mark the shot to be removed
                    table.insert(remShot, i)
                end
            end
        end

        -- remove the marked enemies
        for _, v in ipairs(remEnemy) do
            v.fixture:release()
            v.shape:release()
            v.body:release()
        end

        for _, v in ipairs(remShot) do
            v.fixture:release()
            v.shape:release()
            v.body:release()
        end

        -- update those evil enemies
        for i, enemy in ipairs(enemies) do
            -- let them fall down slowly
            --enemy.body:setAwake(true)
            enemy.body:setLinearVelocity(0, dt)
            --enemy.y = enemy.y + dt

            -- check for collision with ground
            if enemy.body:isTouching(ground.body) then
                --if enemy.y > 448 then
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
                        isPerformingAnimation = false
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
    love.graphics.polygon("fill", ground.body:getWorldPoints(ground.shape:getPoints()))

    -- hurt notice
    love.graphics.setColor(1, 0, 0)
    love.graphics.print('头着地会掉血', FORTY_FOUR, FORTY_FOUR, 0, 7.4, 6)

    if not allOver then
        if not allClear or supremeCombo then
            if not supremeCombo then
                -- let's draw our hero
                love.graphics.setColor(255, 255, 255, 255)
                if not isPerformingAnimation then
                    --love.graphics.rectangle("fill", hero.x, hero.y, hero.width, hero.height)
                    local player
                    if orientation == 'R' then
                        player = playerImgR1
                    else
                        player = playerImgL1
                    end
                    love.graphics.draw(player, geezers.body:getX() - player:getWidth() / 2, geezers.body:getY() + FORTY_FOUR - player:getHeight() + 33)
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.circle("fill", geezers.body:getX(), geezers.body:getY(), geezers.shape:getRadius())
                else
                    local animation = ANIMATION[comboName][comboName .. '_' .. orientation]
                    local player
                    if order < #animation * 2 then
                        local index = order % #animation
                        index = index == 0 and #animation or index
                        player = animation[index]
                    else
                        player = animation[#animation]
                    end
                    love.graphics.draw(player, geezers.body:getX() - player:getWidth() / 2, geezers.body:getY() + FORTY_FOUR - player:getHeight() + 33)
                    love.graphics.setColor(1, 0, 0)
                    love.graphics.circle("fill", geezers.body:getX(), geezers.body:getY(), geezers.shape:getRadius())
                end

                -- let's draw our heros shots
                love.graphics.setColor(255, 255, 255, 255)
                for _, shot in ipairs(hero.shots) do
                    love.graphics.draw(shotImg, shot.body:getX() - shotImg:getWidth() / 2, shot.body:getY() - shotImg:getHeight() / 2)
                    --love.graphics.rectangle("fill", shot.x, shot.y, FORTY_FOUR, FORTY_FOUR)
                end
            else
                -- perform supreme animation
                love.graphics.setColor(255, 255, 255, 255)
                local player = animation[order]
                --love.graphics.draw(player, hero.x, hero.y)
                love.graphics.draw(player, geezers.body:getX() - (player:getWidth() - FORTY_FOUR) / 2, geezers.body:getY() - 80)

                -- display supreme banner
                --local _, enemy = next(enemies)
                --if enemy then
                --    local count = 0
                --    for i, v in ipairs(banner) do
                --        if count >= step then
                --            break
                --        end
                --        love.graphics.setColor(20, 200, 0, 255)
                --        love.graphics.print(v, (i - 1) * 100 + 80, enemy.y - 44, 0, 3, 3)
                --        count = count + 1
                --    end
                --end
            end

            -- let's draw our enemies
            love.graphics.setColor(0, 255, 255, 255)
            for _, enemy in ipairs(enemies) do
                love.graphics.polygon("fill", enemy.body:getWorldPoints(enemy.shape:getPoints()))
                --love.graphics.rectangle("fill", enemy.x, enemy.y, enemy.width, enemy.height)
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

    if hurt == 0 then
        love.graphics.setColor(255, 255, 255, 255)
        love.graphics.draw(bloodBg, 0, 0)
    end
end

function shoot()
    --if #hero.shots >= 5 then
    --    return
    --end
    local shot = createShot(geezers.body:getX(), geezers.body:getY() - FORTY_FOUR, os.time())
    --local shot = {}
    --shot.x, shot.y = geezers.body:getWorldPoints(geezers.shape:getPoints())
    table.insert(hero.shots, shot)
end

function createShot(x, y, id)
    local shot = {}
    shot.body = love.physics.newBody(world, x, y)
    shot.shape = love.physics.newRectangleShape(4, 4)
    shot.fixture = love.physics.newFixture(shot.body, shot.shape)
    shot.fixture:setRestitution(0)
    shot.fixture:setUserData('shot_' .. id)
    return shot
end

-- Collision detection function.
-- Checks if a and b overlap.
-- w and h mean width and height.
--function CheckCollision(ax1, ay1, aw, ah, bx1, by1, bw, bh)
--    local ax2, ay2, bx2, by2 = ax1 + aw, ay1 + ah, bx1 + bw, by1 + bh
--    return ax1 < bx2 and ax2 > bx1 and ay1 < by2 and ay2 > by1
--end

function CheckSupremeCombo(command)
    local len = #command
    for k, v in pairs(SUPREME_COMBO_COMMAND) do
        local _, last = string.find(command, k)
        if last == len then
            comboName = v
            animation = SUPREME_COMBO_ANIMATION[v .. '_' .. orientation]
            banner = SUPREME_COMBO_BANNER[v]
            order = 0
            timeWizard = FREAK_COEFFICIENT
            supremeCombo = true
            break
        end
    end
end

function beginContact(a, b, collision)
    if a == ground.fixture then
        --print('ground')
        if isPerformingAnimation and stunt == -1 then
            hurt = 1
        else
            isCollided = true
            stunt = nil
            hurt = nil
        end
        isPerformingAnimation = false
    end
    if b == geezers.fixture then
        print('geezers')
        geezers.body:setAwake(false)
    end
end

function endContact(a, b, collision)

end

function preSolve(a, b, collision)

end

function postSolve(a, b, collision)

end
