##
# Poracle.rb
# Created: December 8, 2012
# By: Ron Bowes
#
# This class implements a simple Padding Oracle attack. It requires a 'module',
# which implements a couple simple methods:
#
# NAME
#  A constant representing the name of the module, used for output.
#
# blocksize()
#  The blocksize of whatever cipher is being used, in bytes (eg, # 16 for AES,
#  8 for DES, etc)
#
# attempt_decrypt(ciphertext)
#  Attempt to decrypt the given data, and return true if there was no
#  padding error and false if a padding error occured.
#
# character_set() [optional]
#  If character_set() is defined, it is expected to return an array of
#  characters in the order that they're likely to occur in the string. This
#  allows modules to optimize themselves for, for example, filenames. The list
#  doesn't need to be exhaustive; all other possible values are appended from
#  0 to 255.
#
# See LocalTestModule.rb and RemoteTestModule.rb for examples of how this can
# be implemented.
##
#

module Poracle
  attr_accessor :verbose

  @@guesses = 0

  def Poracle.guesses
    return @@guesses
  end

  def Poracle.ord(c)
    if(c.is_a?(Fixnum))
      return c
    end
    return c.unpack('C')[0]
  end
  
  def Poracle.generate_set(base_list)
    mapping = []
    new_list=[]
    base_list.each do |i|
      new_list<< ord(i)
      mapping[ord(i)] = true
    end
    0.upto(255) do |i|
      if(!mapping[i])
        new_list <<i 
      end
    end
    return new_list
  end
  
  
  def Poracle.find_character(mod, character, blocks, index, plaintext,  character_set, verbose = false)
    # First, generate a good C' (C prime) value, which is what we're going to
    # set the previous block to. It's the plaintext we have so far, XORed with
    # the expected padding, XORed with the previous block. This is like the
    # ketchup in the secret sauce.
    STDOUT.flush
    block=blocks[index]
    previous=blocks[index-1]
    blockprime = Array.new(mod.blocksize, 0)
    (mod.blocksize - 1).step(character + 1, -1) do |i|
      blockprime[i] = (plaintext[i])  ^ (mod.blocksize - character) ^(previous[i])
    end
      # Try all possible characters in the set (hopefully the set is exhaustive)
    character_set.each do |current_guess|
      # Calculate the next character of C' based on the plaintext character we
      # want to guess. This is the mayo in the secret sauce.
      blockprime[character] = ((mod.blocksize - character) ^ (previous[character]) ^ (current_guess))
      # Ask the mod to attempt to decrypt the string. This is the last
      # ingredient in the secret sauce - the relish, as it were.
      new_block=Array.new
      new_block << blocks[0..index-2] << blockprime << block
      result = mod.attempt_decrypt(new_block)
      # Increment the number of guesses (for reporting/output purposes)
      @@guesses += 1

      # If it successfully decrypted, we found the character!
      if(result)
        # Validate the result if we're working on the last character
        false_positive = false
        if(character == mod.blocksize - 1)
          # Modify the second-last character in any way (we XOR with 1 for
          # simplicity)
          blockprime[character - 1] = (blockprime[character - 1]) ^ 1
          # If the decryption fails, we hit a false positive!
          new_block=Array.new
          new_block<<blocks[0..index-2] << blockprime << block
          if(!mod.attempt_decrypt(new_block))
             if(@verbose)
              puts("Hit a false positive!")
             end
            false_positive = true 
          end
        end
        # If it's not a false positive, return the character we just found
        if(!false_positive)
          return current_guess
        end
      end
    end
  if (@verbose)
    puts("Couldn't find a valid encoding!")
  end
  end
  def Poracle.do_block(mod, blocks, i, has_padding = false, verbose = false, file)
    # Default result to all question marks - this lets us show it to the user
    # in a pretty way
	count=0
    block=blocks[i]
    previous=blocks[i-1]
    # It doesn't matter what we default the plaintext to, as long as it's long
    # enough
    plaintext = Array.new(mod.blocksize, 0)
    # Loop through the string from the end to the beginning
    (block.length - 1).step(0, -1) do |character|
      # When character is below 0, we've arrived at the beginning of the string
      if(character >= block.length)
        raise("Could not decode!")
      end

      # Try to be intelligent about which character we guess first, to save
      # requests
      set = nil
      if(character == block.length - 1 && has_padding)
        # For the last character of a block with padding, guess the padding
        set = generate_set([1.chr])
      elsif(has_padding && character >= block.length - plaintext[block.length - 1].ord)
        # If we're still in the padding, guess the proper padding value (it's
        # known)
        set = generate_set([plaintext[block.length - 1]])
      elsif(mod.respond_to?(:character_set))
        # If the module provides a character_set, use that
        set = generate_set(mod.character_set)
      else
        # Otherwise, use a common English ordering that I generated based on
        # the Battlestar Galactica wikia page (yes, I'm serious :) )
        set = generate_set(' eationsrlhdcumpfgybw.k:v-/,CT0SA;B#G2xI1PFWE)3(*M\'!LRDHN_"9UO54Vj87q$K6zJY%?Z+=@QX&|[]<>^{}'.chars.to_a)
      end
      # Break the current character (this is the secret sauce)
      c = find_character(mod, character, blocks, i, plaintext,  set, verbose)
      plaintext[character] = c.nil?? 0:c
      if (c.nil?)
        puts "Skipping block #{i}"
      break
      end
	  count+=1
      if(verbose)
		puts "#{i} --> #{plaintext}"		
      end
	  if (count==mod.blocksize)
		File.open(file, 'a') do |f|		
		f.puts "#{i},#{plaintext.pack('C*').force_encoding('utf-8')}"	
		end
	  end

    end
    return plaintext
  end

  # This is the public interface. Call this with the mod, data, and optionally
  # the iv, and it'll return the decrypted text or throw an error if it can't.
  # If no IV is given, it's assumed to be NULL (all zeroes).
  def Poracle.decrypt(mod, data, iv = nil, verbose = true, start = data.length / mod.blocksize, file)
    # Default to a nil IV
    
    if(!iv.nil?)
      iv =iv.unpack('C*')
      data  = iv + data
    end
    # Add the IV to the start of the encrypted string (for simplicity)
      
    blockcount = data.length / mod.blocksize

    # Split the data into blocks - using unpack is kinda weird, but it's the
    # best way I could find that isn't Ruby 1.9-specific
    blocks = data.each_slice(mod.blocksize).to_a
    i = 0
    blocks.each do |b|
      i = i + 1
    end
    # Decrypt all the blocks - from the last to the first (after the IV).
    # This can actually be done in any order.
    result = Array.new
    is_last_block = (start==blockcount-1 ? true:false)
     i=start
      # Process this block - this is where the magic happens
      new_result = do_block(mod, blocks, i, is_last_block, verbose, file)
      if(new_result.nil?)
        return nil
      end
      is_last_block = false
      result = new_result + result
    # Validate and remove the padding
    
    pad_bytes = result[result.length - 1]
    if(result[result.length - ord(pad_bytes), result.length - 1] != pad_bytes * ord(pad_bytes))
      return result
    end

    # Remove the padding
    result = result[0, result.length - ord(pad_bytes)]
    return result
  end

end 