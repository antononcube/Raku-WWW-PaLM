use HTTP::Tiny;
use JSON::Fast;

unit module WWW::PaLM::Models;


#============================================================
# Known models
#============================================================
# https://platform.openai.com/docs/api-reference/models/list

my $knownModels = Set.new(<chat-bison-001 text-bison-001 embedding-gecko-001>);


our sub palm-known-models() is export {
    return $knownModels;
}

#============================================================
# Compatibility of models and end-points
#============================================================

# Taken from:
# https://platform.openai.com/docs/models/model-endpoint-compatibility

my %endPointToModels =
        'embedText' => <embedding-gecko-001>,
        'countMessageTokens' => <chat-bison-001 text-bison-001 embedding-gecko-001>,
        'generateMessage' => <chat-bison-001>,
        'generateText' => <text-bison-001>;

#| End-point to models retrieval.
proto sub palm-end-point-to-models(|) is export {*}

multi sub palm-end-point-to-models() {
    return %endPointToModels;
}

multi sub palm-end-point-to-models(Str $endPoint) {
    return %endPointToModels{$endPoint};
}

#| Checks if a given string an identifier of a chat completion model.
proto sub palm-is-chat-completion-model($model) is export {*}

multi sub palm-is-chat-completion-model(Str $model) {
    return $model ∈ palm-end-point-to-models{'generateMessage'};
}

#| Checks if a given string an identifier of a text completion model.
proto sub palm-is-text-completion-model($model) is export {*}

multi sub palm-is-text-completion-model(Str $model) {
    return $model ∈ palm-end-point-to-models{'generateText'};
}

#------------------------------------------------------------
# Invert to get model-to-end-point correspondence.
# At this point (2023-04-14) only the model "whisper-1" has more than one end-point.
my %modelToEndPoints = %endPointToModels.map({ $_.value.Array X=> $_.key }).flat.classify({ $_.key }).map({ $_.key => $_.value>>.value.Array });

#| Model to end-points retrieval.
proto sub palm-model-to-end-points(|) is export {*}

multi sub palm-model-to-end-points() {
    return %modelToEndPoints;
}

multi sub palm-model-to-end-points(Str $model) {
    return %modelToEndPoints{$model};
}

#============================================================
# Models
#============================================================

#| PaLM models.
our sub PaLMModels(:api-key(:$auth-key) is copy = Whatever, UInt :$timeout = 10) is export {
    #------------------------------------------------------
    # Process $auth-key
    #------------------------------------------------------
    # This code is repeated in other files.
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
    # Retrieve
    #------------------------------------------------------
    my Str $url = 'https://generativelanguage.googleapis.com/v1beta2/models';

    my $resp = HTTP::Tiny.get: $url ~ "?key={ %*ENV<PALM_API_KEY> }";

    my $res = from-json($resp<content>.decode);

    return $res<models>.map({ $_<name> });
}
