#
# This file is part of BeerFestDB, a beer festival product management
# system.
# 
# Copyright (C) 2010-2012 Tim F. Rayner
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# $Id$

package BeerFestDB::Web::Controller::User;
use Moose;
use namespace::autoclean;

use Crypt::SaltedHash;
use List::Util qw(first);
use JSON::MaybeXS;
use Bytes::Random::Secure qw(random_bytes);
use Digest::SHA qw(sha256_hex);
use MIME::Base64 qw(encode_base64url);
use MIME::Lite::TT::HTML;
use DateTime;

BEGIN {extends 'BeerFestDB::Web::Controller'; }

=head1 NAME

BeerFestDB::Web::Controller::User - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub BUILD {

    my ( $self, $params ) = @_;

    $self->model_view_map({
        user_id            => 'user_id',
        username           => 'username',
        password           => 'password',
        name               => 'name',
        email              => 'email',
        roles              => undef, # See viewhash_from_model below.
    });
}

=head2 list

=cut

sub list : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->generate_json_and_detach( $c, $rs );
}

=head2 grid

=cut

sub grid : Local {}

=head2 view

=cut

sub view : Local {

    my ( $self, $c, $id ) = @_;

    my $object = $c->model('DB::User')->find($id);

    unless ( $object ) {
        $c->flash->{error} = "Error: User not found.";
        $c->res->redirect( $c->uri_for('/default') );
        $c->detach();        
    }

    $c->stash->{object} = $object;

    return;
}

=head2 submit

=cut

sub submit : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->write_to_resultset( $c, $rs );
}

=head2 delete

=cut

sub delete : Local {

    my ( $self, $c ) = @_;

    my $rs = $c->model( 'DB::User' );

    $self->delete_from_resultset( $c, $rs );
}

sub build_database_object : Private {

    my ( $self, $rec, $c, @other ) = @_;

    # This overridden method needs to hash any $rec->password
    # field before passing it back to the superclass method.
    my $pw = $rec->{'password'};
    if ( defined $pw ) {
        if ( $pw eq q{} ) {
            delete $rec->{'password'}; # no empty passwords
        }
        else {
            my $csh = Crypt::SaltedHash->new(algorithm => 'SHA-1');
            $csh->add($pw);
            $rec->{'password'} = $csh->generate();
        }
    }

    # Our regular build_database_object method doesn't handle many-to-many.
    my $roles = delete $rec->{'roles'};

    my $obj = $self->next::method( $rec, $c, @other );

    if ( defined $roles && defined $obj ) {
        my $rs = $c->model( 'DB::UserRole' );
        my @r = split /,/, $roles;
        foreach my $existing ($obj->user_roles) {

            # Delete unwanted existing roles.
            if ( ! first { $existing->get_column('role_id') == $_ } @r ) {
                $existing->delete;
            }
        }
        foreach my $role_id (@r) {

            # Check that all the wanted roles are set.
            $rs->find_or_create({ user_id => $obj->user_id(), role_id => $role_id });
        }
    }

    if ( defined $pw && $pw ne q{} && defined $obj ) {
        $obj->update({ date_password_changed => \'CURRENT_TIMESTAMP' });
    }

    $obj->update({ date_modified => \'CURRENT_TIMESTAMP' }) if defined $obj;

    return $obj;
}

=head2 load_form

=cut

sub load_form : Local {

    my ( $self, $c ) = @_;

    my $pk = 'user_id';
    
    my $id = $c->request->param( $pk ) // -1;

    if ( $id != eval{ $c->user->user_id } && ! $c->check_any_user_role('admin') ) {
        $c->stash->{error} = 'You are not authorised to access these data.';
        $c->detach( '/access_denied' );
    }

    my $rs = $c->model('DB::User');

    $self->form_json_and_detach( $c, $rs, $pk );
}

=head2 modify

Profile self-edit: allows a logged-in user to update their own C<name>
and C<email>. Password, username and roles cannot be changed via this
action; use C<request_password_reset> for password changes and the
admin C<submit> action for role management.

=cut

sub modify : Local {

    my ( $self, $c ) = @_;

    my $data = $self->decode_json_changes($c);

    foreach my $rec ( @{ $data } ) {

        my $target_id = $rec->{'user_id'};

        unless ( defined $target_id
              && $target_id == eval { $c->user->user_id }
              || $c->check_any_user_role('admin') ) {
            $c->stash->{error} = 'You are not authorised to edit these data.';
            $c->detach( '/access_denied' );
        }

        # Strip fields that must not be changed via this action.
        delete $rec->{$_} for qw( username password roles );
    }

    my $rs = $c->model( 'DB::User' );
    $self->write_to_resultset( $c, $rs );
}

