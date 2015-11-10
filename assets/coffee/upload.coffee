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


plot_numbers = (data) ->
  data = data.slice(0, 10000)
  canvas = document.getElementById 'plot'
  h = 300
  w = canvas.parentElement.clientWidth
  w = data.length*3

  canvas.width = w
  canvas.height = h

  ctx = canvas.getContext '2d'

  ctx.beginPath()
  ctx.moveTo(0, h)

  dmax = data.reduce (a, b) -> if a > b then a else b
  dmin = data.reduce (a, b) -> if a < b then a else b

  ctx.font = "8px Georgia"
  ctx.textAlign = "center"
  for each, i in data
    xi =  i / data.length * w
    yi =  h*(1 - (each - dmin)/(dmax-dmin))
    if i == data.length - 1
      ctx.moveTo(xi, yi)
      ctx.closePath()
    else
      if /[A-Za-z]/.test(each)
        yi = h

      text = String.fromCharCode each
      ctx.fillText(text, xi, 10)
      ctx.lineTo(xi, yi)

  ctx.stroke()


mseconds_to_string = (mseconds) ->
  minutes = Math.floor(mseconds / 6000)
  seconds = Math.floor((mseconds - minutes*6000) / 100)
  mseconds = mseconds-minutes*6000-seconds*100
  return "#{minutes}:#{seconds}.#{mseconds}"

split_to_mseconds = (text_time) ->
  val = text_time.value
  both = val.split(':')
  min = sec = msec = 0
  if both.length == 2
    [min, secs] = both
  else if both.length == 1
    secs = both[0]

  [sec, msec] = secs.split('.')
  [min, sec, msec] = [min, sec, msec].map (e) -> Number e
  ret = min*60*100 + sec*100 + msec
  
  return ret


regex_to_matches = (re, text, type) ->
  temp = []
  matches = []
  for i in [1..2000] # limit tests to 2000
    temp = re.exec text
    break if temp == null
    matches.push index: temp.index, value: temp[0], type: type.trim()

  return matches

find_splits = (page_text) ->
  re = /([0-9]{1,2}\:)?[0-9]{2}\.[0-9]{2}/g
  return regex_to_matches re, page_text, 'split'

find_events = (page_text) ->
  re = /[Ee]vent\s*\d{1,3}\s*([Mm]en|[Ww]omen)\s*\d{2,4}\s[A-Z]\w*\s[A-Z][a-z]*/g
  return regex_to_matches re, page_text, 'event'

find_names = (page_text) ->
  re = /[A-Z][a-z]*,\s[A-Z][a-z]*(\s\w)?/g
  re = /[A-Z][a-z]*,\s*[A-Z][a-z]*(-[A-Z][a-z]*){0,1}(\s\w)?/g #includes hyphenated names
  return regex_to_matches re, page_text, 'name'

find_teams = (page_text, index=true) ->
  re = /[A-Z][a-z]{3,}(\s[a-zA-Z][a-z]*)*-[A-Z]{2}/g
  return regex_to_matches re, page_text, 'team'

find_ages = (page_text) ->
  re = /(FR|SO|JR|SR)/g
  return regex_to_matches re, page_text, 'age'

find_header = (page_text) ->
  #re = /([Nn]ame|[Yy]r|[Ss]chool|[Pp]relim\s[Tt]ime|[Ff]inals\s[Tt]ime)/g
  #re = /((([Nn]ame|[Yy]r|[Ss]chool|[Pp]relim\s[Tt]ime|[Ff]inals\s[Tt]ime)\s*){2,})/g
  re = /(([Nn]ame|[Yy]r|[Ss]chool|[Pp]relim\s[Tt]ime|[Ff]inals\s[Tt]ime){3,})/g
  return regex_to_matches re, page_text, 'header'

try_to_sort_out_header = (all_matches, all_pages) ->
  all_broken = []
  for page, page_index in all_pages
    matches = all_matches[page_index]
    broken = []
    if matches.length == 0
      broken.push page
    else
      matches.reduce((a, b, i, array) ->
        broken.push page.slice(a, b)
        if i == array.length - 1
          broken.push page.slice array[i]
        return b # <- important
      , 0)

    if all_broken.length > 0
      last = all_broken.slice(-1)[0]
      all_broken = all_broken.slice(0, -1).concat([last + broken[0]])
      all_broken = all_broken.concat broken.slice(1)
    else
      all_broken = broken

  return all_broken

