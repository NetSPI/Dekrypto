# Dekrypto 
A script to perform padding oracle attack against IBM Websphere Commerce (CVE-2013-05230) - written by Khai Tran [https://twitter.com/ktranfosec](https://twitter.com/ktranfosec "@ktranfosec")

### External libraries used:
- Ron Bowes' poracle framework: https://github.com/iagox86/poracle
- Meh's threadpool library: https://github.com/meh/ruby-thread thread 
- Florian Pilz's micro-optparse: https://github.com/florianpilz/micro-optparse 
- John Nunemaker's Httparty https://github.com/jnunemaker/httparty

### Installation
``bundle install``

On Kali Linux you may want to run `apt-get install ruby-dev` first when encounter this error:

    /usr/bin/ruby1.9.1 extconf.rb 
    /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require': cannot load such file -- mkmf (LoadError)
    from /usr/lib/ruby/1.9.1/rubygems/custom_require.rb:36:in `require'
    from extconf.rb:4:in `<main>'

### Usage: Dekrypto.rb [options]

```   
	-s, --sort   Sort temporary results
    -v, --verboseShow debug messages
    -t, --threads SIZE   Set threadpool size
    -f, --file FILE  Save temporary results to file
    -h, --help   Show this message
```
#### Example: run krypto test server

    ruby KryptoTestServer.rb

#### Example: run Dekrypto script with 10 threads, verbose, saving progress to text file

    ruby DeKryptoDemo.rb -v -f decrypted.txt –t 10

#### Note: to change target URL and Success/Fail condition, edit following methods in Dekrypto.rb
- `initialize()` -> change target URL
- `attempt_decrypt()` -> Success/Fail condition 