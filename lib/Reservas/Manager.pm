package Reservas::Manager;
use Reservas::Gestor;

use feature 'say';
use Data::Dumper;
use Template;

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
# https://metacpan.org/pod/Dancer2::Tutorial

my $flash;

our $VERSION = '0.1';

# Como llamar subs de un modulo
my $i = Reservas::Gestor::hola_pedido();

hook before_template_render => sub {
	my $tokens = shift;

	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'} = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');

	$tokens->{'pedido'} = uri_for('/pedido');
};

# Ruteos
get '/' => sub {
	say $i;
#	template 'index';
	template 'show_entries.tt', {
        'msg' => get_flash(),
        # 'add_entry_url' => uri_for('/add'),
        # 'entries' => $sth->fetchall_hashref('id'),
    };
	# return $i; #el return ojaldre caga todo.
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

post '/add' => sub {
   # if ( not session('logged_in') ) {
   #    send_error("Not logged in", 401);
   # }

   # my $db = connect_db();
   # my $sql = 'insert into entries (title, text) values (?, ?)';
   # my $sth = $db->prepare($sql) or die $db->errstr;
   # $sth->execute(params->{'title'}, params->{'text'}) or die $sth->errstr;

   # set_flash('New entry posted!');
   # redirect '/';
};


any ['get', 'post'] => '/pedido' => sub {
	my $resultado;
	if ( request->method() eq "POST" ) {
		# process form input
 		my $pedido_IN = params;
# #		# pedido_IN == item, mes, dia, hora, duracion, quien, comentario

# 		my ( $i, $m, $d, $h, $l, $q, $c ) =  $pedido_IN;
# 		my ( $reporte, $pedido_normalizado )
# 			= formular_pedido($i, $m, $d, $h, $l, $q, $c);

		# print Dumper($pedido->{'atributo1'});
		set_flash('fdef');
		$resultado = $pedido_IN->{'atributo7'};
	};
	template 'pedido.tt', {
		'resultado' => $resultado,
	}
};

get '/logout' => sub {
   app->destroy_session;
   set_flash('You are logged out.');
   redirect '/';
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
