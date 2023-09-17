#!/usr/bin/env raku
use v6.d;

use WWW::PaLM;

.say for %*ENV.grep({ $_.key ~~ / API / });

say '=' x 120;

my $prompt = q:to/END/;
Pretend you are a friendly snowman.
Stay in character for every response you give me.
Keep your responses short.
Feel free to ask me questions, too.
END

my $res;
try {
    $res = palm-generate-message('Who are you?', context => $prompt, format => 'values');
}

if $! {
    say '$!.raku : ', $!.raku;
}

say '-' x 120;

$res = palm-generate-message('Who are you?', context => $prompt, format => 'values');

if $res ~~ Failure {
    say '$res.handled ; ', $res.handled;
    say "Failed with : {$res.exception.payload{'error';'status'}}";
    say "\nException:\n", $res.exception;
} else {
    say $res;
}