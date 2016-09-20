package Reservas::Manager;
use Reservas::Gestor;

use strict;
use warnings;
use feature 'say';

use Data::Dumper;

use Dancer2;
use Dancer2::Plugin::Auth::Extensible;

our $VERSION = '0.1';

my $time = time;
my $flash;
my %inventario = Reservas::Gestor::inventario();


# Hooks

hook before_template_render => sub {
	my $tokens = shift;
	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'}  = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'consulta_url'}   = uri_for('/consultar');
	$tokens->{'reserva_url'}   = uri_for('/reservar');
};


# Ruteos

get '/' => require_login sub {
	my %registros  = Reservas::Gestor::registros();
	my %query  = query();
	template 'index.tt', {
		'msg' => get_flash(),
		'page_title'	=> 'Reservas de Recursos',
		# 'add_grabar_url' => uri_for('/grabar'),
		'registros' => \%registros,
		'query' => \%query,
	};
};

any ['get', 'post'] => '/consultar' => require_login sub {
	my $puede_reservar = 0;
	my $resultado = '';

	if ( request->method() eq "POST" ) {

		my %pedido_IN = params;

		my ( $reporte, $pedido_normalizado ) 
			= Reservas::Gestor::evaluar(%pedido_IN);

		if ( $pedido_normalizado ) {
			my ($msj,$pedido_disponible)
				= Reservas::Gestor::consultar($pedido_normalizado);
			$reporte .=  " -> ".$msj;

			# Ingresar Pedido
			if ( $pedido_disponible ){
				$puede_reservar = 1;
				session 'pedido' => $pedido_disponible;
			}
		}
		set_flash($reporte);
		$resultado = $reporte;
	};
	template 'consulta.tt', {
		'msg'		=> get_flash(),
		'page_title'	=> 'Consultar Disponibilidad',
		'inventario'    =>  \%inventario,
		'reporte'      	=> $resultado,
		'puede_reservar'=> $puede_reservar,
	}
};

get '/reservar' => require_login sub {
	template 'reservar.tt', {
		'msg' => get_flash(),
		'grabar_url' => uri_for('/grabar'),
	};

};

get '/grabar' => require_login sub {
	if (session->{'data'}{'pedido'}){
		my $pedido = session->{'data'}{'pedido'};
		my $reporte .= Reservas::Gestor::registrar($pedido);
		Reservas::Gestor::grabar();
		set_flash($reporte);
	}
	my %registros = Reservas::Gestor::registros();
	my %query  = query();
	template 'index.tt', {
		'msg' => get_flash(),
		'registros' => \%registros,
		'query' => \%query,
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

# Ordenar y Filtrar Reservas viejas... 
sub query{
	my %registro = Reservas::Gestor::registros();
	my %RESULTADO;
	
	foreach my $item (keys %registro) {
		my @RESERVAS;		
		foreach my $reserva (
			sort { 
				$registro{$item}{$a}->{cuando} cmp 
				$registro{$item}{$b}->{cuando}  
			}
			keys %{$registro{$item}}
		){
			
			my ($sale, $vuelve) = split(
				/-/, 
				$registro{$item}{$reserva}{'cuando'}
			);	
			if($vuelve >= $time){
				push @{$RESULTADO{$item}{'reservas'}}, $reserva;	
			}	
		}
    		
	}
	return %RESULTADO;
}


true;
