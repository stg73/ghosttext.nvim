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
    return vim.fn.strutf16len(str)
end

function M.make_request(buf,pos)
    local text = table.concat(vim.api.nvim_buf_get_lines(buf,0,-1,false),"\n")
    local start = str_to_start(table.concat(vim.api.nvim_buf_get_text(buf,0,0,pos[1] - 1,pos[2] + 1,{}),"\n"))
    return {
        text = text,
        selections = {
            { start = start, ["end"] = start }
        }
    }
end

function M.handle_request(buf,data)
    vim.api.nvim_buf_set_lines(buf,0,-1,false,vim.split(data.text,"\n"))
    if vim.api.nvim_win_get_buf(0) == vim.api.nvim_buf_get_number(buf) then
        local text = require("regex").match("^.{" .. data.selections[1].start .. "}")(data.text)
        vim.api.nvim_win_set_cursor(0,str_to_pos(text))
    end
end

function M.start(port,buf)
    http_server = sock.server("127.0.0.1",4001)
    http_server.on.data = function()
        http_server.send(http.wrap(function()
            return {
                header = {
                    ["content-type"] = "application/json",
                },
                body = vim.json.encode({
                    WebSocketPort = port,
                    ProtocolVersion = 1,
                }),
            }
        end)())
        http_server.close()
    end

    ws_server = sock.server("127.0.0.1",port)
    ws_server.on.open = function()
        ws_server.state.websocket_is_open = false
    end
    ws_server.on.data = function(data)
        if ws_server.state.websocket_is_open then
            ws.wrap(vim.schedule_wrap(function(request)
                ws_server.state.hoge = true
                M.handle_request(buf,vim.json.decode(request))
                ws_server.state.hoge = false
            end))(data)
        else
            ws_server.send(http.wrap(ws.handshake)(data))
            ws_server.state.websocket_is_open = true
        end
    end

    vim.api.nvim_buf_attach(buf,true,{
        on_lines = function()
            if ws_server.state.websocket_is_open and not ws_server.state.hoge then
                ws_server.send(ws.wrap(function()
                    local request = M.make_request(buf,vim.api.nvim_win_get_cursor(0))
                    return vim.json.encode(request)
                end)())
            end
        end
    })
end

return M
