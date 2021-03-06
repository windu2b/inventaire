__ = require('config').universalPath
_ = __.require 'builders', 'utils'
items_ = __.require 'controllers', 'items/lib/items'
user_ = __.require 'lib', 'user/user'
couch_ = __.require 'lib', 'couch'
error_ = __.require 'lib', 'error/error'
Item = __.require 'models', 'item'
{ Promise } = __.require 'lib', 'promises'
tests = __.require 'models', 'tests/common-tests'

module.exports =
  lastPublicItems: (req, res, next) ->
    { query } = req
    { limit, offset } = query
    assertImage = query['assert-image'] is 'true'

    limit or= '15'
    offset or= '0'

    try
      limit = _.stringToInt limit
    catch err
      return error_.bundle req, res, 'invalid limit', 400, [limit, err]

    try
      offset = _.stringToInt offset
    catch err
      return error_.bundle req, res, 'invalid offset', 400, [offset, err]

    if limit > 100
      return error_.bundle req, res, "limit can't be over 100", 400, limit

    items_.publicByDate limit, offset, assertImage
    .then bundleOwnersData.bind(null, req, res)
    .catch error_.Handler(req, res)

  usersPublicItems: (req, res, next)->
    _.info req.query, 'usersPublicItems'
    { query } = req
    { users } = query
    unless _.isNonEmptyString(users)
      return error_.bundle req, res, 'missing parameter: users', 400, query

    usersIds = users.split '|'
    unless _.all usersIds, tests.userId
      return error_.bundle req, res, 'invalid user ids', 400, query

    items_.bundleListings ['public'], usersIds
    .then _.Wrap(res, 'items')
    .catch error_.Handler(req, res)

  publicById: (req, res, next) ->
    { id } = req.query
    unless tests.itemId id
      return error_.bundle req, res, 'bad item id', 400

    items_.publicById id
    .then res.json.bind(res)
    .catch error_.Handler(req, res)

  publicByEntity: (req, res, next) ->
    _.info req.query, 'publicByEntity'
    { uri } = req.query
    unless tests.entityUri uri
      return error_.bundle req, res, 'bad entity uri', 400

    items_.publicByEntity uri
    .then bundleOwnersData.bind(null, req, res)
    .catch error_.Handler(req, res)

  publicByUsernameAndEntity: (req, res, next)->
    _.info req.query, 'publicByUserAndEntity'
    { username, uri } = req.query

    unless tests.entityUri uri
      return error_.bundle req, res, 'bad entity uri', 400
    unless tests.username username
      return error_.bundle req, res, 'bad username', 400

    user_.getSafeUserFromUsername username
    .then (user)->
      { _id } = user
      unless _id?
        return error_.new 'user not found', 404

      owner = _id
      items_.publicByOwnerAndEntity owner, uri
      .then (items)-> res.json {items: items, user: user}

    .catch error_.Handler(req, res)

bundleOwnersData = (req, res, items)->
  unless items?.length > 0
    return error_.bundle req, res, 'no item found', 404

  users = getItemsOwners items
  user_.getUsersPublicData users
  .then (users)-> res.json {items: items, users: users}

getItemsOwners = (items)->
  users = items.map (item)-> item.owner
  return _.uniq users
