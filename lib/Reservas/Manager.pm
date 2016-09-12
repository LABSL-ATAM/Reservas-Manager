package Reservas::Manager;
use Reservas::Gestor;

use strict;
use warnings;
use feature 'say';

use Data::Dumper;

# https://metacpan.org/pod/Dancer2::Tutorial
use Dancer2;
# http://search.cpan.org/~hornburg/Dancer2-Plugin-Auth-Extensible-0.303/
use Dancer2::Plugin::Auth::Extensible;

our $VERSION = '0.1';


my $flash;

my %inventario = Reservas::Gestor::inventario();


# Hooks

hook before_template_render => sub {
	my $tokens = shift;
	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'}  = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'consulta'}   = uri_for('/consultar');
};


# Ruteos

get '/' => sub {
	template 'index';
};

get '/reservas' => sub {

	my %registros  = pre_procesar(
		Reservas::Gestor::registros()
	);

	template 'show_entries.tt', {
		'msg' => get_flash(),
		# 'add_grabar_url' => uri_for('/grabar'),
		'registros' => \%registros,
	};
};

any ['get', 'post'] => '/consultar' => sub {
	my $puede_reservar = 0;
	my $resultado = '';

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
				$reporte .= " -> ".
					Reservas::Gestor::registrar($disponible);
				$puede_reservar = 1;
			}
		}

		# set_flash('fdef');
		$resultado = $reporte;
	};
	template 'consulta.tt', {
		'inventario'     =>  \%inventario,
		'reporte'      => $resultado,
		'puede_reservar' => $puede_reservar,
	}
};

get '/reservar' => require_login sub {
	Reservas::Gestor::grabar();
	# my %registros = Reservas::Gestor::registros();
	template 'show_entries.tt', {
		'msg' => get_flash(),
		'add_consultar_url' => uri_for('/consultar'),
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

sub pre_procesar{
	# ordernar, y filtrar los registros
	my %registros = @_;
	# my ($hash) = @_; 

	# return [ sort { $hash->{$a} cmp $hash->{$b} } keys %{$hash} ];

	return %registros;
}



true;



# NOTAS
# llamar subs de un modulo
# my $foo = Reservas::Gestor::bar();
