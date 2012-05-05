package MT::Plugin::AdaptiveEPR;
use strict;
use warnings;
use base 'MT::Plugin';

our $VERSION = '0.01';
our $NAME    = ( split /::/, __PACKAGE__ )[-1];

my $plugin = __PACKAGE__->new({
    name     => $NAME,
    id       => lc $NAME,
    key      => lc $NAME,
    version  => $VERSION,
    author_name => 'masiuchi',
    author_link => 'https://github.com/masiuchi/',
    plugin_link => 'https://github.com/masiuchi/mt-plugin-adaptive-epr',
    description => 'Change EntriesPerRebuild adaptively.',
});
MT->add_plugin( $plugin );

sub init_registry {
    my ( $p ) = @_;
    my $pkg = '$' . $NAME . '::' . $NAME;
    $p->registry({
        applications => {
            cms => {
                methods => {
                    rebuild_phase => $pkg . '::CMS::rebuild_phase',
                },
            },
        },
        callbacks => {
            pre_build       => $pkg . '::CMS::pre_build',
            rebuild_options => $pkg . '::CMS::rebuild_opts',
            post_build      => $pkg . '::CMS::post_build',
        },
    });
}

1;
__END__
