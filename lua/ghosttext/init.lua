local M = {}

local ws = require("websocket")
local http = require("http")
local sock = require("socket")

local function str_to_pos(str)
    local number_of_newline = string.len(string.gsub(str,"[^\n]",""))
    local number_of_chars_after_newline = string.len(string.match(str,"[^\n]*$"))
    return { number_of_newline + 1, number_of_chars_after_newline }
end

local function str_to_start(str)
    return (vim.str_utfindex(str,"utf-16",string.len(str)))
end

local function make_request(buf,pos)
    local text = table.concat(vim.api.nvim_buf_get_lines(buf,0,-1,false),"\n")
    local start = str_to_start(table.concat(vim.api.nvim_buf_get_text(buf,0,0,pos[1] - 1,pos[2] + 1,{}),"\n"))
    return {
        text = text,
        selections = {
            { start = start, ["end"] = start }
        }
    }
end

local function handle_request(buf,data)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,vim.split(data.text,"\n"))
    if vim.api.nvim_win_get_buf(0) == vim.api.nvim_buf_get_number(buf) then
        local text = string.sub(data.text,1,vim.str_byteindex(data.text,"utf-16",data.selections[1].start))
        vim.api.nvim_win_set_cursor(0,str_to_pos(text))
    end
end

function M.start_http_server(opts)
    local http_server = sock.server("127.0.0.1",opts.http)
    local websocket = opts.websocket
    http_server.on.data = function(data)
        local response = http.wrap(function(request)
            if request.path and request.path ~= "/" then
                websocket = tonumber((string.gsub(request.path,"/","")))
            end

            return {
                header = {
                    ["content-type"] = "application/json",
                },
                body = vim.json.encode({
                    WebSocketPort = websocket,
                    ProtocolVersion = 1,
                }),
            }
        end)(data)
        http_server.send(response)
        http_server.close()
    end
end

function M.start_websocket_server(opts)
    local ws_server = require("socket.websocket").server(sock.server("127.0.0.1",opts.websocket))
    local proccessing_request
    ws_server.on.data = vim.schedule_wrap(function(request)
        proccessing_request = true
        handle_request(opts.buf,vim.json.decode(request))
        proccessing_request = false
    end)

    vim.api.nvim_buf_attach(opts.buf,true,{
        on_lines = function()
            if not proccessing_request then
                local request = make_request(opts.buf,vim.api.nvim_win_get_cursor(0))
                ws_server.send(vim.json.encode(request))
            end
        end
    })
end

function M.request_focus(opts)
    local http_server_is_running = sock.can_connect("127.0.0.1",opts.http)
    if not http_server_is_running then
        M.start_http_server(opts)
        return
    end

    local client = sock.client("127.0.0.1",opts.http)
    client.on.open = function()
        client.send(http.wrap(function()
            return {
                method = "GET",
                path = "/" .. opts.websocket,
                header = {
                    host = "127.0.0.1:" .. opts.http,
                },
            }
        end)())
    end
end

function M.start(opts)
    opts = opts or {}
    opts.buf = opts.buf or (function()
        local buf = vim.api.nvim_create_buf(false,true)
        vim.api.nvim_buf_set_name(buf,"[ghosttext]")
        return buf
    end)()
    opts.websocket = opts.websocket or sock.get_available_port()
    opts.http = opts.http or 4001

    M.start_websocket_server(opts)
    M.request_focus(opts)

    vim.api.nvim_create_autocmd("FocusGained",{
        group = vim.api.nvim_create_augroup("ghosttext",{}),
        callback = function()
            M.request_focus(opts)
        end,
    })
end

return M
