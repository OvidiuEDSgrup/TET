--***
CREATE procedure [dbo].[wmDetPuncteLivrare] @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetPuncteLivrareSP' and type='P')
	exec wmDetPuncteLivrareSP @sesiune, @parXML 
else 
begin
	set transaction isolation level READ UNCOMMITTED
	declare @utilizator varchar(100),@subunitate varchar(9),@stare varchar(10),@comanda varchar(20),@explicatii varchar(100)
	declare @linietotal varchar(100),@tert varchar(20),@data datetime,@cod varchar(20)
	declare @clearSearch int --pentru stergere camp de search
	set @clearSearch=0
	exec wIaUtilizator @sesiune, @utilizator output
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	select 
		'wmScriuCantitate' as detalii,1 as areSearch,'D' as tipDetalii,
		dbo.f_wmIaForm('PL') form
	for xml raw,Root('Mesaje')
end