=head2 request_password_reset

Generates a single-use, time-limited (15-minute) password-reset token,
stores its SHA-256 hash in the database, and emails the raw token to
the user's registered address.

=cut

sub request_password_reset : Local {

    my ( $self, $c ) = @_;

    # Must be logged in, or an admin acting on another user's behalf.
    unless ( $c->user_exists ) {
        $c->stash->{error} = 'You must be logged in to request a password reset.';
        $c->detach( '/access_denied' );
    }

    my $user_id = $c->request->param('user_id');
    unless ( defined $user_id && $user_id =~ /^\d+$/ ) {
        $c->stash->{error} = 'Invalid user_id.';
        $c->detach( '/access_denied' );
    }

    unless ( $user_id == eval { $c->user->user_id }
          || $c->check_any_user_role('admin') ) {
        $c->stash->{error} = 'You are not authorised to reset this password.';
        $c->detach( '/access_denied' );
    }

    my $user = $c->model('DB::User')->find( $user_id );
    unless ( $user ) {
        $c->stash->{ success } = JSON->false();
        $c->stash->{ error }   = 'User not found.';
        $c->forward( 'View::JSON' );
        return;
    }

    my $email_addr = $user->email;
    unless ( defined $email_addr && $email_addr ne q{} ) {
        $c->stash->{ success } = JSON->false();
        $c->stash->{ error }   = 'No email address is registered for this account.';
        $c->forward( 'View::JSON' );
        return;
    }

    # Remove any existing unused tokens for this user.
    $c->model('DB::PasswordResetToken')->search({
        user_id => $user_id,
        used    => 0,
    })->delete;

    # Generate a cryptographically secure random token.
    my $raw_token  = encode_base64url( random_bytes(32) );
    my $token_hash = sha256_hex( $raw_token );
    my $expires_at = DateTime->now->add( minutes => 15 );
    my $expires_str = sprintf( '%04d-%02d-%02d %02d:%02d:%02d',
        $expires_at->year, $expires_at->month,  $expires_at->day,
        $expires_at->hour, $expires_at->minute, $expires_at->second );

    $c->model('DB::PasswordResetToken')->create({
        user_id    => $user_id,
        token_hash => $token_hash,
        expires_at => $expires_str,
        used       => 0,
    });

    my $reset_url = $c->uri_for( '/user/reset_password', { token => $raw_token } )->as_string;

    my $email_cfg = $c->config->{ email } || {};
    my $from      = $email_cfg->{ from_address } || 'beerfestdb@localhost';
    my $smtp_host = $email_cfg->{ smtp_host }    || 'localhost';
    my $smtp_port = $email_cfg->{ smtp_port }    || 25;

    eval {
        my $tt_vars = {
            username  => $user->username,
            reset_url => $reset_url,
            expires   => '15 minutes',
        };
        my $msg = MIME::Lite::TT::HTML->new(
            From     => $from,
            To       => $email_addr,
            Subject  => 'BeerFestDB password reset',
            Template => {
                text => 'email/password_reset_text.tt2',
                html => 'email/password_reset_html.tt2',
            },
            TmplOptions => { INCLUDE_PATH => $c->path_to('root', 'src') },
            TmplParams  => $tt_vars,
        );
        $msg->send( 'smtp', $smtp_host, Port => $smtp_port );
    };
    if ( $@ ) {
        $c->log->error( "Failed to send password reset email: $@" );
        $c->stash->{ success } = JSON->false();
        $c->stash->{ error }   = 'Failed to send password reset email. Please contact an administrator.';
        $c->forward( 'View::JSON' );
        return;
    }

    $c->stash->{ success } = JSON->true();
    $c->forward( 'View::JSON' );
}

=head2 reset_password

Renders the password reset form. Validates the raw token supplied in
C<?token=...> before displaying the form; redirects to the login page
if the token is absent, already used, or expired.

=cut

sub reset_password : Local {

    my ( $self, $c ) = @_;

    my $raw_token = $c->request->param('token');

    my $token_row = $self->_validate_reset_token( $c, $raw_token )
        or return;   # _validate_reset_token handles redirect on failure

    $c->stash->{token}    = $raw_token;
    $c->stash->{username} = $token_row->user->username;
    $c->stash->{template} = 'user/reset_password.tt2';
}

