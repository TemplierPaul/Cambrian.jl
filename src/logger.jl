import Logging: Info, Warn, shouldlog, min_enabled_level, catch_exceptions, handle_message

struct DarwinLogger <: AbstractLogger
    stream::IO
    min_level::LogLevel
    message_limits::Dict{Any,Int}
end
DarwinLogger(stream::IO=stderr, level=Info) = DarwinLogger(
    stream, level, Dict{Any,Int}())

shouldlog(logger::DarwinLogger, level, _module, group, id) =
    get(logger.message_limits, id, 1) > 0

min_enabled_level(logger::DarwinLogger) = logger.min_level

catch_exceptions(logger::DarwinLogger) = false

function handle_message(logger::DarwinLogger, level, message, _module, group, id,
                        filepath, line; maxlog=nothing, kwargs...)
    if maxlog != nothing && maxlog isa Integer
        remaining = get!(logger.message_limits, id, maxlog)
        logger.message_limits[id] = remaining - 1
        remaining > 0 || return
    end
    buf = IOBuffer()
    iob = IOContext(buf, logger.stream)
    levelstr = level == Warn ? "Warning" : string(level)
    msglines = split(chomp(string(message)), '\n')
    println(iob, Dates.now(), " Darwin ", levelstr, " ", msglines[1])
    for i in 2:length(msglines)
        println(iob, "│ ", msglines[i])
    end
    for (key, val) in kwargs
        println(iob, "│   ", key, " = ", val)
    end
    write(logger.stream, take!(buf))
    nothing
end
