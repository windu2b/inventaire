CONFIG = require 'config'
__ = CONFIG.root
_ = __.require 'builders', 'utils'
regex_ = require './regex'
error_ = __.require 'lib', 'error/error'

{ CouchUuid, Email, Username, EntityUri, Lang } = regex_

# regex need to their context
bindedTest = (regex)-> regex.test.bind(regex)

module.exports = tests =
  userId: bindedTest CouchUuid
  itemId: bindedTest CouchUuid
  transactionId: bindedTest CouchUuid
  username: bindedTest Username
  email: bindedTest Email
  entityUri: bindedTest EntityUri
  lang: bindedTest Lang


tests.nonEmptyString = (str, maxLength=100)->
  _.isString str
  return 0 < str.length <= maxLength

# no item of this app could have a timestamp before june 2014
June2014 = 1402351200000
tests.EpochMs =
  test: (time)-> June2014 < time <= _.now()


tests.pass = (attribute, value, option)->
  unless @[attribute](value, option)
    throw error_.new "invalid #{attribute}: #{value}", 400