plot_data_types = (data) ->
  canvas = document.getElementById 'plot'
  ctx = canvas.getContext '2d'
  #canvas.width = data.length*3
  max_index = data.map((e) -> e.index).reduce((a, b) -> if a > b then a else b)
  canvas.width = 10000
  canvas.height = 200
  w = canvas.width
  h = canvas.height
  l = data.length
  r = 3
  #repeatedCount = 0
  #lastType = ""
  ctx.fillStyle = 'gray'
  ctx.fillRect(0, 0, w, h)
  for point, i in data
    xi = w / max_index * point.index
    ctx.fillStyle = 'white'
    ctx.fillRect xi, 0, w / max_index * point.value.length, h
    ctx.beginPath()
    #xi = i / l * w
    if point.type == 'split'
      ctx.fillStyle = 'red'
      yi = 5*h/6
    else if point.type == 'age'
      ctx.fillStyle = 'yellow'
      yi = 4*h/6
    else if point.type == 'team'
      ctx.fillStyle = 'orange'
      yi = 3*h/6
    else if point.type == 'event'
      ctx.fillStyle = 'green'
      yi = 2*h/6
    else if point.type == 'name'
      ctx.fillStyle = 'brown'
      yi = 1*h/6
    else
      # this shouldn't happen
      console.log point.type
      ctx.fillStyle = 'black'
      yi = h

    ctx.arc xi, yi, r, 0, 2*Math.PI, false
    ctx.fill()
    #if lastType == point.type
    #  repeatedCount += 1
    #else
    #  if repeatedCount > 10
    #    ctx.fillStyle = 'black'
    #    ctx.fillText String(repeatedCount), xi - (repeatedCount * w / l / 2), h/2
    #  repeatedCount = 0

    #lastType = point.type
  lastType = ""
  currVal = 0
  currInd = 0
  toast = []
  for point, i in data
    if lastType == point.type
      currVal += 1
    else
      toast.push currVal
      currVal = 0
      currInd += 1
    lastType = point.type

  console.log toast.length
  canvas = document.getElementById 'plot2'
  ctx = canvas.getContext '2d'

  maxval = toast.reduce (a, b) -> if a > b then a else b
  minval = toast.reduce (a, b) -> if a < b then a else b
  w = 10000
  h = 200
  canvas.height = h
  canvas.width = w

  ctx.beginPath()
  ctx.moveTo 0, h
  for each, i in toast
    xi = i / toast.length*w
    yi = (1 - (each - minval) / (maxval - minval))*h
    ctx.lineTo xi, yi


  ctx.stroke()
  ctx.closePath()

  return


