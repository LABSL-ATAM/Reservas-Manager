package Reservas::Manager;
use Reservas::Gestor;

use feature 'say';
use Data::Dumper;
use Template;

use Dancer2;

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
my %registros  = Reservas::Gestor::registros();
my %inventario = Reservas::Gestor::inventario();

# Hooks

hook before_template_render => sub {
	my $tokens = shift;

	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'} = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'consulta'} = uri_for('/consultar');
};


# Ruteos

get '/' => sub {
    template 'index';
};



get '/reservas' => sub {
    template 'show_entries.tt', {
        'msg' => get_flash(),
        # 'add_grabar_url' => uri_for('/grabar'),
        'registros' => \%registros,
    };
};

any ['get', 'post'] => '/consultar' => sub {
	my $resultado;
	my $puede_reservar = 0;

	if ( request->method() eq "POST" ) {
 		my %pedido_IN = params;

		my ( $reporte, $normalizado ) 
			= Reservas::Gestor::evaluar(%pedido_IN);

		if ( $normalizado ) {
			my ($msj,$disponible)
				= Reservas::Gestor::consultar($normalizado);
			$reporte .=  " -> ".$msj;

			# Ingresar Pedido
			if ( $disponible ){
				$reporte .= " -> ".Reservas::Gestor::registrar($disponible);
				$puede_reservar = 1;
			}
		}

		# set_flash('fdef');
		$resultado = $reporte;
	};
	template 'consulta.tt', {
		'inventario' =>  \%inventario,
		'resultado'  => $resultado,
		'puede_reservar'	 => $puede_reservar,
	}
};

get '/reservar' => sub {
	Reservas::Gestor::grabar();
	%registros = Reservas::Gestor::registros();
	template 'show_entries.tt', {
        'msg' => get_flash(),
        'add_pedido_url' => uri_for('/pedido'),
        'registros' => \%registros,
        
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

# any ['get', 'post'] => '/login' => sub {
# 	my $err;
# 	if ( request->method() eq "POST" ) {
# 		# process form input
# 		if ( params->{'username'} ne setting('username') ) {
# 			$err = "Invalid username";
# 		} elsif ( params->{'password'} ne setting('password') ) {              
# 			$err = "Invalid password";
# 	}else{
# 			session 'logged_in' => true;
# 			set_flash('You are logged in.');
# 			return redirect '/';
# 		}
# 	}
# 	# display login form
# 	template 'login.tt', {
# 		'err' => $err,
# 	};
# };

any ['get', 'post'] =>  '/login' => sub {

	my $err;
	if ( request->method() eq "POST" ) {
        my ($success, $realm) 
        		= authenticate_user(
           	 		params->{username}, 
           	 		params->{password}
           		)
        ;
        if ($success) {
            session logged_in_user => params->{username};
            session logged_in_user_realm => $realm;
            # other code here
        } else {
            # authentication failed
        }
    };
    # display login form
    template 'login.tt', {
# 		'err' => $err,
	};    
};
    
any '/logout' => sub {
    session->destroy;
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



# NOTAS
# llamar subs de un modulo
# my $foo = Reservas::Gestor::bar();
