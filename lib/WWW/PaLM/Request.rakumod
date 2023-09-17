use v6.d;

use JSON::Fast;
use HTTP::Tiny;

unit module WWW::PaLM::Request;

#============================================================
# POST Tiny call
#============================================================

proto sub tiny-post(Str :$url!, |) is export {*}

multi sub tiny-post(Str :$url!,
                    Str :$body!,
                    Str :api-key(:$auth-key)!,
                    UInt :$timeout = 10) {
    my $resp = HTTP::Tiny.post: $url ~ "?key={ %*ENV<PALM_API_KEY> // $auth-key }",
            headers => { Content-Type => "application/json" },
            content => $body;

    return $resp<content>.decode;
}

multi sub tiny-post(Str :$url!,
                    :$body! where *~~ Map,
                    Str :api-key(:$auth-key)!,
                    Bool :$json = False,
                    UInt :$timeout = 10) {
    if $json {
        return tiny-post(:$url, body => to-json($body), :$auth-key, :$timeout);
    }
    my $resp = HTTP::Tiny.post: $url ~ "?key={ %*ENV<PALM_API_KEY> // $auth-key}",
            content => $body;
    return $resp<content>.decode;
}


#============================================================
# POST Curl call
#============================================================
my $curlQuery = q:to/END/;
curl $URL?key=$PALM_API_KEY \
    -H 'Content-Type: application/json' \
    -X POST \
    -d '$BODY'
END

multi sub curl-post(Str :$url!, Str :$body!, Str :api-key(:$auth-key)!, UInt :$timeout = 10) {

    my $textQuery = $curlQuery
            .subst('$URL', $url)
            .subst('$PALM_API_KEY', $auth-key)
            .subst('$BODY', $body);
    my $proc = shell $textQuery, :out, :err;

    say $proc.err.slurp(:close);

    return $proc.out.slurp(:close);
}

my $curlFormQuery = q:to/END/;
curl $URL?key=$PALM_API_KEY \
  --header 'Authorization: Bearer $PALM_API_KEY' \
  --header 'Content-Type: multipart/form-data'
END

multi sub curl-post(Str :$url!,
                    :$body! where *~~ Map,
                    Str :api-key(:$auth-key)!,
                    UInt :$timeout = 10) {

    my $textQuery = $curlFormQuery
            .subst('$URL', $url)
            .subst('$PALM_API_KEY', $auth-key)
            .trim-trailing;

    for $body.kv -> $k, $v {
        my $sep = $k eq 'file' ?? '@' !! '';
        $textQuery ~= " \\\n  --form $k=$sep$v";
    }

    my $proc = shell $textQuery, :out, :err;

    say $proc.err.slurp(:close);

    return $proc.out.slurp(:close);
}


#============================================================
# Request
#============================================================

#| PaLM request access.
our proto palm-request(Str :$url!,
                       :$body!,
                       :api-key(:$auth-key) is copy = Whatever,
                       UInt :$timeout= 10,
                       :$format is copy = Whatever,
                       Str :$method = 'tiny',
                       ) is export {*}

#| PaLM request access.
multi sub palm-request(Str :$url!,
                       :$body!,
                       :api-key(:$auth-key) is copy = Whatever,
                       UInt :$timeout= 10,
                       :$format is copy = Whatever,
                       Str :$method = 'tiny'
                       ) {

    #------------------------------------------------------
    # Process $format
    #------------------------------------------------------
    if $format.isa(Whatever) { $format = 'Whatever' }
    die "The argument format is expected to be a string or Whatever."
    unless $format ~~ Str;

    #------------------------------------------------------
    # Process $method
    #------------------------------------------------------
    die "The argument \$method is expected to be a one of 'curl' or 'tiny'."
    unless $method ∈ <curl tiny>;

    #------------------------------------------------------
    # Process $auth-key
    #------------------------------------------------------
    if $auth-key.isa(Whatever) {
        if %*ENV<PALM_API_KEY>:exists {
            $auth-key = %*ENV<PALM_API_KEY>;
        } else {
            note 'Cannot find PaLM authorization key. ' ~
                    'Please provide a valid key to the argument auth-key, or set the ENV variable PALM_API_KEY.';
            $auth-key = ''
        }
    }
    die "The argument auth-key is expected to be a string or Whatever."
    unless $auth-key ~~ Str;

    #------------------------------------------------------
    # Invoke PaLM service
    #------------------------------------------------------
    my $res = do given $method.lc {
        when 'curl' {
            curl-post(:$url, :$body, :$auth-key, :$timeout);
        }
        when 'tiny' {
            tiny-post(:$url, :$body, :$auth-key, :$timeout);
        }
        default {
            die 'Unknown method.'
        }
    }

    #------------------------------------------------------
    # Result
    #------------------------------------------------------
    without $res { return Nil; }

    if $format.lc ∈ <asis as-is as_is> { return $res; }

    if $method ∈ <curl tiny> && $res ~~ Str {
        try {
            $res = from-json($res);
        }
        if $! {
            note 'Cannot convert from JSON, returning "asis".';
            return $res;
        }
    }

    return do given $format.lc {
        when $_ eq 'values' {
            if ($res<candidates>:exists) && ($res<messages>:exists) {
                # Assuming chat completion
                my @res2 = $res<candidates>.map({ $_<content> }).Array;
                @res2.elems == 1 ?? @res2[0] !! @res2;
            } elsif $res<candidates>:exists {
                    # Assuming text completion
                    my @res2 = $res<candidates>.map({ $_<output> }).Array;
                    @res2.elems == 1 ?? @res2[0] !! @res2;
            } elsif $res<embedding> {
                # Assuming text embedding
                $res<embedding><value>;
            } else {
                $res
            }
        }
        when $_ ∈ <whatever hash raku> { $res; }
        when $_ ∈ <json> { to-json($res); }
        default { $res; }
    }
}
