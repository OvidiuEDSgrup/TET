
create procedure CreazaDiezLegaturi
as

	alter table #Legaturi add idPozContract int, idPozDoc int, idContract int, idJurnal int, detalii XML
