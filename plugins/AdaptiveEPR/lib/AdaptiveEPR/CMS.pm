package AdaptiveEPR::CMS;
use strict;
use warnings;

our $DEBUG = 0;

my $Name = ( split /::/, __PACKAGE__ )[0];

my $Key_total_entries = $Name . '::total_entries';
my $Key_orig_epr      = $Name . '::orig_epr';
my $Key_next_epr      = $Name . '::next_epr';

{
    my $Cache_drv;

    sub _cache_drv {
        if ( !$Cache_drv ) {
            require MT::Cache::Session;
            $Cache_drv = MT::Cache::Session->new( @_ );
        }
        return $Cache_drv;
    }
}

sub rebuild_phase {
    my ( $app ) = @_;

    calc_epr( $app->param( 'start_time' ) );

    require MT::CMS::Blog;
    return  MT::CMS::Blog::rebuild_phase( $app );
}

sub pre_build {
    if ( MT->app->param( '__mode' ) eq 'rebuild_new_phase' ) {
        init_epr();
    }
}

sub rebuild_opts { 
    my ( $cb, $app, $opts_ref ) = @_;
    
    my $start_time = $app->param( 'start_time' );
    if ( $start_time ) {
        calc_epr( $start_time );
    } else {
        init_epr();
    }
}

sub post_build {
    my $cache_drv = _cache_drv();

    $cache_drv->delete( $Key_total_entries );
    $cache_drv->delete( $Key_next_epr );
        
    my $orig_epr = $cache_drv->get( $Key_orig_epr );
    MT->config->EntriesPerRebuild( $orig_epr );
        
    $cache_drv->delete( $Key_orig_epr );
} 

sub init_epr {
    my $cache_drv = _cache_drv();

    $cache_drv->set( $Key_total_entries, 0 );
        
    my $orig_epr = MT->config->EntriesPerRebuild;
    $cache_drv->set( $Key_orig_epr, $orig_epr );
        
    my $first_epr = MT->config->FirstEntriesPerRebuild || 4;
        
    if ( $DEBUG ) {
        MT->log( '$first_epr = ' . $first_epr );
    }  
        
    $cache_drv->set( $Key_next_epr, $first_epr );
    MT->config->EntriesPerRebuild( $first_epr );
}

sub calc_epr {
    my ( $start_time ) = @_;
    my $cache_drv      = _cache_drv();

    my $epr            = $cache_drv->get( $Key_next_epr );
    my $total_entries  = $cache_drv->get( $Key_total_entries );
    
    if ( $DEBUG ) {
        MT->log( '$epr = ' . $epr );
        MT->log( '$total_entries = ' . $total_entries );
    }
        
    $total_entries += $epr;
    $cache_drv->set( $Key_total_entries, $total_entries );

    my $diff_time      = time - $start_time;
    my $time_per_entry = $diff_time / $total_entries;
            
    my $next_epr = int ( ( MT->config->TimePerRebuild || 5 ) / $time_per_entry );
    $next_epr  ||= 1;
        
    if ( $DEBUG ) {
        MT->log( '$diff_time = ' . $diff_time );
        MT->log( '$time_per_entry = ' . $time_per_entry );
        MT->log( '$next_epr = ' . $next_epr );
    }
        
    $cache_drv->set( $Key_next_epr, $next_epr );
    MT->config->EntriesPerRebuild( $next_epr );
}   


1;
__END__
