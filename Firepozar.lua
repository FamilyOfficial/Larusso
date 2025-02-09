script_author('@zeka955')

local sampev = require("samp.events")
local effil = require("effil")
local encoding = require("encoding")
encoding.default = 'CP1251'
u8 = encoding.UTF8

chat_id = '-4622362493'  -- ID чата юзера
token = '7799196233:AAGGLSxdMPc3kFg4Ryn4kGsDizyI79TvRss'  -- Токен бота

local lastNotificationTime = 0  -- Время последнего уведомления
local notificationCooldown = 30  -- Задержка в секундах между уведомлениями
local notificationSent = {}  -- Таблица для хранения уже отправленных уведомлений
local scriptUpdated = false  -- Флаг, что скрипт был обновлён

local updateURL = "https://zeka12394.github.io/Testj/Firepozar.lua" -- Ссылка на актуальный скрипт
local scriptPath = thisScript().path  -- Автоматическое определение пути скрипта
local checkInterval = 60  -- Интервал проверки обновлений (10 минут)

-- Функция для отправки уведомления в Telegram
function sendTelegramNotification(msg)
    msg = msg:gsub('{......}', '')  -- Убираем цвета
    msg = u8:encode(msg, 'CP1251')  -- Кодируем строку
    async_http_request('https://api.telegram.org/bot' .. token .. '/sendMessage?chat_id=' .. chat_id .. '&text=' .. msg, '', function(result) end)
end

-- Проверка сообщений в чате (зеленый текст в рации)
function sampev.onServerMessage(color, text)
    local currentTime = os.time()

    if color == 0x00FF00 and text:lower():find("степени") then
        if currentTime - lastNotificationTime >= notificationCooldown then
            sendTelegramNotification('ЗАХОДИ БЫСТРЕЙ В ИГРУ, ПОЖАР ПОШЁЛ!')
            lastNotificationTime = currentTime
        end
    end
end

-- Проверка времени для уведомления за 5 минут до пожара
function checkFireAlert()
    local currentTime = os.date("*t")
    local fireTimes = {5, 25, 45}

    for _, fireMinute in ipairs(fireTimes) do
        if currentTime.min == (fireMinute - 5) and not notificationSent[currentTime.hour .. ":" .. fireMinute] then
            sendTelegramNotification(string.format("ЗАХОДИ БЫСТРЕЙ В ИГРУ! Через 5 минут пожар в %02d:%02d!", currentTime.hour, fireMinute))
            notificationSent[currentTime.hour .. ":" .. fireMinute] = true
        end
    end
end

-- Функция автообновления с автоматическим перезапуском
function downloadAndUpdate()
    local https = require("ssl.https")
    local body, code = https.request(updateURL)

    if code == 200 and body then
        local file = io.open(scriptPath, "r")
        local currentScript = file and file:read("*all") or ""
        if file then file:close() end

        if body ~= currentScript then
            local newFile = io.open(scriptPath, "w")
            if newFile then
                newFile:write(body)
                newFile:close()
                scriptUpdated = true
            end
        end
    end
end

-- Обратный отсчёт перед перезапуском
function restartScript()
    sampAddChatMessage("{FF0000}[AutoUpdate] Вышло обновление! Через 5 секунд будет перезагрузка...", -1)
    wait(1000)
    for i = 5, 1, -1 do
        sampAddChatMessage("{FFFF00}" .. i, -1)
        wait(1000)
    end
    sampAddChatMessage("{FF0000}Перезагрузка!", -1)
    thisScript():reload()
end

function main()
    while not isSampAvailable() do wait(0) end

    -- Проверяем, нужно ли перезапустить скрипт после обновления
    if scriptUpdated then
        lua_thread.create(restartScript)
    end

    while true do
        checkFireAlert()  -- Проверяем, нужно ли отправить уведомление за 5 минут до пожара
        downloadAndUpdate()  -- Проверяем обновления скрипта
        wait(checkInterval)  -- Ждём 10 минут перед следующей проверкой
    end
end
