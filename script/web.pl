use Mojolicious::Lite;
use utf8;
use File::Basename;
use lib dirname(__FILE__) . '/../lib';
use WordCounter;

my $yahoo_appid = '';

my @verbs = (
    { number => 1,  str => '形容詞',   checked => 1 },
    { number => 2,  str => '形容動詞', checked => 1 },
    { number => 3,  str => '感動詞',   checked => 1 },
    { number => 4,  str => '副詞',     checked => 1 },
    { number => 5,  str => '連体詞',   checked => 1 },
    { number => 6,  str => '接続詞',   checked => 1 },
    { number => 7,  str => '接頭辞',   checked => 1 },
    { number => 8,  str => '接尾辞',   checked => 1 },
    { number => 9,  str => '名詞',     checked => 1 },
    { number => 10, str => '動詞',     checked => 1 },
    { number => 11, str => '助詞',     checked => 0 },
    { number => 12, str => '助動詞',   checked => 0 },
    { number => 13, str => '特殊（句読点、カッコ、記号など）', checked => 0 },
);

get '/' => sub {
    my $self = shift;
    $self->stash->{verbs} = \@verbs;
    $self->render();
} => 'index';

post '/wordcount' => sub {
    my $self = shift;

    my @filter;
    my $params = $self->req->params->to_hash;
    for my $name ( %$params ) {
        if ($name =~ /verb_(\d+)/) {
            push @filter, $1;
        }
    }

    my $wc = WordCounter->new(
        yahoo_appid    => $yahoo_appid,
        on_description => $self->param('on_description') || 0,
        on_keywords    => $self->param('on_keywords') || 0,
        on_alt         => $self->param('on_alt') || 0,
        filter         => \@filter
    );

    eval {
        $self->stash->{results} = $wc->fetch_and_count_word($self->param('url'));
    };
    if ( $@ ) {
        die $@;
    }

    $self->render();
} => 'wordcount';


app->start;


