local BasePlugin = require "kong.plugins.base_plugin"
local responses = require "kong.tools.responses"
local cjson = require "cjson.safe"

local ProxyCacheHandler = BasePlugin:extend()

function ProxyCacheHandler:new()
  ProxyCacheHandler.super.new(self, "proxy-cache")
end

-- Add cache hit/miss headers
function ProxyCacheHandler:header_filter(conf)
  ProxyCacheHandler.super.header_filter(self)

  local cache_status = ngx.var.upstream_cache_status or "MISS"
  ngx.header["X-Cache-Status"] = cache_status
end

-- Optionally bypass caching for certain requests
function ProxyCacheHandler:access(conf)
  ProxyCacheHandler.super.access(self)

  local bypass_cache = ngx.req.get_headers()["X-Bypass-Cache"]
  if bypass_cache == "true" then
    ngx.ctx.bypass_cache = true
  end
end

-- Custom log for debug
function ProxyCacheHandler:log(conf)
  ProxyCacheHandler.super.log(self)

  local req = {
    method = ngx.req.get_method(),
    uri = ngx.var.request_uri,
    cache_status = ngx.var.upstream_cache_status,
    bypassed = ngx.ctx.bypass_cache or false
  }

  ngx.log(ngx.INFO, "[proxy-cache] Request info: ", cjson.encode(req))
end

return ProxyCacheHandler
