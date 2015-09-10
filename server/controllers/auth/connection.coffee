CONFIG = require 'config'
{ cookieMaxAge } = CONFIG
__ = CONFIG.root
_ = __.require 'builders', 'utils'
error_ = __.require 'lib', 'error/error'
passport_ = __.require 'lib', 'passport/passport'
setLoggedInCookie = require './lib/set_logged_in_cookie'

exports.signup = (req, res)->
  {strategy} = req.body
  next = LoggedIn(res)
  switch strategy
    when 'local' then passport_.authenticate.localSignup(req, res, next)
    # browserid login handles both login and signup
    else error_.bundle res, "unknown signup strategy: #{strategy}", 400

exports.login = (req, res)->
  {strategy} = req.body
  next = LoggedIn(res)
  switch strategy
    when 'local' then passport_.authenticate.localLogin(req, res, next)
    when 'browserid' then passport_.authenticate.browserid(req, res, next)
    else error_.bundle res, "unknown login strategy: #{strategy}", 400

LoggedIn = (res)->
  loggedIn = ->
    setLoggedInCookie res
    res.send 'ok'

exports.logout = (req, res, next) ->
  res.clearCookie 'loggedIn'
  req.logout()
  res.redirect '/'