
local lexer = {extensions = {"lua"}, keywords = {}}

lexer.keywords[1] = [[
    and break do else elseif end false for function if
    in local nil not or repeat return then true until while
]]

lexer.keywords[2] = [[
    _VERSION assert collectgarbage dofile error gcinfo loadfile loadstring
    print rawget rawset require tonumber tostring type unpack
]]

lexer.keywords[3] = [[
    _G getfenv getmetatable ipairs loadlib next pairs pcall
    rawequal setfenv setmetatable xpcall
    string table math coroutine io os debug
    load module select
]]

lexer.keywords[4] = [[
    string.byte string.char string.dump string.find string.len
    string.lower string.rep string.sub string.upper string.format string.gfind string.gsub
    table.concat table.foreach table.foreachi table.getn table.sort table.insert table.remove table.setn
    math.abs math.acos math.asin math.atan math.atan2 math.ceil math.cos math.deg math.exp
    math.floor math.frexp math.ldexp math.log math.log10 math.max math.min math.mod
    math.pi math.pow math.rad math.random math.randomseed math.sin math.sqrt math.tan
    string.gmatch string.match string.reverse table.maxn
    math.cosh math.fmod math.modf math.sinh math.tanh math.huge
]]

lexer.keywords[5] = [[
    coroutine.create coroutine.resume coroutine.status
    coroutine.wrap coroutine.yield
    io.close io.flush io.input io.lines io.open io.output io.read io.tmpfile io.type io.write
    io.stdin io.stdout io.stderr
    os.clock os.date os.difftime os.execute os.exit os.getenv os.remove os.rename
    os.setlocale os.time os.tmpname
    coroutine.running package.cpath package.loaded package.loadlib package.path
    package.preload package.seeall io.popen
    debug.debug debug.getfenv debug.gethook debug.getinfo debug.getlocal
    debug.getmetatable debug.getregistry debug.getupvalue debug.setfenv
    debug.sethook debug.setlocal debug.setmetatable debug.setupvalue debug.traceback
]]

return lexer
