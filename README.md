SJCL:  Searchable Encryption
============================

An extension to [The Stanford Javascript Crypto Library](https://github.com/bitwiseshiftleft/sjcl), providing basic searchable symmetric encryption.


> Searchable symmetric encryption (SSE) allows a party to outsource the storage of his data to another party in a private manner, while maintaining the ability to selectively search over it.

~ *[Searchable Symmetric Encryption:  Improved Definitions and Efficient Constructions](http://eprint.iacr.org/2006/210.pdf)*

Applications: *(Basically anything that involves tagging or querying private data.)*
  1. Outsourcing functionality like spam detection and search to a backend server in encrypted email services.
  2. Raw data and file storage.
  3. ...?


Compiling
---------

For those who'd prefer to compile the CoffeeScript into JavaScript and run that instead:
```bash
coffee -c ./searchable.coffee
```

Regardless of what filetype is in use, an appropriately compiled `sjcl.js` should always be loaded before this library is.


Documentation
-------------
*This implementation of SSE is intended for the browser, while [caesar](https://github.com/Bren2010/caesar)'s implementation can be used on the backend.*
  - `sjcl.searchable.tokenize(corpus)` - The basic, stock tokenizer.  Takes a corpus and returns the `Array` of unique words it contains without caps or punctuation.
    1. `corpus` - Body of text to be tokenized.  (`String`)
    -  Returns the tokenized corpus.  (`Array`)
  - `sjcl.searchable.secureIndex(keystore, max, indexes...)` - Encrypts a data's index so that it can be sent to an untrusted party.
    1. `keystore` - The unencrypted keystore.  (`Object`)
    2. `max` - The size in bytes of the largest document in the collection.  (`Number`)
    3. `indexes...` - 
