The Onomatosynthesizer is an unusual kind of software drum machine.
It's a combined interpreter and NIDI sequencer for a cute domain-specific
language for percussion.

Take a look in the samples/ directory to see how to generate some
familiar beats. You'll need [the midilib library](http://midilib.rubyforge.org)
to run the scripts, and any MIDI player should be capable of handling the
output.

Beats are expressed in Vocal Percussion Assmebly Language (VPAL), which gets
its name from its similarity to machine code, consisting of numerous
instructions that are each only three or four characters in length. It's
simple:

 * A rhythm is a line of sounds separated by one or more spaces.
 * Every sound gets played for the same length of time.
 * Each line is a different part that is played at the same time as the other
parts.
 * A rhythm may have any length, but each line must have the same number of
beats. Use extra spaces to line up the beats.

The following list represents all valid percussive sounds. Any sound can be
written in capital letters to increase loudness.

  .                  # rest
  doom, boom         # bass drum
  tik , rik          # snare
  pah , kah          # clap/hit
  chik, pss , wsh    # hi hat
  krsh, psh , dang   # cymbals
  dee , dih , dah    # toms
  doh , doo , duh    # more toms
  ding, dong         # agogo
  bum , bom          # bongo
  ash                # cymbal
  plik               # tambourine
  shik               # maracas
  goh                # cowbell
  dddd               # vibraslap
  twih, twee         # whistle
  gih , grrr         # guiro
  dink               # claves
  nik , nok          # wood block
  uhh , err          # cuica
  twik, tink         # triangle

Though similar in spirit, this tool is a bit more advanced than (and preadtes)
[Google Translate beatboxing](https://github.com/ianli/google-beatbox). This
is polyrhythmic, uses more drumlike sounds, and generates actual audio files.

--
Daniel W. Steinbrook
January 2009
