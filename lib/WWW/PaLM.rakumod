use v6.d;

use JSON::Fast;
use HTTP::Tiny;

unit module WWW::PaLM;

use WWW::PaLM::EmbedText;
use WWW::PaLM::GenerateMessage;
use WWW::PaLM::GenerateText;
use WWW::PaLM::Models;


#===========================================================
#| PaLM audio transcriptions and translations access.
#our proto palm-audio(|) is export {*}
#
#multi sub palm-audio(**@args, *%args) {
#    return WWW::PaLM::Audio::OpenAIAudio(|@args, |%args);
#}

#===========================================================
#| PaLM chat and text completions access.
#| C<:type> -- type of text generation, one of 'chat', 'text', or Whatever;
#| C<:model> -- LLM model to use.
#| C<*%args> -- additional arguments, see C<palm-generate-message> and C<palm-generate-text>.
our proto palm-generation(|) is export {*}

multi sub palm-generation($prompt,
                          :$type is copy = Whatever,
                          :$model is copy = Whatever,
                          *%args) {

    #------------------------------------------------------
    # Process $type
    #------------------------------------------------------
    if $type.isa(Whatever) {
        $type = do given $model {
            when Whatever { 'text' }
            when palm-is-chat-completion-model($_) { 'chat' };
            when $_.starts-with('text-') { 'text' };
            default { 'text' }
        }
    }
    die "The argument \$type is expected to be one of 'chat', 'text', or Whatever."
    unless $type ∈ <chat text>;

    #------------------------------------------------------
    # Process $model
    #------------------------------------------------------
    if $model.isa(Whatever) { $model = $type eq 'text' ?? 'text-bison-001' !! 'chat-bison-001'; }
    die "The argument \$model is expected to be Whatever or one of the strings: { '"' ~ palm-known-models.keys.sort.join('", "') ~ '"' }."
    unless $model ∈ palm-known-models;

    if $type eq 'chat' {
        return WWW::PaLM::GenerateMessage::PaLMGenerateMessage($prompt, :$model, |%args);
    } else {
        return WWW::PaLM::GenerateText::PaLMGenerateText($prompt, :$model, |%args);
    }
}

#===========================================================
#| PaLM chat completions access.
#| C<$prompt> -- message to the LLM;
#| C<:$context> -- context;
#| C<:$examples> -- examples;
#| C<:$author> -- author; no more two authors per chat;
#| C<:$model> -- model;
#| C<:$temperature> -- number between 0 and 1;
#| C<:$top-p> -- top probability of tokens to use in the answer;
#| C<$top-k> -- top-K top tokens to use;
#| C<:n($candidate-count)> -- number of answers;
#| C<:api-key($auth-key)> -- authorization key (API key);
#| C<:$timeout> -- timeout;
#| C<:$format> -- format to use in answers post processing, one of <values json hash asis>);
#| C<:$method> -- method to WWW API call with, one of <curl tiny>.
our proto palm-generate-message(|) is export {*}

multi sub palm-generate-message(**@args, *%args) {
    return WWW::PaLM::GenerateMessage::PaLMGenerateMessage(|@args, |%args);
}

#===========================================================
#| PaLM embeddings access.
our proto palm-embed-text(|) is export {*}

multi sub palm-embed-text(**@args, *%args) {
    return WWW::PaLM::EmbedText::PaLMEmbedText(|@args, |%args);
}

#===========================================================
#| PaLM image generation access.
#our proto palm-create-image(|) is export {*}
#
#multi sub palm-create-image(**@args, *%args) {
#    return WWW::PaLM::ImageGenerations::OpenAICreateImage(|@args, |%args);
#}

#===========================================================
#| PaLM models access.
our proto palm-models(|) is export {*}

multi sub palm-models(*%args) {
    return WWW::PaLM::Models::PaLMModels(|%args);
}

#===========================================================
#| PaLM moderations access.
#our proto palm-moderation(|) is export {*}
#
#multi sub palm-moderation(**@args, *%args) {
#    my %args2 = %args.grep({ $_.key != 'format'});
#
#    my $res = WWW::PaLM::GenerateText::PaLMGenerateText(|@args, |%args, format => 'hash');
#
#    $res = $res<candidates>.map({ $_<safetyRatings> }).Array;
#
#    #return @res.elems > 1 ?? @res !! @res[0];
#    return $res;
#}

