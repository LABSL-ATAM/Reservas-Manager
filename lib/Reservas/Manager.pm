package Reservas::Manager;
use Reservas::Gestor;

use feature 'say';
use Data::Dumper;
use Template;

use Dancer2;

# set 'database'     => File::Spec->catfile(File::Spec->tmpdir(), 'dancr.db');
set 'session'      => 'Simple';
set 'template'     => 'template_toolkit';
set 'layout'       => 'main';
set 'logger'       => 'console';
set 'log'          => 'debug';
set 'show_errors'  => 1;
set 'startup_info' => 1;
set 'warnings'     => 1;

set 'username'     => 'admin';
set 'password'     => 'password';
our $VERSION = '0.1';


# https://metacpan.org/pod/Dancer2::Tutorial

my $flash;


my %registros = Reservas::Gestor::cargar_registros();

# Hooks

hook before_template_render => sub {
	my $tokens = shift;

	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'} = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'pedido'} = uri_for('/pedido');
};



# Ruteos

get '/' => sub {
	template 'show_entries.tt', {
        'msg' => get_flash(),
        # 'add_entry_url' => uri_for('/add'),
        'registros' => \%registros,
    };
    #	template 'index';
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
   #    send_error("Not logged in", 401);P
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
 		my %pedido_IN = params;
		# pedido_IN == item, mes, dia, hora, duracion, quien, comentario

		# my ( $reporte, $pedido_normalizado )
		#		= formular_pedido($i, $m, $d, $h, $l, $q, $c);
		print Dumper(%pedido_IN);

		set_flash('fdef');
		$resultado = $pedido_IN{item}; # 
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

# notas

# llamar subs de un modulo
# my $foo = Reservas::Gestor::bar();



true;
