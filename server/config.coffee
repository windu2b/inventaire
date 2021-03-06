CONFIG = require 'config'
__ = require('config').universalPath
_ = __.require 'builders', 'utils'

americano = require 'americano'

auth = require './middlewares/auth'
security = require './middlewares/security'
routes = require './middlewares/routes'
lang = require './middlewares/lang'
statics = require './middlewares/statics'
cache = require './middlewares/cache'
logger = require './middlewares/logger'
content = require './middlewares/content'

module.exports =
  common: [
    americano.bodyParser()
    content.recoverValidJson
    americano.methodOverride()
    americano.errorHandler
      dumpExceptions: true
      showStack: true

    logger.beforeStatic
    statics.mountStaticFiles
    logger.afterStatic

    cache.cacheControl

    auth.cookieParser
    auth.session
    auth.passport.initialize
    auth.passport.session
    content.dedupplicateRequests

    routes.restrictApiAccess
    # security.csrf  #not correctly implemented yet

    lang.langCookie
  ]
  production: []
  development:
    use: [
      #handled by the Nginx server in production
      security.allowCrossDomain
      # /!\ Before reactivating CSP policies:
      # - check DataUrl (used by profile picture)
      # - check new Worker(BlobUrl) (used by quagga.js. see https://github.com/greasemonkey/greasemonkey/issues/1803 for bug)
      # security.cspPolicy
    ]
    set:
      debug: 'on'
