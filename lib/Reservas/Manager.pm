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
my %flash;

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
#	my $tokens = shift;
#	$tokens->{'login_url'}  = uri_for('/login');
#	$tokens->{'logout_url'} = uri_for('/logout');
#	$tokens->{'consulta_url'}   = uri_for('/consultar');
#	$tokens->{'res'}   = uri_for('/reservar');
};


# Ruteos

get '/' => require_login sub {
	my %registros  = Reservas::Gestor::registros();
	my %query  = query();
	template 'index.tt', {
		'page_title'	=> 'Reservas de Recursos',
		'registros' => \%registros,
		'query' => \%query,
		'flash' => get_flash(),
	}
};

# Agregado: Cada ID con su render...
get '/ID/:id' => require_login sub {
	my $id = params->{'id'};
	my %registros  = Reservas::Gestor::registros();
	my %reserva;	
	# foreach my $item (keys %registro) {
        # $registro{$item}{$reserva}{'cuando'}
	foreach my  $recurso (keys %registros){
		foreach my $reserva (keys %{$registros{$recurso}}){
			if($id eq $reserva){
				say $reserva;
				%reserva = %{$registros{$recurso}{$reserva}};
				$reserva{'recurso'} = $recurso;
			}	
		}
	}
	
	template 'reserva-individual.tt', {
		'flash' => get_flash(),
		'page_title'	=> 'Reserva: ' . $id,
		'reserva' => \%reserva,
		# 'add_grabar_url' => uri_for('/grabar'),
        	# 'filtro_id_cosa' => $cosa,
	};
};

get '/consultar' => require_login sub {
	template 'consultar.tt', {
		'page_title'	=> 'Consultar Disponibilidad',
		'inventario'    =>  \%inventario,
		'flash'		=> get_flash(),
	}
};

post '/consultar' => require_login sub {
	my %pedido_IN = params;
	my ( $reporte, $pedido_normalizado ) 
		= Reservas::Gestor::evaluar(%pedido_IN);
	set_flash($reporte, 'warning');
	if ( $pedido_normalizado ) {
		my ($msj,$pedido_disponible)
			= Reservas::Gestor::consultar($pedido_normalizado);
		$reporte .=  " -> ".$msj;
		set_flash($reporte, 'danger');

		# Ingresar Pedido
		if ( $pedido_disponible ){
			session 'pedido' => $pedido_disponible;
			set_flash($reporte,'success');
			redirect '/preview';	
		}else{
			redirect '/consultar';	
		}
	
	}else{
		redirect '/consultar';	
	}
};


get '/preview' => require_login sub {
	template 'preview.tt', {
		'flash' => get_flash(),
		'grabar_url' => uri_for('/grabar'),
	};

};

get '/grabar' => require_login sub {
	if (session->{'data'}{'pedido'}){
		my $pedido = session->{'data'}{'pedido'};
		my $reporte .= Reservas::Gestor::registrar($pedido);
		Reservas::Gestor::grabar();
		set_flash($reporte, 'success');
		delete session->{'data'}{'pedido'};
	}
	my %registros = Reservas::Gestor::registros();
	my %query  = query();
	template 'index.tt', {
		'flash' => get_flash(),
		'registros' => \%registros,
		'query' => \%query,
	};

};

## user/session negotiation

get '/users' => require_login sub {
	my $user = logged_in_user;
	return "Hi there, $user->{username}";
};

### Auth rules: Copy-pastiado y simple / garlompo
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
	my $estado = shift;
	#my $estado = 'info';	
	$flash{'contenido'} = $message;
	$flash{'estado'} = $estado;
}
#sub get_flash {
#	# my $msg = $flash;
#	my $msg = $flash{'contenido'};
#	my $estado = $flash{'estado'};
#
#	delete $flash{'contenido'};
#	delete $flash{'estado'};
#
#	return $msg;
#}
sub get_flash {
	my %f;
	$f{'contenido'} = $flash{contenido};
	$f{'estado'} = $flash{'estado'};
	if(!$f{'estado'}) {
	
		$f{'estado'} = 'info';
	}
	delete $flash{'contenido'};
	delete $flash{'estado'};

	return \%f;
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
