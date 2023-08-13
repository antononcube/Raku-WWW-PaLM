#!/usr/bin/env raku
use v6.d;

use WWW::PaLM;

# Here we follow the "motivational coach" example here:
# https://developers.generativeai.google/tutorials/chat_quickstart#examples

# An array of "ideal" interactions between the user and the model
my @examples = [
    "What's up?" => "What isn't up?? The sun rose another day, the world is bright, anything is possible! ☀️",
    "I'm kind of bored" => "How can you be bored when there are so many fun, exciting, beautiful experiences to be had in the world? 🌈"
];

my $res2 = palm-generate-message(
        "I'm too tired to go the gym today",
        context => "Be a motivational coach who's very inspiring", :@examples,
        format => 'values', temperature => 0.6);

say $res2