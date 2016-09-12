package Reservas::Manager;
use Reservas::Gestor;

use feature 'say';
use Data::Dumper;
use Template;
use Template::Stash;

use Dancer2;
use Dancer2::Plugin::Auth::Extensible;

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
my %inventario = Reservas::Gestor::inventario();
my %registros  = pre_procesar(
		Reservas::Gestor::registros()
	);

# Hooks

hook before_template_render => sub {
	my $tokens = shift;
	# $tokens->{'css_url'} = request->base . 'css/style.css';
	#$tokens->{'login_url'}  = uri_for('/login');
	##$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'consulta'}   = uri_for('/consultar');
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

get '/users' => require_login sub {
	my $user = logged_in_user;
	return "Hi there, $user->{username}";
};




## Subfunciones

### Notification Handling
sub set_flash {
	my $message = shift;
	$flash = $message;
}

sub get_flash {
	my $msg = $flash;
	$flash = "";
	return $msg;
}

### Autentification
sub login_page_handler{
	# return 1,1;
}

sub pre_procesar{
	my %registros = @_;
	# my ($hash) = @_; 

	# return [ sort { $hash->{$a} cmp $hash->{$b} } keys %{$hash} ];

	return %registros;
}



true;



# NOTAS
# llamar subs de un modulo
# my $foo = Reservas::Gestor::bar();
