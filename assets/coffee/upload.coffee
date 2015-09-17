request = (msg, url, method='POST') ->
  msg = JSON.stringify(msg)
  new Promise (resolve, reject) ->
    req = new XMLHttpRequest()
    req.open method, url, true
    req.setRequestHeader(
      'Content-Type',
      'application/json; charset=UTF-8'
    )
    req.onload = (e) ->
      resolve(req)
    req.onerror = (e) ->
      reject(req)
    req.send(msg)

handleFileSelection = (e) ->
  files = e.target.files

  for file in files
    reader = new FileReader()

    reader.onload = (
      (file_object) -> 
        (e) ->
          target = e.target.result
          # load pdf document
          PDFJS.getDocument(target).then (doc) ->
            # load first page
            doc.getPage(1).then (page) ->
              viewport = page.getViewport 1.0

              canvas.height = viewport.height
              canvas.width = viewport.width

              ctx = canvas.getContext '2d'

              # render preview
              page.render(canvasContext: ctx, viewport: viewport).then () ->
                console.log 'rendered'

                page.getTextContent().then (result) ->
                  console.log "got text"
                  console.log result.items

                  text.textContent = result.items.map (item) ->
                    return item.str
                  .join("\n")

              .catch (err) ->
                console.log err
                alert 'failed to render'

          .catch (err) ->
            console.log err
            alert "failed to load #{file_object.name}"

    )(file)

    reader.readAsArrayBuffer(file)




file_button = document.getElementById 'files'
file_button.addEventListener 'change', handleFileSelection, false

canvas = document.getElementById 'canvas'
text = document.getElementById 'text'
