use v6.d;

use lib '.';
use lib './lib';

use WWW::PaLM;
use Test;

my $method = 'tiny';

plan *;

## 1
ok palm-prompt(path => 'models', :$method);

## 2
ok palm-prompt('What is the most important word in English today?', :$method);

## 3
isa-ok
        palm-prompt('What is the most important word in English today?', :$method, format => 'values'),
        Str,
        'string result';

## 4
ok palm-prompt('Generate Raku code for a loop over a list', path => 'generateText', model => Whatever, :$method);

## 5
ok palm-prompt('Generate Raku code for a loop over a list', path => 'generateMessage', model => 'chat-bison-001',
        :$method);

done-testing;
