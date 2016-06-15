--***
/* procedura pentru populare macheta de gen. D390 */
create procedure wOPGenerareD390_p @sesiune varchar(50), @parXML xml 
as  
declare @codfiscal varchar(20), @tipdecl int, @numedecl varchar(150), @prendecl varchar(50), 
	@functiedecl varchar(50), @calefisier varchar(300), @lunaalfa varchar(15), @luna int, @an int, 
	@datajos datetime, @datasus datetime, @RP int, @FF int, @listaFF varchar(200), @FB int, 
	@listaFB varchar(200), @AS int

exec luare_date_par 'GE', 'NDECLTVA', 0, 0, @numedecl output
exec luare_date_par 'GE', 'FDECLTVA', 0, 0, @functiedecl output
exec luare_date_par 'GE', 'D390AS', @AS output, 0, ''
exec luare_date_par 'GE', 'D390FB', @FB output, 0, @listaFB output
exec luare_date_par 'GE', 'D390FF', @FF output, 0, @listaFF output
exec luare_date_par 'GE', 'D390RP', @RP output, 0, ''

select @functiedecl as functiedecl, LEFT(@numedecl,CHARINDEX(' ',@numedecl)-1) as numedecl, 
	right(rtrim(@numedecl),len(rtrim(@numedecl))-CHARINDEX(' ',rtrim(@numedecl))) as prendecl, 
	@AS as [AS], @FB as FB, @listaFB as listaFB, @FF as FF, @listaFF as listaFF, @RP as RP,
	convert(varchar(20),@parxml.value('(row/@datalunii)[1]','datetime'),101) as datajos
for xml raw
