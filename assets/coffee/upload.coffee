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

time_and_split = (array) ->
  # format
  # 00:00.00 -> [00, 00, 00]
  [minutes, seconds, ms] = array.slice(1, 4)
  sub_min = if not isNaN(minutes) then minutes*60*100 else 0
  sub_sec = if not isNaN(seconds) then seconds*100 else 0
  sub_ms  = if not isNaN(ms) then ms else 0
  total_time = sub_min + sub_sec + sub_ms

  # is there split data as well
  if array.slice(5, 6).every((item) -> not isNaN(item))
    # format
    # 00:00.00 (00.00) -> [00, 00, 00, 00, 00]
    [split_seconds, split_ms] = array.slice(-2)
    split_time = split_seconds*100 + split_ms

  return [total_time, if split_time then split_time else null]


ms_to_each = (milliseconds) ->
  minutes = Math.floor(milliseconds / 600000)
  seconds = milliseconds % 600000 / 10000
  ms = milliseconds % 10000

  return [minutes, seconds, ms]


try_to_solve = (string_array) ->
  new Promise (resolve, reject) ->
    toast = []
    for item, index in string_array
      # assume continuity (danger, danger)
      time_re = /\s*(?:\d{1,2}:)*(\d{1,2})+\.\d{2}/
      if time_re.test(item)
        sum = 0
        another_re = /(?:(\d{1,2}):)*(\d{1,2})+\.(\d{2})\s*(?:\((\d{1,2}).(\d{2})\)){0,1}/
        matches = another_re.exec item
        ms = time_and_split(matches)

        toast.push ms


    return resolve toast


###
. file load
  . select file
  . render preview

. preanalysis
  . lane count
  . team count - determine team name format
  . name count?

. analysis
  . subdivide data

. data rendering / validation
  . render data in tables (better if progressive)
###

look_at_headers = (header_text, how_deep) ->
  console.log header_text


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

                  return result.items.map (item) -> item.str

            updateWithPage = (page_number) ->
  
              doc.getPage(page_number).then (page) ->
                viewport = page.getViewport 1.0
                canvas.height = viewport.height
                canvas.width = viewport.width

                render_page(page, ctx, viewport).then (result) ->
                  console.log "rendered page #{page_number}"

                  try_to_solve result
                    .then (res) ->
                      console.log res

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
            test = Promise.all([1..page_count].map (page_number) ->
              ((page_num) ->
                # get page # page_number from doc
                doc.getPage(page_num).then (page) ->
                  # get text content of document
                  page.getTextContent().then (text_content) ->
                    # limit to items in document, rather than both
                    # items and styles
                    return text_content.items.map (item) ->
                      # limit to item strings (should probably use 
                      # positional information as well)
                      item.str

              )(page_number)

            ).then (all) ->
              page_regex = /[P,p]age\s*([1-9][0-9]|[1-9])/
              # remove headers
              first_page = all[0]
              header_up_to = 0
              for column, column_index in first_page
                test_text = first_page[column_index].replace(page_regex, "PAGE").trim()
                for row, row_index in all
                  break_test = false
                  if row[column_index].replace(page_regex, "PAGE").trim() == test_text
                    break_test = true
                    all[row_index][column_index] = null

                header_up_to += 1

                if break_test != true
                  break

              combined = all.reduce((prev, curr) -> prev.concat(curr))
              console.log "combined"
              console.log combined[0]
              console.log combined.slice(-1)[0]
              string = combined.map((element) -> if typeof element == "string" then element else "").reduce((prev, curr) -> prev + '\n' + curr)

              console.log string
              text.textContent = first_page.slice(0, header_up_to).join('\n') + "\n\n\n" + string



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
