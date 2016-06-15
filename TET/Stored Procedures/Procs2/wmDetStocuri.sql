--***
create procedure wmDetStocuri @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmDetStocuriSP' and type='P')
begin
	exec wmDetStocuriSP @sesiune, @parXML 
	return 0
end

set transaction isolation level READ UNCOMMITTED
declare @cod varchar(20),@stTotal varchar(20), @adaugaPoza xml, @stocuri xml

set @cod=@parXML.value('(/row/@cod)[1]','varchar(100)')
set @stTotal=ltrim(convert(varchar(20),convert(money,(select SUM(stoc) from stocuri where Subunitate='1' and stocuri.Cod=@cod),1)))

select @adaugaPoza =
	(select
		rtrim(@cod) as cod,
		'Adauga poza' as denumire,
		'server://assets/Imagini/Meniu/camera.png' as poza,
		'wmAdaugaPozaNomencl' as procdetalii,
		'0xF5F5DC' as culoare,
		dbo.f_wmIaForm('PNOM') as form,
		'D' tipdetalii
	for xml raw)

select @stocuri = 
	(select RTRIM(gestiuni.Denumire_gestiune) as cod,
	RTRIM(gestiuni.Denumire_gestiune) as denumire,
	ltrim(convert(varchar(20),CONVERT(money,sum(stocuri.stoc)),1))+' '+rtrim(nomencl.um) as info
	from stocuri
	inner join gestiuni on stocuri.Subunitate=gestiuni.Subunitate and stocuri.Cod_gestiune=gestiuni.Cod_gestiune
	inner join nomencl on stocuri.cod=nomencl.cod
	where stocuri.Subunitate='1' and
	stocuri.Cod=@cod and stocuri.stoc<>0
	group by stocuri.Cod_gestiune,gestiuni.Denumire_gestiune,nomencl.um
	for xml raw)

select
	@adaugaPoza, @stocuri
for xml path('Date')

select 
	rtrim(denumire)+': '+@stTotal+' '+RTRIM(um) as titlu,
	0 as areSearch
from nomencl where cod=@cod
for xml raw,Root('Mesaje')

