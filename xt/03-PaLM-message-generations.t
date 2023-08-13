use v6.d;

use lib '.';
use lib './lib';

use WWW::PaLM;
use Test;

my $method = 'tiny';

plan *;

## 1
ok palm-generate-message('Generate Raku code for a loop over a list',
        context => 'You are a guru of the programming language Raku.');

## 2

my @examples = [
    "What's up?" => "What isn't up?? The sun rose another day, the world is bright, anything is possible! ☀️",
    "I'm kind of bored" => "How can you be bored when there are so many fun, exciting, beautiful experiences to be had in the world? 🌈"
];

ok palm-generate-message(
        'I do not want to exercise today...',
        context => "Be a motivational coach who's very inspiring",
        :@examples);

## 3
ok palm-generate-message(
        'I do not want to exercise today...',
        context => "Be a motivational coach who's both inspiring and cynical.",
        examples => @examples.head);


done-testing;
