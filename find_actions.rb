require 'audio_monster'
require 'google_speech'
require 'fuzzy_match'

AudioMonster.logger = Logger.new('/dev/null')
GoogleSpeech.logger = Logger.new('/dev/null')

logger = Logger.new(STDOUT)

terms = [
  'promo',
  'offer',
  'sponsor',
  'advertiser',
  'fund',
  'code',
  'kickstarter',
  'event',
  'patreon',
  'support',
  'tickets'
]

groupings = [
  [/kick/i, /starter/i],
  [/live/i, /event/i],
  [/live/i, /show/i],
  [/dot/i, /com/i],
  [/dot/i, /org/i],
  [/sponsored/i, /by/i],
  [/offer/i, /code/i],
  [/made/i, /possible/i]
]

threshold = 0.6
matcher = FuzzyMatch.new(terms, groupings: groupings)

Dir.glob('/Users/andrew/Downloads/Archive/*').each do |file|
  logger.info "Checking #{file}"
  wav_file = AudioMonster.create_temp_file(File.basename(file) + '.wav')
  AudioMonster.decode_audio(file, wav_file.path)
  transcriber = GoogleSpeech::Transcriber.new(wav_file, overlap: 1, chunk_duration: 5)
  t = transcriber.transcribe
  # logger.info "***** DONE:\n#{t.inspect}"

  t.each do |line|
    logger.info "  #{line[:start_time]} - #{line[:end_time]}: #{line[:text]}"
    words = line[:text].split
    last_word = ""
    words.each do |word|

      words = "#{last_word} #{word}"
      last_word = word

      match = matcher.find_with_score(word)
      if match && (match[1..2].max > threshold)
        logger.info "    * Match #{match.inspect} ~ #{word}\n\t#{line.inspect}"
      else
        match = matcher.find_with_score(words)
        if match && (match[1..2].max > threshold)
          logger.info "    * Matches #{match.inspect} ~ #{words}\n\t#{line.inspect}"
        end
      end
    end
  end
end
