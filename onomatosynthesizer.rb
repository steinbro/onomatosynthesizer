#! /usr/bin/env ruby
require 'rubygems'
require 'midilib/sequence'
include MIDI

# Definitions of all valid percussive sounds (translations to MIDI drum note
# numbers).
$sounds = {
  "." => 0,                                 # rest
  "doom" => 35, "boom" => 36,               # bass drum
  "tik"  => 37, "rik"  => 38,               # snare
  "pah"  => 39, "kah"  => 40,               # clap/hit
  "chik" => 42, "pss"  => 44, "wsh"  => 46, # hi hat
  "krsh" => 49, "psh"  => 51, "dang" => 53, # cymbals
  "dee"  => 50, "dih"  => 48, "dah"  => 47, # toms
  "doh"  => 45, "doo"  => 43, "duh"  => 41, # more toms
  "ding" => 67, "dong" => 68,               # agogo
  "bum"  => 63, "bom"  => 64,               # bongo
  "ash"  => 52,                             # cymbal
  "plik" => 54,                             # tambourine
  "shik" => 70,                             # maracas
  "goh"  => 56,                             # cowbell
  "dddd" => 58,                             # vibraslap
  "twih" => 71, "twee" => 72,               # whistle
  "gih"  => 73, "grrr" => 74,               # guiro
  "dink" => 75,                             # claves
  "nik"  => 76, "nok"  => 77,               # wood block
  "uhh"  => 78, "err"  => 79,               # cuica
  "twik" => 80, "tink" => 81                # triangle
}

# a bunch of nice rhythms
$eight = ["BOOM .    .    boom .    .    .    boom",
          "chik chik KAH  chik chik PSS  KAH  chik",
          "tik  .    tik  tik  .    tik  tik  tik",
          "plik .    .    plik .    .    plik .",
          "dang .    .    pss  pss  .    dang .",
          "DOOM .    .    boom DOOM .    .    .",
          ".    .    bum  .    .    tik  bom  bom",
          "goh  .    goh  .    goh  .    goh  ."]

$sixteen = ["chik .    chik .    chik .    chik .    chik .    chik .    chik .    chik .",
            "boom .    .    .    KAH  .    .    boom .    kah  boom .    KAH  .    .    .",
            "dang .    dang dang .    .    dang .    dang .    dang .    dang .    dang .",
            "doom .    .    .    kah  .    .    .    .    .    doom .    .    .    doom .",
            "BOOM .    chik BOOM .    boom chik .    BOOM .    chik BOOM .    boom chik BOOM",
            "tik  .    .    tik  .    .    tik  .    tik  .    .    tik  .    .    tik  .",
            ".    .    dink .    dink .    .    .    dink .    .    dink .    .    dink .",
            "ding .    ding .    dong dong .    ding .    ding .    ding dong .    dong ."]

# A Whack is simply a sound and a volume. It is initially fed a VPAL token.
class Whack
  def initialize(beat)
    @volume = 40
    # sound is twice as loud if beat is written in uppercase letters
    @volume = 80 if beat.downcase != beat
    # ensure percussive sound translates to a MIDI note number
    if not $sounds.has_key? beat.downcase
      raise RuntimeError, "\"#{beat}\" is not a valid percussive sound."
    end
    @sound = $sounds[beat.downcase]
  end
  
  attr_reader :sound, :volume
  
  def play
    NoteOnEvent.new(9, @sound, @volume, 0)
  end
  
  def stop(length)
    NoteOffEvent.new(9, @sound, @volume, length)
  end
end

module Onomatosynthesizer
  class << self
    # Takes a single- or multi-line input of VPAL and generates an array of beats,
    # each containing all whacks played simultaneously on each beat, where each 
    # whack is defined by a sound and volume.
    def parse(input)
      parts = input.split("\n").collect{|p| p.squeeze(" ").split(" ")}
      # verify that each part has the same number of beats
      parts.size.times do |i|
        if parts[i].size != parts[0].size
          raise RuntimeError, "The first line has #{parts[0].size} beats, but line #{i+1} has #{parts[i].size}."
        end
      end
      # create an array of arrays of hits that happen at each beat
      code = Array.new
      parts[0].size.times do |i|
        code[i] = Array.new
        parts.each do |hits|
          code[i].push Whack.new(hits[i])
        end
      end
      code
    end

    # Generates a complete MIDI sequence given a string of VPAL, a tempo, and a
    # number of times to repeat.
    def generate(input, tempo, repeat)
      # check for valid tempo
      if tempo < 1
        raise RuntimeError, "You might want to go a little faster."
      end
      seq = Sequence.new()
      # metadata track
      track = Track.new(seq)
      seq.tracks << track
      track.events << Tempo.new(Tempo.bpm_to_mpq(tempo))
      track.events << MetaEvent.new(META_SEQ_NAME, "Vocal Percussion Assembly")
      # percussion track
      track = Track.new(seq)
      seq.tracks << track
      track.name = 'Percussion'
      track.instrument = 'Drum Kit'

      code = parse(input)
      repeat.times do |iteration|
        code.each do |beat|
          # sound all the notes at this beat simultaneously...
          beat.each do |whack|
            track.events << whack.play
          end
          # ...then stop them all simultaneously
          beat.each do |whack|
            # note length doesn't directly apply to drum sounds, but the notes need 
            # to have a definite end. we divide by beat.length so that all notes
            # end by then end of the beat (we are not rewinding, so note ends are
            # sequential)
            track.events << whack.stop(seq.note_to_delta('eighth') / beat.length)
          end
        end
      end
      seq
    end

    def create(input, tempo, repeat, output)
      File.open(output, 'wb') do |file|
        generate(input, tempo, repeat).write(file)
      end
    end
  end
end

def randombeat
  # pick either an eight- or sixteen-beat set of rhythms
  set = [$eight, $sixteen][rand(2)]
  result = String.new
  # between 2 and 4 rhythm lines
  (2 + rand(3)).times do
    # add a random rhythm to the result, and prevent it from being chosen again
    result += set.delete_at(rand(set.length)) + "\n"
  end
  result
end


if ARGV.size != 4
  puts "usage: #{$0} <vpal_file> <tempo> <repeat> <midi_file>"
  exit(-1)
end

vpal = File.read(ARGV[0])
tempo = ARGV[1].to_i
repeat = ARGV[2].to_i
outfile = ARGV[3]

begin
  Onomatosynthesizer.create(vpal, tempo, repeat, outfile)
rescue RuntimeError
  puts "Oops! #{$!}"
end
