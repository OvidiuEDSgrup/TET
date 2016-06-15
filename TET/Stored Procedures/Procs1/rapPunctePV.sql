--***
create procedure rapPunctePV (@datajos datetime=null,@datasus datetime=null,@tert varchar(13)=null,@cod varchar(13)=null, @UID_card varchar(36)=null,
		@tel varchar(50))
as
set transaction isolation level read uncommitted

select p.IdAntetBon, a.Tert as tert, RTRIM(t.Denumire) as dentert, RTRIM(bp.Cod_produs) as cod, RTRIM(n.Denumire) as dencod,
	CONVERT(char(10),bp.data,103) as data, bp.Cantitate as cantitate, bp.Pret as pret, bp.Tva as tva, bp.Total as total,
	c.Nume_posesor_card, c.Telefon_posesor_card,RTRIM(bp.Vinzator) as vanzator,
	p.Puncte as puncte, p.Tip tip , c.UID as uid_card,
	bp.Numar_bon as numar_bon, left(bp.Ora,2)+':'+SUBSTRING(bp.Ora,3,2) as ora, 
	case when bp.Numar_linie=1 then (case when p.tip='C' then -1 else 1 end) * convert(float,puncte) else 0 end as puncteTip
from PvPuncte p 
	inner join CarduriFidelizare c on p.UID_card=c.UID
	left join bp on bp.IdAntetBon=p.IdAntetBon and bp.Tip=21
	left join nomencl n on n.Cod=bp.Cod_produs
	left join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
	left join terti t on a.Tert=t.Tert
where (c.Tert=@tert or ISNULL(@tert,'')='')
	and (c.UID=@UID_card or ISNULL(@UID_card,'')='')
	and (bp.Cod_produs=@cod or ISNULL(@cod,'')='')
	and (bp.Data between ISNULL(@datajos,'1901-01-01') and ISNULL(@datasus,'2099-01-01'))
	and (rtrim(ltrim(c.Telefon_posesor_card))=@tel or ISNULL(@tel,'')='')
order by bp.Data desc ,bp.IdAntetBon desc, bp.IdPozitie 