another_approach = (data) ->
  data = data.map((page) ->
    page_joined = page.reduce((a, b) -> a + b)
    return page_joined
  )

  last_index = 0
  all_splits = []
  all_events = []
  all_names = []
  all_teams = []
  all_ages = []

  add_last_index = (last_index) ->
    (e) ->
      e.index = e.index + last_index
      return e

  for page in data
    team_matches = find_teams(page)
    team_matches.map (e) -> e.index=e.index+last_index; e
    last_index += page.length

    fn = add_last_index(last_index)
    all_splits = all_splits.concat find_splits(page).map fn
    all_events = all_events.concat find_events(page).map fn
    all_names = all_names.concat find_names(page).map fn
    all_teams = all_teams.concat find_teams(page).map fn
    all_ages = all_ages.concat find_ages(page).map fn

  all = all_splits.concat all_events.concat all_names.concat all_teams.concat all_ages
  plot_data_types all.sort (a, b) -> a.index-b.index

  # sort by index
  #unique_team_names = []
  #header_matches = []

  #for page in data
  #  #matches = find_splits(page)
  #  #matches = find_events(page)
  #  #matches = find_names(page)
  #  matches = find_teams(page).map((e) -> e.value)
  #  for match in matches
  #    if unique_team_names.indexOf(match) == -1
  #      unique_team_names.push match
  #  #matches = find_ages(page)
  #  matches = find_header(page).map((e) -> e.index)
  #  header_matches.push matches

  #broken_by_header = try_to_sort_out_header(header_matches, data)
  #sorted_matches = []

  #last_index = 0
  #for piece in broken_by_header.slice(0)
  #  all_matches = []
  #  matches = find_teams(piece)
  #  all_matches = all_matches.concat matches
  #  matches = find_ages(piece)
  #  all_matches = all_matches.concat matches
  #  matches = find_events(piece)
  #  all_matches = all_matches.concat matches
  #  matches = find_splits(piece)
  #  all_matches = all_matches.concat matches
  #  matches = find_names(piece)
  #  all_matches = all_matches.concat matches

  #  broken = []
  #  curr = []
  #  sorted = all_matches.sort((a, b) -> a.index-b.index).map((e) -> e.index = e.index + last_index; e)
  #  sorted_matches = sorted_matches.concat sorted
  #  last_index = sorted.map((e) -> e.index).reduce((a, b) -> if a > b then a else b)

  #plot_data_types sorted_matches

  # split ident
  #curr = []
  #for match in sorted_matches
  #  if match.type == 'split'
  #    ret = split_to_mseconds match
  #    curr.push ret
  #  else
  #    if curr.length > 0
  #      console.log "len: #{curr.length}"
  #      if curr.length > 3
  #        curr_sorted = curr.sort (a, b) -> b-a
  #        out = []
  #        index = 0
  #        cnt = 0
  #        acnt = 0
  #        while index < curr_sorted.length - 1
  #          cur = curr_sorted[index]
  #          nxt = curr_sorted[index+1]
  #          diff = cur - nxt
  #          cnt += if diff in curr_sorted then 1 else 0
  #          acnt += if [diff + 1, diff - 1, diff].some((e) -> e in curr_sorted) then 1 else 0
  #          index+=1

  #        console.log " cnt: #{cnt}"
  #        console.log "acnt: #{acnt}"

  #    curr = []

  return


class ItemSet
  constructor: (@doc_id) ->
    ItemSet.item_sets[@doc_id] = @

  items: []

  @item_sets: {}

class Item
  constructor: (@original_index, @page, itemSet) ->
    @type = 'hanging' # type not yet assigned

    # was it joined with a preceding item
    @concatenated = false

    # if it was concatenated, but an obvious alt isn't available
    @alt_value =  null

    # add to list of items
    ItemSet.item_sets[itemSet].items.push @

parse_for_times = (data, page, doc_id) ->
  re = /([0-9]{1,2}\:)?[0-9]{2}\.[0-9]{2}/
  console.log 'parse for data'
  new_data = []
  pla = ""
  for raw_item, raw_index in data
    item = new Item(raw_index, page, doc_id)
    first_result = re.exec pla + raw_item

    if first_result? # does raw_item contain time?
      {0: match, 1: _, index: ind, input: inp} = first_result

      item.value = match

      if pla != "" # was item concatenated with another item
        pla_test = raw_item.match re
        if pla_test? # does raw_item work without pla?
          item.alt_value = match
          {0: match, 1: _, index: ind, input: inp} = first_result
          item.value = match # second value is probably* better (*meh)
          item.type = 'split'

        else # raw_item needs pla, so it is concatenated
          item.concatenated = yes

        pla = ""

      remainder = raw_item.slice(ind + match.length)

      second_result = remainder.match re

      if second_result? # does remainder contain time?
        new_item = new Item(raw_index, page, doc_id)
        {0: match, 1: _, index: ind, input: inp} = first_result

        new_item.value = match
        new_item.type = 'split'

      else
        # check that pla contains numbers like its broken from another item
        if /[0-9]/.test(pla)
          pla = remainder

    else # item didn't contain number
      if /[0-9]/.test(pla)
        pla = remainder

      item.value = raw_item

  return


handleFileSelection = (e) ->
  files = e.target.files

  for file in files
    reader = new FileReader()

    reader.onload = (
      (file_object) ->
        {name: filename, lastModified: filemod} = file_object
        fileid = filename + '_' + filemod
        console.log ItemSet.item_sets
        if fileid not of ItemSet.item_sets
          new ItemSet fileid
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

                  #parse_for_times(result, page_number, fileid)

                  #try_to_solve result
                  #  .then (res) ->
                  #    console.log res

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
              another_approach all

              #text.textContent = all.map((elem) -> elem.map(
              #text.textContent = all[0].join('\n')

              ###
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
              ###



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
long_text = document.getElementById 'long-text'
increment_up = document.getElementById 'up'
increment_down = document.getElementById 'down'
