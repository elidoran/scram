
fs = require 'fs'
path = require 'path'
LineByLineReader = require 'line-by-line'

args = require ('yargs')
  .usage('Usage:\n  $0 -input <input file> -output <output file>')
  .demand(['input', 'output'])
  .alias('i', 'input')
  .alias('o', 'output')
  .describe('i', 'The GMROI report from Eclipse')
  .describe('o', 'The file to save the CSV results into')
  .argv

inputFile = path.resolve args.input
outputFile = path.resolve args.output

reader = new LineByLineReader inputFile, { skipEmptyLines: true }

skipNames = [
    'IN HOUSE PURCHASE LI'
    'MISC (IN HOUSE USE)'
    '9'
    'Grand Total'
    'New Priceline'
    'New Buyline'
    'MISC PRICE LINE'
    ]
skipLineCount = 4
data = []
linesPerData = 7
lines = []

skippedCount = 0
processedCount = 0

reader.on 'error', (err) ->
    # 'err' contains error object
    console.error "Encountered an error: #{err.message}"

reader.on 'line', (line) ->
    #console.log 'read a line...'
    if skipLineCount-- > 0
        #console.log 'skipped intro line'
        return

    lines.push line

    #console.log "pushed line, count is now: #{lines.length}"

    if lines.length is linesPerData
        #console.log "lines length is now #{linesPerData}, checking..."
        if shouldSkip()
            console.log "skipping... #{lines[0].substring(0, 20)}"
            clear lines
            return

        processLines()

    return

output = undefined
reader.on 'end', ->
    console.log 'End of file reached.'
    console.log "processed: #{processedCount}  skipped: #{skippedCount}"
    data.sort (a, b) -> a.onhand$ - b.onhand$
    #console.log "#{pl.name}  #{pl.onhand$}" for pl in data
    output = fs.createWriteStream outputFile, 'utf8'
    headers = [
        'Customer'
        'Annual Sales$'
        'Annual COGS$'
        'Annual GP$'
        'Avg $OnHand'
        'Turns'
        'Avg MU%'
        'GMROI'
        'Adjusted Margin%'
        ]
    headers = '"' + headers.join('","') + '"\n'
    output.write headers
    writeResults()
    return

writeResults = ->
    okay = writeResult()
    while okay
        okay = writeResult()

    if data.length isnt 0
        output.once 'drain', writeResults
    else
        console.log 'Output written.'

writeResult = ->
    if data.length is 0
        output.end()
        return false

    pl = data.pop()
    value = [
            pl.name
            pl.annualSales$
            pl.annualCogs$
            pl.annualGp$
            pl.onhand$
            pl.turns
            pl.avgMu
            pl.gmroi
            pl.adjustedMargin
        ]
    value = '"' + value.join('","') + '"\n'
    output.write value


shouldSkip = ->
    for skipName in skipNames
        if lines[0].indexOf(skipName) is 0
            skippedCount++
            return true
    return false

clear = (array) ->
    #console.log 'clearing array'
    while array.length > 0
        array.pop()
    return

processLines = ->
    #console.log 'processing lines'

    pl = {}

    pl.name = lines[0].substring(0, 20).trim()
    totals = tokens lines[6].substring(20)
    pl.annualSales$ = totals[9]
    pl.annualCogs$ = totals[10]
    pl.annualGp$ = totals[11]
    pl.onhand$ = Number strip ',', totals[12]
    pl.turns = totals[13]
    pl.avgMu = totals[14]
    pl.gmroi = totals[15]
    pl.adjustedMargin = totals[16]

    #console.log "name: #{pl.name}  onhand: #{pl.onhand$}"
    #console.log "totals: #{totals}"

    data.push pl

    clear lines
    processedCount++
    return

tokens = (string) ->
    array = string.split ' '
    value for value in array when value.length isnt 0

strip = (ch, value) ->
    newValue = ''
    newValue += c for c in value when c isnt ch
    newValue
