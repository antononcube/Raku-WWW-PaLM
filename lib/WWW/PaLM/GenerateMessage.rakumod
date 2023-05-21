use v6.d;

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
                              :$model is copy = Whatever,
                              :$temperature is copy = Whatever,
                              Numeric :$top-p = 1,
                              :$top-k is copy = Whatever,
                              UInt :n($candidate-count) = 1,
                              :$auth-key is copy = Whatever,
                              UInt :$timeout= 10,
                              :$format is copy = Whatever,
                              Str :$method = 'tiny') is export {*}

#| PaLM completion access.
multi sub PaLMGenerateMessage(@prompts, *%args) {
    return @prompts.map({ PaLMGenerateMessage($_, |%args) });
}

#| PaLM completion access.
multi sub PaLMGenerateMessage($prompt is copy,
                              :$model is copy = Whatever,
                              :$temperature is copy = Whatever,
                              Numeric :$top-p = 1,
                              :$top-k is copy = Whatever,
                              UInt :n($candidate-count) = 1,
                              :$auth-key is copy = Whatever,
                              UInt :$timeout= 10,
                              :$format is copy = Whatever,
                              Str :$method = 'tiny') {

    #------------------------------------------------------
    # Process $prompt
    #------------------------------------------------------
    if $prompt ~~ Str {
        $prompt = %( messages => [%(content => $prompt)]);
    }

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
    # Make PaLM URL
    #------------------------------------------------------

    my %body = :$model, :$prompt, :$temperature,
               topP => $top-p, candidateCount => $candidate-count;

    if !$top-k.isa(Whatever) { %body<topK> = $top-k; }

    my $url = "https://generativelanguage.googleapis.com/v1beta2/models/{ $model }:generateMessage";

    #------------------------------------------------------
    # Delegate
    #------------------------------------------------------

    return palm-request(:$url, body => to-json(%body), :$auth-key, :$timeout, :$format, :$method);
}
