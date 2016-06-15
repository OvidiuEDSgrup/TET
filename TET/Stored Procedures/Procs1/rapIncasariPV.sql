--***
create procedure rapIncasariPV (@ordonare varchar(1) ,@datajos datetime, @datasus datetime, @gestiune varchar(100), @tip_doc int, @casa_marcat varchar(100), @vanzator varchar(100))
as
set transaction isolation level read uncommitted

declare @subunitate varchar(50) 

select	@subunitate=(case when parametru='SUBPRO' then rtrim(val_alfanumerica) else @subunitate end)
from par 
where Tip_parametru='GE' and Parametru='SUBPRO'

declare @f_gestiune bit, @f_casa_marcat bit
select  @f_gestiune=(case when isnull(@gestiune,'')='' then 0 else 1 end),
		@f_casa_marcat=(case when isnull(@casa_marcat,'')='' then 0 else 1 end)

select casa_de_marcat,vinzator,numar_bon, data, tip, 
	(case when tip='31' then 'Numerar' when tip='32' then 'Ordin de plata' when tip='33' then 'CEC' when tip='34' then 'Credit' 
	when tip='35' then 'Tichet' when tip='36' then 'Credit card' else '' end) as tip_inc,
	numar_document_incasare, data_documentului,
	cantitate, pret, total,
	(case when @ordonare='b' then  numar_bon else tip end) as ord,
	rtrim(bp.gestiune) gestiune, rtrim(g.Denumire_gestiune) as denumire_gestiune
from bp
	left join gestiuni g on bp.Gestiune=g.Cod_gestiune and g.Subunitate=@subunitate
where tip in ('31','32','33','34','35','36') and 
	data between @datajos and @datasus and (@f_gestiune=0 or loc_de_munca=@gestiune) and 
	(@tip_doc=0 or  bp.factura_chitanta=(case when @tip_doc=1 then 1 else 0 end))
	and (@f_casa_marcat=0 or casa_de_marcat=@casa_marcat)
	and (@vanzator is null or bp.vinzator=@vanzator)
order by ord , data, numar_bon
