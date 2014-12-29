__ = require('config').root
_ = __.require 'builders', 'utils'
promises_ = __.require 'lib', 'promises'
cache_ = __.require 'lib', 'cache'
books = __.require 'lib', 'books'

module.exports = getImages = (req, res)->
  dataArray = req.query.data.split '|'
  unless dataArray? then return res.json 400, 'bad query'

  promises = dataArray.map getImage

  _.log dataArray, 'dataArray'
  promises_.settle(promises)
  .then (dataSets)->

    _.log dataSets, 'dataSets'
    data = {}
    i = 0
    while i < dataArray.length
      key = dataArray[i]
      value = dataSets[i]
      data[key] = value
      i++

    _.log data, 'data at getImages'
    res.json data
  .catch (err)-> _.errorHandler res, err

getImage = (data)->
  key = "image:#{data}"
  cache_.get key, books.getImage, books, [data]
  .catch (err)-> _.error err, 'getImage err'