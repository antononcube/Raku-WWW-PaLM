use WWW::PaLM::Models;
use WWW::PaLM::Request;
use JSON::Fast;

unit module WWW::PaLM::GenerateMessage;


#============================================================
# Message generation
#============================================================

my $messageGenerationStencil = q:to/END/;
{
  "model": "$model",
  "prompt": "$prompt",
  "safetySettings": @safety-settings,
  "maxOutputTokens": $max-output-tokens,
  "temperature": $temperature,
  "candidateCount": $candidate-count,
  "topP" : $top-p,
  "topK" : $top-k
}
END



#| PaLM completion access.
our proto PaLMGenerateMessage($prompt is copy,
                              :$context = Whatever,
                              :$examples = Whatever,
                              :$author = Whatever,
                              :$model = Whatever,
                              :$temperature = Whatever,
                              Numeric :$top-p = 1,
                              :$top-k = Whatever,
                              UInt :n($candidate-count) = 1,
                              :api-key(:$auth-key) = Whatever,
                              UInt :$timeout= 10,
                              :$format= Whatever,
                              Str :$method = 'tiny') is export {*}

#| PaLM completion access.
multi sub PaLMGenerateMessage(Str $message, *%args) {
    return PaLMGenerateMessage([$message,], |%args);
}

#| PaLM completion access.
multi sub PaLMGenerateMessage(@messages,
                              :$context is copy = Whatever,
                              :$examples is copy = Whatever,
                              :$author is copy = Whatever,
                              :$model is copy = Whatever,
                              :$temperature is copy = Whatever,
                              Numeric :$top-p = 1,
                              :$top-k is copy = Whatever,
                              UInt :n($candidate-count) = 1,
                              :api-key(:$auth-key) is copy = Whatever,
                              UInt :$timeout= 10,
                              :$format is copy = Whatever,
                              Str :$method = 'tiny') {

    #------------------------------------------------------
    # Process $author
    #------------------------------------------------------

    if $author.isa(Whatever) { $author = 'user'; }
    die "The argument \$author is expected to be a string or Whatever."
    unless $author ~~ Str:D;

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------

    if $model.isa(Whatever) { $model = 'chat-bison-001'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ palm-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ palm-known-models;

    #------------------------------------------------------
    # Process $temperature
    #------------------------------------------------------
    if $temperature.isa(Whatever) { $temperature = 0.35; }
    die "The argument \$temperature is expected to be Whatever or number between 0 and 1."
    unless $temperature ~~ Numeric:D && 0 ≤ $temperature ≤ 1;

    #------------------------------------------------------
    # Process $top-p
    #------------------------------------------------------
    if $top-p.isa(Whatever) { $top-p = 1.0; }
    die "The argument \$top-p is expected to be Whatever or number between 0 and 1."
    unless $top-p ~~ Numeric:D && 0 ≤ $top-p ≤ 1;

    #------------------------------------------------------
    # Process $top-k
    #------------------------------------------------------
    die "The argument \$top-k is expected to be Whatever or a positive integer."
    unless $top-k.isa(Whatever) || $top-k ~~ UInt;

    #------------------------------------------------------
    # Process $candidate-count
    #------------------------------------------------------
    die "The argument \$candidate-count is expected to be a positive integer."
    unless 0 < $candidate-count ≤ 8;

    #------------------------------------------------------
    # Process $context
    #------------------------------------------------------
    die "The argument \$context is expected to be a string or Whatever."
    unless $context.isa(Whatever) || $context ~~ Str:D;

    #------------------------------------------------------
    # Process $examples
    #------------------------------------------------------

    if $examples ~~ Pair:D { $examples = [$examples,] }
    if $examples ~~ Map:D { $examples = $examples.pairs }

    die "The argument \$examples is expected to be a string-to-string Pair, a Positional of string-to-string Pairs, or Whatever."
    unless $examples.isa(Whatever) ||
            $examples ~~ Positional && $examples.all ~~ Pair:D;

    # Instead making above this check:
    #   ... && $examples.Hash.keys.all ~~ Str:D && $examples.Hash.values.all ~~ Str:D;
    # we turn the Pair elements into string below.

    #------------------------------------------------------
    # Messages
    #------------------------------------------------------

    @messages = @messages.map( -> $r {
        given $r {
            when $_ ~~ Pair && $_.key ∉ <context examples> {
                %(author => $_.key, content => $_.value)
            }
            when $_ ~~ Pair && $_.key eq 'context' && $context.isa(Whatever) {
                $context = $_.value; Empty
            }
            when $_ ~~ Pair && $_.key eq 'examples' && $examples.isa(Whatever) {
                $examples = $_.value; Empty
            }
            default {
                %(:$author, content => $_.Str)
            }
        }
    }).Array;

    my $prompt = %(:@messages);

    if $context ~~ Str:D {
        $prompt = %(:$context, |$prompt);
    }

    if $examples ~~ Positional {
        $examples = $examples.map({ %( input => %( content => $_.key.Str), output => %( content => $_.value.Str)) }).Array;
        $prompt = %(:$examples, |$prompt);
    }

    #------------------------------------------------------
    # Make PaLM URL
    #------------------------------------------------------

    my %body = :$model, :$prompt, :$temperature, topP => $top-p, candidateCount => $candidate-count;

    if !$top-k.isa(Whatever) { %body<topK> = $top-k; }

    my $url = "https://generativelanguage.googleapis.com/v1beta2/models/{ $model }:generateMessage";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return palm-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
