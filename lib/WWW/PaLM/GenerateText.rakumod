use v6.d;

use WWW::PaLM::Models;
use WWW::PaLM::Request;
use JSON::Fast;

unit module WWW::PaLM::GenerateText;


#============================================================
# Text generation
#============================================================

my $textCompletitionStencil = q:to/END/;
{
  "model": "$model",
  "prompt": "$prompt",
  "safetySettings": @safety-settings,
  "stopSequences": @stop-sequences,
  "maxOutputTokens": $max-output-tokens,
  "temperature": $temperature,
  "candidateCount": $candidate-count,
  "topP" : $top-p,
  "topK" : $top-k
}
END



#| PaLM completion access.
our proto PaLMGenerateText($prompt is copy,
                           :$model is copy = Whatever,
                           :max-tokens(:$max-output-tokens) is copy = Whatever,
                           :$temperature is copy = Whatever,
                           Numeric :$top-p = 1,
                           :$top-k is copy = Whatever,
                           UInt :n(:$candidate-count) = 1,
                           :$safety-settings = Whatever,
                           :$stop-sequence = Whatever,
                           :$auth-key is copy = Whatever,
                           UInt :$timeout= 10,
                           :$format is copy = Whatever,
                           Str :$method = 'tiny') is export {*}

#| PaLM completion access.
multi sub PaLMGenerateText(@prompts, *%args) {
    return @prompts.map({ PaLMGenerateText($_, |%args) }).Array;
}

#| PaLM completion access.
multi sub PaLMGenerateText($prompt is copy,
                           :$model is copy = Whatever,
                           :max-tokens(:$max-output-tokens) is copy = Whatever,
                           :$temperature is copy = Whatever,
                           Numeric :$top-p = 1,
                           :$top-k is copy = Whatever,
                           UInt :n(:$candidate-count) = 1,
                           :$safety-settings is copy = Whatever,
                           :$stop-sequence is copy = Whatever,
                           :$auth-key is copy = Whatever,
                           UInt :$timeout= 10,
                           :$format is copy = Whatever,
                           Str :$method = 'tiny') {

    #------------------------------------------------------
    # Process $prompt
    #------------------------------------------------------
    if $prompt ~~ Str {
        $prompt = %( text => $prompt );
    }

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------

    if $model.isa(Whatever) { $model = 'text-bison-001'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ palm-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ palm-known-models;

    #------------------------------------------------------
    # Process $max-output-tokens
    #------------------------------------------------------
    if $max-output-tokens.isa(Whatever) { $max-output-tokens = 64; }
    die "The argument \$max-output-tokens is expected to be Whatever or a positive integer."
    unless $max-output-tokens ~~ Int && 0 < $max-output-tokens;

    #------------------------------------------------------
    # Process $temperature
    #------------------------------------------------------
    if $temperature.isa(Whatever) { $temperature = 0.35; }
    die "The argument \$temperature is expected to be Whatever or number between 0 and 1."
    unless $temperature ~~ Numeric && 0 ≤ $temperature ≤ 1;

    #------------------------------------------------------
    # Process $top-p
    #------------------------------------------------------
    if $top-p.isa(Whatever) { $top-p = 1.0; }
    die "The argument \$top-p is expected to be Whatever or number between 0 and 1."
    unless $top-p ~~ Numeric && 0 ≤ $top-p ≤ 1;

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
    # Process $safety-settings
    #------------------------------------------------------
    if !$safety-settings.isa(Whatever) {
        die "The argument \$safety-settings is expected to be a map, a list maps, or Whatever."
        unless $safety-settings ~~ Map || $safety-settings ~~ Positional && $safety-settings.all ~~ Map;

        if $safety-settings ~~ Map {
            $safety-settings = [$safety-settings, ];
        }
    }

    #------------------------------------------------------
    # Process $stop-sequence
    #------------------------------------------------------
    if !$stop-sequence.isa(Whatever) {
        die "The argument \$stop-sequence is expected to be a string, a list strings, or Whatever."
        unless $stop-sequence ~~ Str || $stop-sequence ~~ Positional && $stop-sequence.all ~~ Str;
    }

    $stop-sequence = do given $stop-sequence {
        when Str:D { [$_, ]}
        when Empty { Whatever }
        when $_ ~~ Positional && $_.elems { $_ }
        when $_ ~~ Iterable   && $_.elems { $_.Array }
        default { Whatever }
    }

    #------------------------------------------------------
    # Make PaLM URL
    #------------------------------------------------------

    my %body = :$model, :$prompt, maxOutputTokens => $max-output-tokens, :$temperature,
               topP => $top-p, candidateCount => $candidate-count;

    if !$stop-sequence.isa(Whatever) { %body<stopSequence> = $stop-sequence; }
    if !$safety-settings.isa(Whatever) { %body<safetySettings> = $safety-settings; }
    if !$top-k.isa(Whatever) { %body<topK> = $top-k; }

    my $url = "https://generativelanguage.googleapis.com/v1beta2/models/{$model}:generateText";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return palm-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
