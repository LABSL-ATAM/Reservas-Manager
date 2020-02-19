package Reservas::Gestor;

use strict;
use warnings;
use Data::Dumper;
use Data::Uniqid qw ( luniqid );
#TZ=PST8PDT;
#use Date::Manip::TZ;
#$tz = new Date::Manip::TZ;
#use Date::Manip;
use File::Slurp;
use JSON;
my $json = JSON->new;


# # Args / Params
my $verbose = 0;

# Defaults Globales
my ($sec,$min,$hour,$day,$month,$yr19,@rest) = localtime(time);
my $anio = $yr19+1900; # año actual ¿salvo q se indique?
my $limite_duracion = 72;

# Datos 
my %inventario = inventario();
my %registros = registros();

print Dumper( %registros ) if $verbose;


# grabar();

# Subrutinas ### ### ###

sub inventario{
	# # Inventario (items disponibles)
	my @inventario =  split /\W/, read_file('inventario');
	my %inventario = map { $_ => 1 } @inventario; # POR REVISAR
	return %inventario;
}

sub registros{
	my $registros_RAW = read_file('registro.json');
	# my $json = JSON->new;
	my $registro_JSON = $json->decode($registros_RAW);
	return %$registro_JSON;
}

sub evaluar{
	my %pedido = @_;
	#print Dumper(%pedido);
	my $item 		= $pedido{item};
	my ($anio,$mes,$dia) 	= split /-/, $pedido{'fecha'};
	my $hora 		= $pedido{hora};
	my $duracion 		= $pedido{duracion};
	my $quien 		= $pedido{quien};
	my $comentario 		= $pedido{comentario};

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
		if( ($duracion > $limite_duracion) || ($duracion < 1)  ){
			$porque = "Duracion: 1 < $duracion > $limite_duracion";

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
			"\n",
			$pedido_OK;
	} else{
		return
			"[$item-".
			"$anio/$mes/$dia:$hora".
			"x$duracion] ".
			"Consulta <b>RECHAZADA</b> ".
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
	# primera decena tiene leading 0
	# print Dumper(s/^0/$m/g);

	my %mes2dias = qw(
		01 31  02 28  03 31  04 30  05 31 06 30
		07 31  08 30  09 31  10 31  11 30  12 31
	);

	# Revisar esto
	if( es_bisiesto($anio) ){
		%mes2dias = qw(
			01 31  02 29  03 31  04 30  05 31  06 30
			07 31  08 30  09 31  10 31  11 30  12 31
		);
	}

	return $mes2dias{ lc substr($m, 0, 3) };
}

sub es_bisiesto{
	my $y = shift;
	my $bisiesto = 0;
	if( $y =~ /^\d+?$/ ) {
		if( !($y % 4 )){
			$bisiesto++;
		}
	}
	return $bisiesto;
}

sub consultar{
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
		return "Recurso <b>DISPONIBLE</b>",$p;
	}else{
		return "Recurso <b>OCUPADO</b>";
	}
}

sub registrar{
	my $p  = $_[0];
	my $item  = $p->{item};
	my $reserva_id = luniqid; # ID de pedido

	my $pedido_embalado = {
		cuando    => $p->{cuando},
		quien   => $p->{quien},
		comentario  => $p->{comentario}
	};
	$registros{$item}{$reserva_id} = $pedido_embalado;
	return "INGRESO Reserva: <b>$reserva_id</b>";
}

sub borrar{
	my $id= $_[0];
	foreach my $item (keys %registros){
		foreach my $reserva (keys %{$registros{$item}}){
			if($id eq $reserva ){
				print Dumper $registros{$item}{$reserva};
				delete($registros{$item}{$reserva});
			}	
		}
	}
	return "BORRO Reserva: <b>$id</b>";
}

sub grabar{
	# Grabar Registros ### ### ###
	my $registro_actualizado = $json->encode(\%registros);
	write_file( 'registro.json', $registro_actualizado );
}

1;
