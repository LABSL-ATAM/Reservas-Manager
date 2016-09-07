package Reservas::Manager;

use Dancer2;
# set 'database'     => File::Spec->catfile(File::Spec->tmpdir(), 'dancr.db');
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;

set 'username' => 'admin';
set 'password' => 'password';
set 'layout'       => 'main';

my $flash;

use Reservas::Gestor;

use feature 'say';
use Data::Dumper;

our $VERSION = '0.1';



# Como llamar subs de un modulo
my $i = Reservas::Gestor::hola_pedido();

# get '/' => sub {
#     template 'index';
# };

get '/' => sub {
	say $i;
	return $i;
};

any ['get', 'post'] => '/login' => sub {
	my $err;

	if ( request->method() eq "POST" ) {
	# process form input
		if ( params->{'username'} ne setting('username') ) {
			$err = "Invalid username";
		} elsif ( params->{'password'} ne setting('password') ) {
			$err = "Invalid password";
	}else{
			session 'logged_in' => true;
			set_flash('You are logged in.');
			return redirect '/';
		}
	}
	# display login form
	template 'login.tt', {
		'err' => $err,
	};
};




# Subfunciones
sub set_flash {
	my $message = shift;

	$flash = $message;
}

sub get_flash {
	my $msg = $flash;
	$flash = "";
	return $msg;
}

true;
