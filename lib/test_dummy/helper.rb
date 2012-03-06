module TestDummy::Helper
  ALPHANUMERIC_SET = [ 'a'..'z', 'A'..'Z', '0'..'9' ].collect(&:to_a).flatten.freeze

  # There are certain substrings that shouldn't be emitted as part of the
  # random strings in order to keep them safe and inoffensive. While this is
  # not exhaustive, it should scrub the random strings enough that it would
  # be a stretch to see something wrong with them, at least in English.
  AVOID_SUBSTRINGS = Regexp.new(%w[
    ass a55 as5 a5s bal bit btc b1t bul bll bls but btu chi ch1 cun cnt dic dik d1c d1k fag f4g fuc fuk fck fcu fkn fkc kik kyk k1k jer jrk j3r jew j3w mot m0t m07 mth m7h mtr m7r neg n3g ngr nig n1g pak p4k pof p0f poo po0 p00 que qu3 qee q3e qe3 shi sh1 shy stf sht sfu spi spk sp1 tar t4r trd wtf wth xxx
  ].join('|'))
  
  def random_string(length = 12)
    string = nil
    
    while (!string or AVOID_SUBSTRINGS.match(string))
      string = ''

      length.times do
        string << ALPHANUMERIC_SET[rand(ALPHANUMERIC_SET.length)]
      end
      
      # As it's not especially hard to find a random word that passes this
      # simple filter for relatively short strings, the chance of this loop
      # spinning for an extended period of time is very slim.
    end
    
    string
  end

  CONSONANTS = %w[ b c d f g h j k l m n p qu r s t v w x z ch cr fr nd ng nk nt ph pr rd sh sl sp st th tr ]
  VOWELS = %w[ a e i o u y ]

  def random_phonetic_string(length = 12)
    string = nil
    
    while (!string or AVOID_SUBSTRINGS.match(string))
      string = ''

      length.times do |i|
        string << ((i % 2 != 0) ? CONSONANTS[rand(CONSONANTS.size)] : VOWELS[rand(VOWELS.size)])
      end
    end
    
    # The generated string is probably longer than it needs to be, so trim
    # to fit.
    string.to_s[0, length]
  end

  extend(self)
end
