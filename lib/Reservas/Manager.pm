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
	my $tokens = shift;
	$tokens->{'login_url'}  = uri_for('/login');
	$tokens->{'logout_url'} = uri_for('/logout');
};


# Ruteos

get '/' => sub {
	my %registros  = Reservas::Gestor::registros();
	my %query  = query();
	template 'index.tt', {
		'page_title'	=> 'Reservas de Recursos',
		'registros' => \%registros,
		'query' => \%query,
		'flash' => get_flash(),
	}
};

get '/reserva/:id' => sub {
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
		'previo_borrar_url' => uri_for('/previo_borrar/'.$id),
        	# 'filtro_id_cosa' => $cosa,
	};
};

get '/consultar' => sub {
	template 'consultar.tt', {
		'page_title'	=> 'Consultar Disponibilidad',
		'inventario'    =>  \%inventario,
		'flash'		=> get_flash(),
	}
};

post '/consultar' => sub {
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


get '/preview' => sub {
	unless(session->{'data'}{'pedido'}){
		redirect '/';
	}
	template 'preview.tt', {
		'grabar_url' => uri_for('/grabar'),
		'cancelar_url' => uri_for('/cancelar'),
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



get '/cancelar' => require_login sub {
	if (session->{'data'}{'pedido'}){
		delete session->{'data'}{'pedido'};
		set_flash('Reserva <b>CANCELADA</b>', 'danger');
	};
	redirect '/';
};

get '/previo_borrar/:id' => sub {
	my $id = params->{'id'};
	my %registros  = Reservas::Gestor::registros();
	my %reserva;	
	my $encontrada = 0;	
	foreach my  $recurso (keys %registros){
		foreach my $reserva (keys %{$registros{$recurso}}){
			if($id eq $reserva){
				say $reserva;
				#%reserva = %{$registros{$recurso}{$reserva}};
				#$reserva{'recurso'} = $recurso;
				$encontrada = 1;	
			}	
		}
	}
        if($encontrada){	

	   set_flash('VAS A BORRAR:'.$id, 'danger');
	   template 'reserva-borrar.tt', {
		'borrar_url' => uri_for('/borrar/'.$id),
	   	'flash' => get_flash(),
	   	'page_title'	=> 'BORRAR: ' . $id,
	   	'reserva' => \%reserva,
	   };
	}else{
	   set_flash('NADA PARA HACER!', 'warning');
	   template 'reserva-borrar.tt', {
	   	'flash' => get_flash(),
	   	'page_title'	=> 'NO ENCONTRÉ: ' . $id,
	   	'reserva' => '',
	   };
	};

};
get '/borrar/:id' => sub {
	my $id = params->{'id'};
	my %registros  = Reservas::Gestor::registros();
	my %reserva;	
	my $encontrada = 0;	
	foreach my  $recurso (keys %registros){
		foreach my $reserva (keys %{$registros{$recurso}}){
			if($id eq $reserva){
				say $reserva;
				#%reserva = %{$registros{$recurso}{$reserva}};
				#$reserva{'recurso'} = $recurso;
				$encontrada = 1;	
			}	
		}
	}
        if($encontrada){	
	   my $reporte .= Reservas::Gestor::borrar( $id );
	   Reservas::Gestor::grabar();
	   set_flash('BORRASTE:'.$id.$reporte, 'success');

	   template 'reserva-borrar.tt', {
	   	'flash' => get_flash(),
		#'borrar_url' => uri_for('/borrar/'.$id),
	   	'page_title'	=> 'BORRÉ:' . $id,
		#'reserva' => \%reserva,
	   };
	}else{
	   set_flash('NADA PARA HACER!', 'warning');
	   template 'reserva-borrar.tt', {
	   	'flash' => get_flash(),
	   	'page_title'	=> 'NO ENCONTRÉ: ' . $id,
	   	'reserva' => '',
	   };
	};

};
## user/session negotiation

get '/users' => require_login sub {
	my $user = logged_in_user;
	return "Hi there, $user->{username}";
};

### Auth rules: Copy-pastiado y simple / garlompo
# post '/login' => sub {
#         my ($success, $realm) = authenticate_user(
#             	params->{username}, params->{password}
#         );
#         if ($success) {
# 		redirect '/preview';	
# 		print Dumper (session);
#             	session logged_in_user => params->{username};
#         	session logged_in_user_realm => $realm;
#         } else {
#             	redirect '/login';
#         }
# };
    
#any '/logout' => sub {
#    session->destroy;
#    redirect '/';
#};


## Subfunciones

### Notification Handling
sub set_flash {
	my $message = shift;
	my $estado = shift;
	# my $estado = 'info';	
	$flash{'contenido'} = $message;
	$flash{'estado'} = $estado;
}
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
			#if($sale>= $time){
			       push @{$RESULTADO{$item}{'reservas'}}, $reserva;	
			#}	
		}
    		
	}
	return %RESULTADO;
}


true;
