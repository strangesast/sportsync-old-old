express = require 'express'
router = express.Router()
mongoclient = require('mongodb').MongoClient

mongo_url = "mongodb://localhost:27017/sportsync"

connect_to_db = ->
  if active_db_connection?
    Promise.resolve(active_db_connection)
  else
    new Promise (resolve, reject) ->
      console.log "connecting to db at #{mongo_url}"
      mongoclient.connect mongo_url, (err, db) ->
        return reject err if err?
        resolve db


router.get '/', (req, res, next) ->
  res.render 'upload'

  
module.exports = router
