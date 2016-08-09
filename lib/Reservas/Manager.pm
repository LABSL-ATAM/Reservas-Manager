package Reservas::Manager;
use Dancer2;
use Reservas::Gestor;

our $VERSION = '0.1';

# Como llamar subs de un modulo
my $i = Reservas::Gestor::ingresar_pedido();

get '/' => sub {
    template 'index';
};

true;
