if not sjcl? then alert 'No sjcl library found!'
if sjcl.searchable? then alert 'Overriding sjcl.searchable!'
sjcl.searchable = {}

# Takes a string of data and splits it into tokens.
sjcl.searchable.tokenize = (data) ->
    data = data.toLowerCase().replace /[^\w\s]/gi, ''
    data = data.trim().replace /\s{2,}/g, ' '
    data = data.split ' '
    
    data

generateSecureToken = (iv, key, n, word) ->
    n = n.toString 16
    nEnc = '00000000'
    nEnc = nEnc.substring(0, nEnc.length - n.length) + n

    word = sjcl.codec.hex.fromBits sjcl.codec.utf8String.toBits word
    wEnc = '00000000000000000000000000000000000000000000000000000000'
    wEnc = wEnc.substr(0, wEnc.length - word.length) + word

    buff = sjcl.hash.sha256.hash sjcl.codec.hex.toBits(wEnc + nEnc)

    prp = new sjcl.cipher.aes key
    ct = sjcl.mode.ccm.encrypt prp, buff, iv, [], 0
    ct = sjcl.codec.base64.fromBits ct
    
    ct

# Secures a search index.
sjcl.searchable.secureIndex = (keystore, max, indexes...) ->
    domain = sjcl.codec.base64.fromBits sjcl.random.randomWords 4, 0
    newId = sjcl.codec.base64.fromBits sjcl.random.randomWords 4, 0
    iv = sjcl.random.randomWords 4, 0
    key = sjcl.random.randomWords 8, 10
    
    keystore[domain] = sjcl.codec.base64.fromBits sjcl.bitArray.concat iv, key
    keystore[domain] = [indexes.length, keystore[domain]]
    
    # Normalize first index.
    if indexes[0] instanceof Array
        temp = {}
        temp[token] = newId for token in indexes[0]
        indexes[0] = temp
    
    index = {}
    
    # Merge all indexes.
    for list in indexes
        index[word].push id for word, id of list when index[word]?
        index[word] = [id] for word, id of list when not index[word]?
    
    # Secure new, complete index.
    sindex = {} # Secure index.
    for word, ids of index
        word = word.substr 0, 28
        offset = 28 - word.length
        
        sindex[generateSecureToken(iv, key, n, word)] = id for n, id of ids
    
    docs = [] # Get an array of unique document ids.
    docs.push id for id in ids when -1 is docs.indexOf id for word, ids of index
    
    one = [256, 131072, 50331648] # Pad the secure index.
    two = [256, 65536, 16777216]
    [threshold, sum, i] = [0, 0, 0]
    
    while threshold <= max
        threshold += one[i]
        sum += two[i]
        ++i
    
    threshold = threshold - one[i - 1]
    sum = sum - two[i - 1]
    sum += Math.floor((max - threshold) / i)
    
    for id in docs
        c = 0 # Number of entries in index that already contain that id.
        ++c for entry in sindex when entry is id
        
        l = sum - c
        while l -= 1
            sindex[generateSecureToken(iv, key, docs.length + l, '')] = id
    
    shuffle = (array) ->
        i = array.length
        if i is 0 then return false
        
        bytes = Math.ceil(Math.log(array.length) / (8 * Math.log(2)))
        while i -= 1
            N = new sjcl.bn array.length
            j = new sjcl.bn 4294967297
            one = new sjcl.bn 1
            cap = 4294967296 - (4294967296 % array.length) + 1
            cap = new sjcl.bn cap
            
            # Guess random numbers until one is in range.
            until 0 is j.greaterEquals cap
                j = '0x' + sjcl.codec.hex.fromBits sjcl.random.randomWords 1, 10
                j = new sjcl.bn j
            
            j = j.mulmod one, N
            j = parseInt j.toString(), 16
            [array[j], array[i]] = [array[i], array[j]] # Swap values.
        
        array
    
    keys = shuffle Object.keys sindex # Shuffle the secure index.
    rsindex = {}
    rsindex[key] = sindex[key] for key in keys
    
    out =
        newId: newId
        newDomain: domain
        index:
            docs: docs
            index: rsindex
    
    out

# Create a secure query.
sjcl.searchable.createQuery = (keystore, tokens...) ->
    queries = []
    for word in tokens
        word = word.substr 0, 28
        offset = 28 - word.length
        
        out = {}
        
        for dn, blob of keystore
            data = sjcl.codec.base64.toBits blob[1]
            iv = data.slice 0, 4
            key = data.slice 4, 12
            
            [i, out[dn]] = [0, []]
            until i is blob[0]
                out[dn].push generateSecureToken iv, key, i, word
                ++i
        
        queries.push out
    
    queries
        
