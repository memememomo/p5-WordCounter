package WordCounter;
use strict;
use warnings;
use utf8;
use Encode;
use Encode::Guess;
use Mojo::UserAgent;

our $VERSION = '0.01';


sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    Carp::croak('yahoo_appid is needed!') unless defined $args{yahoo_appid};
    my $base_url = $args{yahoo_base_url}
        || 'http://jlp.yahooapis.jp/MAService/V1/parse';

    my $params = {
        appid    => $args{yahoo_appid},
        base_url => $base_url,
        ua       => Mojo::UserAgent->new,
    };

    return bless $params, $class;
}

sub fetch_and_count_word {
    my ($self, $url) = @_;
    return $self->count_word(
        $self->fetch_content($url)
    );
}

sub fetch_content {
    my ($self, $url) = @_;

    my $tx = $self->{ua}->get($url);
    return unless $tx->success;

    my $sentence = '';

    my $dom = $tx->res->dom;

    $dom->find('title')->each(
        sub {
            my ($e) = @_;
            $sentence .= $e->text;
        }
    );

    $dom->find('meta')->each(
        sub {
            my ($e) = @_;
            my $name = $e->attrs('name');
            if ( $name && ( $name eq 'keywords' || $name eq 'description' ) ) {
                $sentence .= $e->attrs('content');
            }
        }
    );

    $dom->find('img')->each(
        sub {
            my ($e) = @_;
            my $alt = $e->attrs('alt');
            if ( $alt ) {
                $sentence .= $alt;
            }
        }
    );

    my $body = $tx->res->dom->at('body');

    $body->find('script')->each(
        sub {
            $body = $body->at('script')->replace('<h1></h1>')->root;
        }
    );

    $body =~ s/<.*?>//g;
    $body =~ s/\r\n//g;
    $body =~ s/\n//g;
    $sentence .= $body;

    my $enc = guess_encoding($sentence, qw/euc-jp shiftjis 7bit-jis/);

    return decode($enc, $sentence);
}

sub count_word {
    my ($self, $sentence, $filter) = @_;

    $filter ||= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12];

    my $uniq_filter = join('|', @$filter);

    my $tx =
        $self->{ua}->post_form(
            $self->{base_url},
            {
                results => 'uniq',
                appid => $self->{appid},
                uniq_filter => $uniq_filter,
                sentence => $sentence
            }
        );
    die "Error access api" unless $tx->success;

    my @counter;
    my $total = 0;

    my $dom = $tx->res->dom;
    $dom->find('uniq_result word_list word')->each(
        sub {
            my ($e) = @_;

            my %col = (
                count   => $e->count->text,
                surface => $e->surface->text,
                pos     => $e->pos->text,
            );
            $total += $col{count};

            push @counter, \%col;
        }
    );

    for my $c ( @counter ) {
        $c->{ratio} = $c->{count} / $total;
    }

    return \@counter;
}

1;
__END__

=head1 NAME

WordCounter -

=head1 SYNOPSIS

  use WordCounter;

=head1 DESCRIPTION

WordCounter is

=head1 AUTHOR

memememomo E<lt>memememomo {at} gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
