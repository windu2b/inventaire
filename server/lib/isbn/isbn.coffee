__ = require('config').universalPath
_ = __.require 'builders', 'utils'
isbn_ = __.require('sharedLibs', 'isbn')(_)

{ parse:isbnParser } = require('isbn2').ISBN
groups = require './groups'

parse = (isbn)->
  # The isbn2 parser would reject an ISBN formatted like 978-2070368228,
  # so removing all hypens gives us more coverage
  isbn = isbn.replace /-/g, ''
  data = isbnParser(isbn)?.codes
  if data?
    { prefix, group, publisher } = data
    data.groupPrefix = groupPrefix = "#{prefix}-#{group}"
    data.publisherPrefix = "#{groupPrefix}-#{publisher}"
    langData = groups[groupPrefix]
    if langData?
      data.groupLang = langData.lang
      data.groupLangUri = langData.wd

  return data

module.exports = _.extend isbn_,
  parse: parse
  toIsbn13: (isbn, hyphenate)->
    data = parse isbn
    unless data? then return
    if hyphenate then data.isbn13h else data.isbn13
