pdfjs = PDFJS
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

upload_file = (file) ->
  formData = new FormData()
  formData.append('file', file)

  req = new XMLHttpRequest()
  req.open('POST', '/add-results')
  i = 0
  req.onload = (e) ->
    i++
    console.log i
    console.log e.target.response
  req.send(formData)

handleFileSelection = (e) ->
  files = e.target.files

  for file in files
    pdfjs.getDocument URL.createObjectURL file
    .then (pdf) ->
      Promise.all([1..pdf.numPages].map (index) ->
        pdf.getPage(index)
        .then (page) ->
          #scale = 0.5
          #viewport = page.getViewport scale

          #canvas = document.getElementById 'canvas'
          #context = canvas.getContext '2d'
          #canvas.height = viewport.height
          #canvas.width = viewport.width

          #renderContext =
          #  canvasContext: context
          #  viewport: viewport

          #page.render renderContext

          page.getTextContent().then (content) ->
            text = content.items.map (e) ->
              return e.str
            .reduce (prev, curr) ->
              return prev + curr
            
      )
    .then (obj) ->
      request(test: obj, '/add-results').then (res) ->
        console.log res

  return false



file_button = document.getElementById 'files'
file_button.addEventListener 'change', handleFileSelection, false
