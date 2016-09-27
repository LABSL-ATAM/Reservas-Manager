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


# AUTENTIFICACION

sub login_page_handler {
    template 'login';
}

sub permission_denied_page_handler {
    template 'login';
}

# Hooks

hook before_template_render => sub {
	my $tokens = shift;
	# $tokens->{'css_url'} = request->base . 'css/style.css';
	$tokens->{'login_url'}  = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
	$tokens->{'consulta_url'}   = uri_for('/consultar');
	$tokens->{'res'}   = uri_for('/reservar');
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
# Agregado: Cada ID con su render...
get '/ID/:id' => require_login sub {
	my %registros  = Reservas::Gestor::registros();
	my %query  = query();
	my $id = params->{'id'};
	template 'puntual.tt', {
		'msg' => get_flash(),
		'page_title'	=> 'Reserva ' . $id,
		# 'add_grabar_url' => uri_for('/grabar'),
		'registros' => \%registros,
		'query' => \%query,
	        'filtro_id' => $id,
        	#'filtro_id_cosa' => $cosa,
	};
};

get '/consultar' => require_login sub {
	template 'consultar.tt', {
		'msg'		=> get_flash(),
		'page_title'	=> 'Consultar Disponibilidad',
		'inventario'    =>  \%inventario,
	}
};

post '/consultar' => require_login sub {
	my %pedido_IN = params;
	my ( $reporte, $pedido_normalizado ) 
		= Reservas::Gestor::evaluar(%pedido_IN);

	if ( $pedido_normalizado ) {
		my ($msj,$pedido_disponible)
			= Reservas::Gestor::consultar($pedido_normalizado);
		$reporte .=  " -> ".$msj;

		# Ingresar Pedido
		if ( $pedido_disponible ){
			session 'pedido' => $pedido_disponible;
		}
	}
	set_flash($reporte);

};


get '/pre-reserva' => require_login sub {
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
		delete session->{'data'}{'pedido'};
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

# Auth rules: Copy-pastiado y simple / garlompo
post '/login' => sub {
        my ($success, $realm) = authenticate_user(
            params->{username}, params->{password}
        );
        if ($success) {
            session logged_in_user => params->{username};
            session logged_in_user_realm => $realm;
        } else {
            redirect '/login';
        }
};
    
any '/logout' => sub {
    session->destroy;
    redirect '/';
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
