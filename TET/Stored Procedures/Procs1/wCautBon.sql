--***
/* cauta bon pentru generarea facturilor din bonuri */
create procedure wCautBon @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wCautBonSP' and type='P')
begin
	exec wCautBonSP @sesiune, @parXML 
	return 0
end

declare @casaM int, @data datetime, @numar varchar(20), @zecimaleCasa int

select	@casaM = @parXML.value('(/row/@casaM)[1]', 'int'),
		@data = @parXML.value('(/row/@data)[1]', 'datetime'),
		@numar = @parXML.value('(/row/@nrBon)[1]', 'int'),
		@casaM = @parXML.value('(/row/@casaM)[1]', 'int')

/* verific daca inca nu a fost descarcat ultimul bon */
if exists (select 1 from bt where tip='21' and factura_chitanta=1 and casa_de_marcat=@casaM and data= @data and numar_bon=@numar)	
begin
	declare @msgEroare varchar(max)
	set @msgEroare='Nu s-a terminat descarcarea gestiunii pentru bonul '+convert(varchar,@numar)+' din '+CONVERT(varchar,@data,104)+'.'+CHAR(10)
	+'Incercati aducerea bonului peste cateva secunde.'
	raiserror(@msgEroare,11,1)
	return 0
end

/* selectul functioneaza bine pentru casele de marcat care lucreaza cu 2 zecimale. 
Pentru Rompos(care lucreaza cu 4 zecimale, s-ar putea sa nu 'bata' total bon adus de aici, cu totalul de pe bonul fiscal.
De discutat cand apare efectiv o problema(daca apare). */
select 
@casaM as casamarcat,
CONVERT(char(10),@data, 101) as data,@numar as nrbon,
rtrim(n.denumire) as denumire,n.um,convert(decimal(5,2),bp.Cota_TVA) as cotatva,
convert(decimal(12,2),bp.pret) as pretcatalog,convert(decimal(12,2),bp.discount) as discount,
convert(decimal(12,2),bp.pret) as pret,
convert(decimal(12,3),round((bp.total-bp.tva)/bp.Cantitate,3)) as pretftva,
convert(decimal(12,3),round(bp.total-bp.tva,3)) as valftva,
convert(decimal(12,3),bp.tva) as tva,
convert(decimal(12,2),bp.cantitate) as cantitate,bp.tip,
convert(decimal(12,2),bp.total) as total,
a.Factura as factura
from bp
left join antetBonuri a on bp.IdAntetBon=a.IdAntetBon
inner join nomencl n on bp.cod_produs=n.cod
where bp.tip='21' and bp.factura_chitanta=1
and bp.casa_de_marcat=@casaM
and bp.data= @data
and bp.numar_bon=@numar
for xml raw
