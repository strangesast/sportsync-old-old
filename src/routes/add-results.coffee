express = require 'express'
router = express.Router()
path = require 'path'
multer = require 'multer'
mongoclient = require('mongodb').MongoClient
fs = require 'fs'

active_db_connection = null

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


router.use multer dest: path.join __dirname, 'uploads'

router.get '/', (req, res, next) ->
  res.render 'add-results', title: 'Add Results'

router.post '/', (req, res, next) ->
  fs.writeFile("/tmp/test", req.body.test.join('\n'), (err) ->
    return res.json(err) if err?
    res.json(req.body)
  )

  ###
  connect_to_db().then (db) ->
    files_collection = db.collection 'files'
    owner = 'default'
    result = req.files[file] for file of req.files

      
    res.json(result)

  .catch (err) ->
    console.log "error"
    res.json err

  ###


module.exports = router
