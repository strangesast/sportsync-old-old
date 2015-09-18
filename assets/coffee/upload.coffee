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

pentuplet_to_ms_and_split = (pentuplet) ->
  for each, i in pentuplet[1..3]
    if isNaN(Number(each))
      pentuplet[i] = 0

  if pentuplet[4]? and pentuplet[5]?
    split = Number(pentuplet[4])*100 + pentuplet[5]

  if isNaN(Number(pentuplet[1]*60 + pentuplet[2]))
    console.log pentuplet
  return primary: (pentuplet[1]*60 + pentuplet[2])*100 + pentuplet[3], split: split

try_to_solve = (string_array) ->
  new Promise (resolve, reject) ->
    toast = []
    for item, index in string_array
      # assume continuity (danger, danger)
      time_re = /\s*(?:\d{1,2}:)*(\d{1,2})+\.\d{2}/
      if time_re.test(item)
        sum = 0
        #another_re = /(?:(\d{1,2}):)*(\d{1,2})+\.(\d{2})/ #without splits
        another_re = /(?:(\d{1,2}):)*(\d{1,2})+\.(\d{2})\s*(?:\((\d{1,2}).(\d{2})\)){0,1}/
        matches = another_re.exec item
        ms = pentuplet_to_ms_and_split(matches)

        toast.push(ms)


    console.log toast
    return toast
  




    resolve string_array

handleFileSelection = (e) ->
  files = e.target.files

  for file in files
    reader = new FileReader()

    reader.onload = (
      (file_object) ->
        (file_read_event) ->
          target = file_read_event.target.result
          # load pdf document
          PDFJS.getDocument(target).then (doc) ->
            page_count = doc.pdfInfo.numPages

            ctx = canvas.getContext '2d'

            current_page = 1

            render_page =  (page, ctx, viewport) ->
              page.render(canvasContext: ctx, viewport: viewport).then () ->
                console.log 'rendered'

                page.getTextContent().then (result) ->
                  string = result.items.map((item) -> item.str).join('\n')
                  text.textContent = string

                  return result.items.map (item) -> item.str

            updateWithPage = (page_number) ->
  
              doc.getPage(page_number).then (page) ->
                viewport = page.getViewport 1.0
                canvas.height = viewport.height
                canvas.width = viewport.width

                render_page(page, ctx, viewport).then (result) ->
                  console.log "rendered page #{page_number}"

                  try_to_solve result

            page_change = (page_change_event) ->
              unless page_change_event.target.name == "down"
                val = 1
              else
                val = -1

              new_page = Math.max(Math.min(current_page + val, page_count), 1)
                
              unless new_page == current_page
                updateWithPage(new_page)

                current_page = new_page

            increment_up.addEventListener 'click', page_change, false
            increment_down.addEventListener 'click', page_change, false
              
            updateWithPage(current_page) # do the first one, first

          .catch (err) ->
            console.log err
            alert "failed to load #{file_object.name}"

    )(file)

    reader.readAsArrayBuffer(file)




file_button = document.getElementById 'files'
file_button.addEventListener 'change', handleFileSelection, false

canvas = document.getElementById 'canvas'
text = document.getElementById 'text'
increment_up = document.getElementById 'up'
increment_down = document.getElementById 'down'
