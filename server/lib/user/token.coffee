CONFIG = require 'config'
__ = CONFIG.root
_ = __.require 'builders', 'utils'
Radio = __.require 'lib', 'radio'
User = __.require 'models', 'user'
error_ = __.require 'lib', 'error/error'
pw_ = __.require('lib', 'crypto').passwords
{tokenDaysToLive} = CONFIG

# waiting for credential 0.2.6 to make pw_.expired verifications
testToken = pw_.verify
uuid = require 'simple-uuid'


module.exports = (db)->

  token_ = {}

  token_.sendValidationEmail = (user)->
    if user.validEmail
      log = _.pick user, ['_id', 'creationStrategy']
      _.warn log, 'email was already validated'
      return user

    getTokenData()
    .then (tokenData)->
      [token, tokenHash] = tokenData
      Radio.emit 'validation:email', user, token
      updateEmailValidation db, user, tokenHash
      return user

  token_.confirmEmailValidity = (email, token)->
    @findOneByEmail(email)
    .then updateIfValidToken.bind(null, token)

  updateIfValidToken = (token, user)->
    {emailValidation, _id} = user
    unless emailValidation?
      throw error_.new 'token is invalid or expired', 401, token, _id

    testToken(emailValidation, token)
    .then updateValidEmail.bind(null, db, _id)

  token_.sendResetPasswordEmail = (user)->
    getTokenData()
    .then (tokenData)->
      [token, tokenHash] = tokenData
      Radio.emit 'reset:password:email', user, token
      updateToken db, user, tokenHash
      return user

  return token_


updateValidEmail = (db, _id, valid)->
  if valid then db.update _id, emailIsValid
  else throw error_.new 'token is invalid or expired', 401, _id

emailIsValid = (user)->
  user.validEmail = true
  return _.omit user, 'emailValidation'

getTokenData = ->
  token = uuid()
  pw_.hash(token)
  .then (tokenHash)->
    return [token, tokenHash]

updateEmailValidation = (db, user, tokenHash)->
  db.update user._id, (doc)->
    doc.emailValidation = tokenHash
    return doc

updateToken = (db, user, tokenHash)->
  db.update user._id, (doc)->
    doc.token = tokenHash
    return doc