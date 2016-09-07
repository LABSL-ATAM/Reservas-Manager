package Reservas::Gestor;

#!/usr/bin/perl
use strict;
use warnings;

# use v5.20;
use Data::Uniqid qw ( luniqid );
use File::Slurp;
use JSON;

# # Args / Params
my $verbose = 0;
# if( 'v' ~~ @ARGV ){
#   my $verbose = 1;
# }

# Defaults Globales
my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
my $anio = $yr19+1900; # año actual ¿salvo q se indique?



my $limite_duracion = 24;

# Inventario (items disponibles)
my @inventario =  split /\W/, read_file('inventario');
my %inventario = map { $_ => 1 } @inventario; # CABEZEADA POR REVISAR

# Pedidos (input)
# my @pedidos = read_file('pedidos.csv');

# Registro (almacen de reservas)
my $registro_text = read_file('registro.json');
my $json = JSON->new;
my $registro_json = $json->decode($registro_text);
my %registros = %$registro_json;

#   No vamos vamos a usar esta cadena
#   # Normalizar Pedido
#   my ( $reporte, $pedido_normalizado )
#     = formular_pedido($i, $m, $d, $h, $l, $q, $c);
#   # item, mes, dia, hora, duracion, quien, comentario

#   # Procesar Pedido
#   if($pedido_normalizado){
#     my (
#       $msj,
#       $pedido_disponible
#     ) = disponibilidad($pedido_normalizado);
#     $reporte .=  " -> ".$msj;

#     # Ingresar Pedido
#     if($pedido_disponible){
#       $reporte .= " -> ".registrar_pedido($pedido_disponible);
#     }
#   }
#   say $reporte;

print Dumper( %registros ) if $verbose;

# Grabar Registros ### ### ###
my $registro_actualizado = $json->encode(\%registros);
write_file( 'registro.json', $registro_actualizado );

sub hola_pedido {
	my $i = 'Hola, Pedido!';

	my (
		$item,
		$mes,
		$dia,
		$hora,
		$duracion,
		$quien,
		$comentario
	) = @_;



	return  $i;
}

# Subrutinas ### ### ###
sub formular_pedido {

	my (
		$item,
		$mes,
		$dia,
		$hora,
		$duracion,
		$quien,
		$comentario
	) = @_;

	# Condiciones del pedido
	my $item_existe;

	# Integridad de las fechas
	my $duracion_correcta;
	my $fecha_correcta;

	# Pedido listo para procesar
	my $pedido_OK;

	# Informacion para el usuario
	my $porque = "";

	if( !exists($inventario{$item}) ) {
		$item_existe = 0;
		$porque = "$item: No encontrado";

	}else {
		$item_existe = 1;
		if( ($duracion >= $limite_duracion) || ($duracion <= 0)  ){
			$porque = "Duracion: 0 < $duracion? > $limite_duracion";

		}else {
			$duracion_correcta = 1;

			my (
				$resultado,
				$mensaje
			) = fecha_correcta( $mes, $dia, $hora );
			$fecha_correcta = $resultado;

			if( !$fecha_correcta ) {
				$porque = $mensaje;
			}else {

				# Obtener timestamp retira
				my $pedido_retira = POSIX::mktime(0,0,
					$hora,$dia,$mes-1,$anio-1900);

				# Calcular vuelta
				my $pedido_vuelve = POSIX::mktime(0,0,
					$hora+$duracion,$dia,$mes-1,$anio-1900);

				$pedido_OK = {
					item    => $item,
					cuando    => $pedido_retira."-".$pedido_vuelve,
					quien   => $quien,
					comentario  => $comentario
				};

=pod
ESTRUCTURA DE PEDIDO
	Item ( como en inventario )
	Cuando ( $pedido_retira."-".$pedido_vuelve )
	Quien Hizo el pedido
	Comentario
=cut

			}
		}
	}

	if (
		$item_existe &&
		$duracion_correcta &&
		$fecha_correcta
	){
		return
			"[$item-".
			"$anio/$mes/$dia:$hora".
			"x$duracion] ".
			"aprobado",
			$pedido_OK;
	} else{
		return
			"[$item-".
			"$anio/$mes/$dia:$hora".
			"x$duracion] ".
			"RECHAZADO ".
			"($porque)";
	}
}


sub fecha_correcta {
	my ( $mes, $dia, $hora ) =  @_;

	my $mes_correcto;
	my $dia_correcto;
	my $hora_correcta;

	my $porque;
	my $limite_mes = cantidad_dias( $mes );

	if( ( $mes >= 1 ) && ( $mes <= 12 ) ) {
		$mes_correcto = 1;
		if( ( $dia >= 1 ) && ( $dia <= $limite_mes ) ) {

			$dia_correcto = 1;

			if ( $hora < 24 ){
				$hora_correcta = 1;
			}else{
				$porque = "hora $hora?"
			}
		}else{
			$porque = "dia $dia > $limite_mes?"
		}
	}else{
		$porque = "mes $mes?"
	}

	if( $mes_correcto && $dia_correcto && $hora_correcta ){
		return 1;
	}else{
		return 0, $porque;
	}
}

sub cantidad_dias{
	my $m = $_[0];

	my %mes2dias = qw(
		1 31  2 28  3 31  4 30  5 31  6 30
		7 31  8 30  9 31  10 31  11 30  12 31
	);

	# Revisar esto
	if( es_bisiesto($anio) ){
		%mes2dias = qw(
			1 31  2 29  3 31  4 30  5 31  6 30
			7 31  8 30  9 31  10 31  11 30  12 31
		);
	}

	return $mes2dias{ lc substr($m, 0, 3) };
}

sub es_bisiesto{
	my $y = shift;
	my $bisiesto = 0;
	if( $y =~ /^\d+?$/ ) {
		if( !($y % 400) ){
			$bisiesto = 1;
		}elsif( !($y % 100) ){
			$bisiesto = 0;
		}elsif( !($y % 4) ){
			$bisiesto = 1;
		}
	}
	return $bisiesto;
}

sub disponibilidad{

	my $p = $_[0];
	my $item = $p->{item};
	my $ocupado = 0;

	if($registros{$item}) {

		my (
			$pedido_retira,
			$pedido_vuelve
		) = split /-/, $p->{cuando};

		# Consultar reservas
		foreach my $reserva ( keys %{$registros{$item}} ) {
			my (
				$registro_retira,
				$registro_vuelve
			) = split /-/, $registros{$item}{$reserva}{cuando};

			# http://c2.com/cgi/wiki?TestIfDateRangesOverlap
			if( $pedido_retira < $registro_vuelve &&
				$registro_retira < $pedido_vuelve ){
				$ocupado = 1;
				# Aca habria que dar info de cual molesta?
			}
		}
	}

	if(!$ocupado){
		return "recurso disponible",$p;
	}else{
		return "recurso OCUPADO";
	}
}

sub registrar_pedido {
	my $p  = $_[0];

	my $item  = $p->{item};
	my $pedido_id = luniqid; # ID de pedido

	my $pedido_embalado = {
		cuando    => $p->{cuando},
		quien   => $p->{quien},
		comentario  => $p->{comentario}
	};
	$registros{$item}{$pedido_id} = $pedido_embalado;
	return "RESERVO: $pedido_id";
}

1;