=head2 reset_password_submit

Handles submission of the password reset form. Re-validates the token
inside a transaction, hashes the new password, updates the user record,
and marks the token as used.

=cut

sub reset_password_submit : Local {

    my ( $self, $c ) = @_;

    my $raw_token   = $c->request->param('token');
    my $new_pw      = $c->request->param('new_password');
    my $confirm_pw  = $c->request->param('confirm_password');

    unless ( defined $new_pw && $new_pw ne q{} ) {
        $c->flash->{error} = 'Password must not be empty.';
        $c->res->redirect( $c->uri_for( '/user/reset_password', { token => $raw_token } ) );
        $c->detach();
    }

    unless ( $new_pw eq $confirm_pw ) {
        $c->flash->{error} = 'Passwords do not match.';
        $c->res->redirect( $c->uri_for( '/user/reset_password', { token => $raw_token } ) );
        $c->detach();
    }

    my $schema = $c->model('DB::User')->result_source->schema;

    my $error;
    eval {
        $schema->txn_do( sub {

            # Re-validate inside the transaction to guard against races.
            my $token_row = $self->_validate_reset_token( $c, $raw_token )
                or die "invalid token\n";

            my $csh = Crypt::SaltedHash->new( algorithm => 'SHA-1' );
            $csh->add( $new_pw );
            my $hashed_pw = $csh->generate();

            $token_row->user->update({
                password             => $hashed_pw,
                date_password_changed => \'CURRENT_TIMESTAMP',
                date_modified        => \'CURRENT_TIMESTAMP',
            });

            $token_row->update({ used => 1 });
        });
    };
    if ( $@ && $@ ne "invalid token\n" ) {
        $c->log->error( "Password reset transaction failed: $@" );
        $c->flash->{error} = 'An error occurred while resetting your password. Please try again.';
        $c->res->redirect( $c->uri_for( '/user/reset_password', { token => $raw_token } ) );
        $c->detach();
    }

    # On success (or handled invalid-token redirect from _validate_reset_token):
    unless ( $error ) {
        $c->flash->{message} = 'Your password has been updated. Please log in with your new password.';
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
    }
}

# ------------------------------------------------------------------
# Private helper

sub _validate_reset_token : Private {

    my ( $self, $c, $raw_token ) = @_;

    unless ( defined $raw_token && $raw_token ne q{} ) {
        $c->flash->{error} = 'No reset token provided.';
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
        return;
    }

    my $token_hash = sha256_hex( $raw_token );
    my $token_row  = $c->model('DB::PasswordResetToken')->find({ token_hash => $token_hash });

    unless ( $token_row ) {
        $c->flash->{error} = 'Invalid or expired password reset link.';
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
        return;
    }

    if ( $token_row->used ) {
        $c->flash->{error} = 'This password reset link has already been used.';
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
        return;
    }

    # Compare expiry in UTC.
    my $now     = DateTime->now;
    my $expires = $token_row->expires_at;
    # expires_at comes back as a string from the DB; parse it.
    if ( ! ref $expires ) {
        my ( $y, $mo, $d, $h, $mi, $s ) = split /\D+/, $expires;
        $expires = DateTime->new(
            year => $y, month => $mo, day => $d,
            hour => $h, minute => $mi, second => $s,
        );
    }

    if ( DateTime->compare( $now, $expires ) >= 0 ) {
        $c->flash->{error} = 'This password reset link has expired. Please request a new one.';
        $c->res->redirect( $c->uri_for('/login') );
        $c->detach();
        return;
    }

    return $token_row;
}

sub generate_object_viewhash : Private {

    my ( $self, $obj, $c ) = @_;

    # Don't publish the SHA-1 password hash; just leave it blank.
    my $obj_info = $self->next::method( $obj, $c );
    delete $obj_info->{'password'};
    return $obj_info;
}

sub viewhash_from_model : Private {

    my ( $self, $view_key, $dbrow, $lookup ) = @_;

    my $rc;
    if ( $view_key eq 'roles' ) {
        $rc = join(',', map { $_->get_column('role_id') } $dbrow->roles);
    }
    else {
        $rc = $self->next::method( $view_key, $dbrow, $lookup );
    }

    return $rc;
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Tim F. Rayner

This library is released under version 3 of the GNU General Public
License (GPL).

=cut

__PACKAGE__->meta->make_immutable;

1;