#===========================================================
#| PaLM text completions access.
#| C<$prompt> -- message to the LLM;
#| C<:$model> -- model;
#| C<:max-tokens(:$max-output-tokens)> -- max number of tokens of the results;
#| C<:$temperature> -- number between 0 and 1;
#| C<:$top-p> -- top probability of tokens to use in the answer;
#| C<$top-k> -- top-K top tokens to use;
#| C<:n($candidate-count)> -- number of answers;
#| C<:$safety-settings> -- safety (or moderation) settings;
#| C<:api-key($auth-key)> -- authorization key (API key);
#| C<:$timeout> -- timeout;
#| C<:$format> -- format to use in answers post processing, one of <values json hash asis>);
#| C<:$method> -- method to WWW API call with, one of <curl tiny>.
our proto palm-generate-text(|) is export {*}

multi sub palm-generate-text(**@args, *%args) {
    return WWW::PaLM::GenerateText::PaLMGenerateText(|@args, |%args);
}

#===========================================================
#| PaLM utilization for finding textual answers.
#our proto palm-find-textual-answer(|) is export {*}
#
#multi sub palm-find-textual-answer(**@args, *%args) {
#    return WWW::PaLM::FindTextualAnswer::OpenAIFindTextualAnswer(|@args, |%args);
#}


#============================================================
# Playground
#============================================================

#| PaLM maker-suite access.
#| C<:path> -- end point path;
#| C<:api-key(:$auth-key)> -- authorization key (API key);
#| C<:timeout> -- timeout
#| C<:$format> -- format to use in answers post processing, one of <values json hash asis>);
#| C<:$method> -- method to WWW API call with, one of <curl tiny>,
#| C<*%args> -- additional arguments, see C<palm-generate-message> and C<palm-generate-text>.
our proto palm-prompt($text is copy = '',
                      Str :$path = 'generateText',
                      :api-key(:$auth-key) is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny',
                      *%args
                      ) is export {*}

#| PaLM maker-suite access.
multi sub palm-prompt(*%args) {
    return palm-prompt('', |%args);
}

#| PaLM maker-suite access.
multi sub palm-prompt(@texts, *%args) {
    return @texts.map({ palm-prompt($_, |%args) });
}

#| PaLM maker-suite access.
multi sub palm-prompt($text is copy,
                      Str :$path = 'generateText',
                      :api-key(:$auth-key) is copy = Whatever,
                      UInt :$timeout= 10,
                      :$format is copy = Whatever,
                      Str :$method = 'tiny',
                      *%args
                      ) {

    #------------------------------------------------------
    # Dispatch
    #------------------------------------------------------

    given $path {
        when $_ eq 'models' {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/models';
            return palm-models(:$auth-key, :$timeout);
        }
        when $_ ∈ <message generateMessage message-generation> {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/{model=models/*}:generateMessage';
            my $expectedKeys = <model prompt temperature top-p top-k n candidate-count context examples>;
            return palm-generate-message($text,
                    |%args.grep({ $_.key ∈ $expectedKeys }).Hash,
                    :$auth-key, :$timeout, :$format, :$method);
        }
        when $_ ∈ <text generateText text-generation> {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/{model=models/*}:generateText';
            my $expectedKeys = <model prompt max-tokens max-output-tokens temperature top-p top-k n candidate-count stop-sequence safety-settings>;
            return palm-generate-text($text,
                    |%args.grep({ $_.key ∈ $expectedKeys }).Hash,
                    :$auth-key, :$timeout, :$format, :$method);
        }
        when $_ ∈ <embed embedding embedText text-embedding text-embeddings> {
            # my $url = 'https://generativelanguage.googleapis.com/v1beta2/{model=models/*}:embedText';
            return palm-embed-text($text,
                    |%args.grep({ $_.key ∈ <model> }).Hash,
                    :$auth-key, :$timeout, :$format, :$method);
        }
        default {
            die 'Do not know how to process the given path.';
        }
    }
}
