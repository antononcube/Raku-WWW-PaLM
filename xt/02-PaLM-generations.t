use v6.d;

use lib '.';
use lib './lib';

use WWW::PaLM;
use Test;

my $method = 'tiny';

plan *;

## 1
ok palm-generation('Generate Raku code for a loop over a list',
        type => Whatever, model => Whatever, :$method);

## 2
ok palm-generation('Generate Raku code for a loop over a list',
        type => Whatever, model => 'text-bison-001', :$method);

## 3
ok palm-generation('Generate Raku code for a loop over a list',
        type => 'text', model => Whatever, :$method);

## 4
ok palm-generation('Generate Raku code for a loop over a list',
        type => 'chat', model => Whatever, :$method);

## 5
dies-ok {
    palm-generation('Generate Raku code for a loop over a list', type => Whatever, model => 'gtp-blah-blah', :$method)
};

## 6
ok palm-generation('Generate Raku code for a loop over a list',
        type => Whatever, model => 'chat-bison-001', :$method);

done-testing;
