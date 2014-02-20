
console.log "test script args: #{process.argv[2..]}"

process.on 'message', (msg) ->
    console.log 'child received: ' + msg.num

for i in [1..10]
    process.send
        type: 'count'
        count: i

# done, so exit
process.exit 0




