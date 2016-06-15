--***
create procedure wIaPuncteLivrare @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wIaPuncteLivrareSP' and type='P')
	exec wIaPuncteLivrareSP @sesiune, @parXML 
else begin

Declare @tert varchar(13), @cautare varchar(200), @fltDenTert varchar(80), @fltDescriere varchar(30)

select @tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	@cautare = isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(200)'), ''), 
	/* 
	filtrele pe denumire tert si descriere pot fi folosite doar atunci cand procedura 
	e folosita pt. macheta distincta de puncte de livrare (catalog), nu la chemarea dinspre Terti ca detaliere; 
	totusi, dentert va fi completat la chemarea pt. detaliere - aici nu ar fi probleme;
	trebuie avut grija la introducerea unor noi filtre sa nu se suprapuna eronat peste campuri existente in terti (descrierea nu e in terti, deci asta e ok).
	*/
	@fltDenTert = isnull(@parXML.value('(/row/@dentert)[1]', 'varchar(80)'), ''), 
	@fltDescriere = isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(30)'), '')

declare @subunitate varchar(9)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

select @cautare = replace(@cautare, ' ', '%'), 
	@fltDenTert = replace(@fltDenTert, ' ', '%'), 
	@fltDescriere = replace(@fltDescriere, ' ', '%')

select top 100 rtrim(p.tert) as tert, rtrim(isnull(t.denumire, '')) as dentert, 
	rtrim(p.identificator) as punctlivrare, rtrim(p.descriere) as denpunctlivrare, 
	rtrim(isnull(p.loc_munca, '')) as lm, rtrim(isnull(lm.denumire, '')) as denlm,
	rtrim(p.pers_contact) as localitate, rtrim(isnull(l.oras, '')) as denlocalitate,
	rtrim(p.nume_delegat) as numedelegat, 
	rtrim(left(p.buletin, 2)) as seriebuletin, rtrim(substring(p.buletin, 3, 10)) as numarbuletin, rtrim(p.eliberat) as eliberatbuletin, 
	rtrim(p.mijloc_tp) as mijloctransport, rtrim(isnull(m.descriere, '')) as denmijloctransport, 
	rtrim(p.adresa2) as adresa, 
	rtrim(case when isnull(it.zile_inc, 0)=0 then p.telefon_fax2 else '' end) as judet, isnull(j.denumire, '') as denjudet, 
	rtrim(case when isnull(it.zile_inc, 0)>0 then p.telefon_fax2 else '' end) as tara, isnull(tari.denumire, '') as dentara, 
	rtrim(p.e_mail) as email, 
	rtrim(p.banca2) as banca, 
	rtrim(p.cont_in_banca2) as continbanca, 
	rtrim(p.banca3) as ruta, 
	rtrim(isnull(r.denumire, '')) as denruta, 
	rtrim(p.cont_in_banca3) as contclient, 
	rtrim(isnull(c.denumire_cont, '')) as dencontclient, 
	convert(int, p.indicator) as indicator, 
	rtrim(p.grupa13) as grupa13, 
	convert(decimal(7, 2), p.discount) as discount, 
	p.zile_inc as zileincasare, 
	rtrim(p.observatii) as nrautorizatie,
	convert(decimal(14, 2), p.sold_ben) as soldben, 
	convert(decimal(14, 2), p.sold_ben) as categpret, 
	RTRIM(categpret.Denumire)as dencategpret
from infotert p
	left join terti t on t.subunitate=p.subunitate and t.tert=p.tert
	left join infotert it on it.subunitate=p.subunitate and it.tert=p.tert and it.identificator=''
	left join lm on lm.cod=p.loc_munca
	left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=p.telefon_fax2 
	left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=p.telefon_fax2 
	left join localitati l on l.cod_judet=p.telefon_fax2 and l.cod_oras=p.pers_contact
	left join masinexp m on m.numarul_mijlocului=p.mijloc_tp
	left join ruteliv r on r.cod=p.banca3
	left join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_in_banca3
	left join categpret on categpret.categorie=p.Sold_ben
where p.subunitate=@subunitate and (@tert='' or p.tert=@tert) and p.identificator<>''
	and (@cautare='' 
		or p.descriere like '%' + @cautare + '%' 
		or @tert='' and isnull(t.denumire, '') like '%' + @cautare + '%' 
		or (p.pers_contact like '%' + @cautare + '%' or isnull(l.oras, '') like '%' + @cautare + '%') 
		or p.e_mail like '%' + @cautare + '%')
	and isnull(t.denumire, '') like '%' + @fltDenTert + '%'
	and p.descriere like '%' + @fltDescriere + '%'
order by p.tert, p.identificator
for xml raw

end
