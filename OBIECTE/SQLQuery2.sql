/****** Object:  StoredProcedure [dbo].[wIaPuncteLivrare]    Script Date: 02/09/2012 16:58:21 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

--***
ALTER procedure [dbo].[wIaPuncteLivrare] @sesiune varchar(50), @parXML xml
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
	@fltDescriere = isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(80)'), '')

declare @subunitate varchar(9), @AdrPLiv int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
exec luare_date_par 'GE', 'ADRPLIV', @AdrPLiv output, 0, ''

select @cautare = replace(@cautare, ' ', '%'), 
	@fltDenTert = replace(@fltDenTert, ' ', '%'), 
	@fltDescriere = replace(@fltDescriere, ' ', '%')

select top 100 rtrim(p.tert) as tert, rtrim(isnull(t.denumire, '')) as dentert, 
rtrim(p.identificator) as punctlivrare, rtrim(p.descriere) as denpunctlivrare, 
rtrim(isnull(p.loc_munca, '')) as lm, rtrim(isnull(lm.denumire, '')) as denlm,
rtrim(case when @AdrPLiv=0 then p.pers_contact else '' end) as persoanacontact, 
rtrim(case when @AdrPLiv=1 then p.pers_contact else '' end) as localitate, rtrim(isnull(l.oras, '')) as denlocalitate,
rtrim(p.nume_delegat) as numedelegat, 
rtrim(left(p.buletin, 2)) as seriebuletin, rtrim(substring(p.buletin, 3, 10)) as numarbuletin, rtrim(p.eliberat) as eliberatbuletin, 
rtrim(p.mijloc_tp) as mijloctransport, rtrim(isnull(m.descriere, '')) as denmijloctransport, 
rtrim(p.adresa2) as adresa2, /*liber*/
rtrim(case when @AdrPLiv=0 then p.telefon_fax2 else '' end) as telefonfax, 
rtrim(case when @AdrPLiv=1 and isnull(it.zile_inc, 0)=0 then p.telefon_fax2 else '' end) as judet, isnull(j.denumire, '') as denjudet, 
rtrim(case when @AdrPLiv=1 and isnull(it.zile_inc, 0)>0 then p.telefon_fax2 else '' end) as tara, isnull(tari.denumire, '') as dentara, 
rtrim(case when @AdrPLiv=0 then p.e_mail else '' end) as email, 
rtrim(case when @AdrPLiv=1 then p.e_mail else '' end) as adresa, 
rtrim(p.banca2) as banca, rtrim(p.cont_in_banca2) as continbanca, 
rtrim(p.banca3) as ruta, rtrim(isnull(r.denumire, '')) as denruta, 
rtrim(p.cont_in_banca3) as contclient, rtrim(isnull(c.denumire_cont, '')) as dencontclient, 
convert(int, p.indicator) as indicator, rtrim(p.grupa13) as grupa13, convert(decimal(14, 2), p.sold_ben) as soldben, convert(decimal(7, 2), p.discount) as discount, /*nefolosite*/
p.zile_inc as zileincasare, rtrim(p.observatii) as nrautorizatie
from infotert p
left join terti t on t.subunitate=p.subunitate and t.tert=p.tert
left join infotert it on it.subunitate=p.subunitate and it.tert=p.tert and it.identificator=''
left join lm on lm.cod=p.loc_munca
left join judete j on @AdrPLiv=1 and isnull(it.zile_inc, 0)=0 and j.cod_judet=p.telefon_fax2 
left join tari on @AdrPLiv=1 and isnull(it.zile_inc, 0)>0 and tari.cod_tara=p.telefon_fax2 
left join localitati l on @AdrPLiv=1 and l.cod_judet=p.telefon_fax2 and l.cod_oras=p.pers_contact
left join masinexp m on m.numarul_mijlocului=p.mijloc_tp
left join ruteliv r on r.cod=p.banca3
left join conturi c on c.subunitate=p.subunitate and c.cont=p.cont_in_banca3
where p.subunitate=@subunitate and (@tert='' or p.tert=@tert) and p.identificator<>''
and (@cautare='' 
	or p.descriere like '%' + @cautare + '%' 
	or @tert='' and isnull(t.denumire, '') like '%' + @cautare + '%' 
	or @AdrPLiv=1 and (p.pers_contact like '%' + @cautare + '%' or isnull(l.oras, '') like '%' + @cautare + '%') 
	or @AdrPLiv=1 and p.e_mail like '%' + @cautare + '%')
and isnull(t.denumire, '') like '%' + @fltDenTert + '%'
and p.descriere like '%' + @fltDescriere + '%'
order by p.tert, p.identificator
for xml raw

end
/*
populare 1: ca submacheta de detaliere, chemata dinspre terti; nume tip/subtip ajunge sa fie completata pe o pozitie, ca apoi merge cu max()
#start populare
infotert
C, CG, T, 1
Terti (puncte de livrare)
Terti (puncte de livrare)

('PL','',3,'Identificator','','@punctlivrare','',0,'','','','char',5,'C','C','','','','',1,'','','',1,0,1,'Puncte livrare',2,1),
('PL','',4,'Descriere','','@denpunctlivrare','',0,'','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',2,1),
('PL','',5,'Loc de munca','','@lm','@denlm',0,'','','','char',9,'C','AC','wLocm','','','',0,'','','',1,1,1,'',2,1),
('PL','',6,'Denumire loc de munca','','@denlm','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',20,'Persoana contact','','@persoanacontact','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',2,1),
('PL','',21,'Localitate','','@localitate','@denlocalitate',0,'','','','char',20,'C','AC','wLocalitati','','','',0,'','','',1,1,1,'',2,1),
('PL','',22,'Denumire localitate','','@denlocalitate','',0,'','','','char',30,'C','C','','','','',1,'','','',1,0,0,'',2,1),
('PL','',11,'Nume delegat','','@numedelegat','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',12,'Serie buletin','','@seriebuletin','',0,'','','','char',2,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',13,'Numar buletin','','@numarbuletin','',0,'','','','char',10,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',14,'Eliberat','','@eliberatbuletin','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',9,'Mijloc transport','','@mijloctransport','@denmijloctransport',0,'','','','char',20,'C','AC','wMasiniExpeditie','','','',0,'','','',1,1,1,'',2,1),
('PL','',10,'Denumire mijloc transport','','@denmijloctransport','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',31,'Adresa 2','','@adresa2','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',2,1),
('PL','',15,'Telefon / fax','','@telefonfax','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',2,1),
('PL','',16,'Judet','','@judet','@denjudet',0,'','','','char',20,'C','AC','wJudete','','','',0,'','','',1,1,1,'',2,1),
('PL','',17,'Denumire judet','','@denjudet','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',18,'Tara','','@tara','@dentara',0,'','','','char',20,'C','AC','wTari','','','',0,'','','',1,1,1,'',2,1),
('PL','',19,'Denumire tara','','@dentara','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',23,'E-mail','','@email','',0,'','','','char',50,'C','C','','','','',0,'','','',1,0,1,'',2,1),
('PL','',24,'Adresa','','@adresa','',0,'','','','char',50,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',27,'Banca','','@banca','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',2,1),
('PL','',28,'Cont in banca','','@continbanca','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',7,'Ruta','','@ruta','@denruta',0,'','','','char',20,'C','AC','wRute','','','',0,'','','',1,1,1,'',2,1),
('PL','',8,'Denumire ruta','','@denruta','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',29,'Cont client','','@contclient','@dencontclient',0,'','','','char',35,'C','AC','wConturi','','','',0,'','','',1,1,1,'',2,1),
('PL','',30,'Denumire cont client','','@dencontclient','',0,'','','','char',80,'C','C','','','','',0,'','','',1,0,0,'',2,1),
('PL','',32,'Indicator','','@indicator','',0,'','','','bit',1,'N','CHB','','','','',0,'','','',1,0,1,'',2,1),
('PL','',33,'Grupa13','','@grupa13','',0,'','','','char',13,'C','C','','','','',0,'','','',1,0,1,'',2,1),
('PL','',34,'Sold ben','','@soldben','',0,'','','','decimal',14,'N','N','','','','',0,'','','',1,0,1,'',2,1),
('PL','',35,'Discount','','@discount','',0,'','','','decimal',7,'N','N','','','','',0,'','','',1,1,1,'',2,1),
('PL','',26,'Zile incasare','','@zileincasare','',0,'','','','int',1,'N','N','','','','',0,'','','',1,1,1,'',2,1),
('PL','',25,'Numar autorizatie','','@nrautorizatie','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',2,1)
#sfarsit populare
populare 2: ca macheta catalog "stand-alone"; in input tertul e pus cu vizibilitate 0 pt. ca se face o singura configurare (form) pt. macheta de detaliere si cea catalog
#start populare
infotert
C, CG, PL
Puncte de livrare
Puncte de livrare
('','',1,'Tert','','@tert','',0,'','','','varchar',13,'C','C','','','','',1,'','','',0,0,0,'',0,1),
('','',2,'Denumire tert','','@dentert','',0,'','','','varchar',80,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Nume prenume','','@descriere','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1)

('','',1,'Tert','','@tert','@dentert',0,'','','','char',13,'C','AC','wTerti','','','',0,'','','',1,0,1,'',0,1),
('','',2,'Denumire tert','','@dentert','',0,'','','','char',80,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Identificator','','@punctlivrare','',0,'','','','char',5,'C','C','','','','',1,'','','',1,0,1,'',0,1),
('','',4,'Descriere','','@denpunctlivrare','',0,'','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',5,'Loc de munca','','@lm','@denlm',0,'','','','char',9,'C','AC','wLocm','','','',0,'','','',1,1,1,'',0,1),
('','',6,'Denumire loc de munca','','@denlm','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',20,'Persoana contact','','@persoanacontact','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',21,'Localitate','','@localitate','@denlocalitate',0,'','','','char',20,'C','AC','wLocalitati','','','',0,'','','',1,1,1,'',0,1),
('','',22,'Denumire localitate','','@denlocalitate','',0,'','','','char',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',11,'Nume delegat','','@numedelegat','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',12,'Serie buletine','','@seriebuletin','',0,'','','','char',2,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',13,'Numar buletin','','@numarbuletin','',0,'','','','char',10,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',14,'Eliberat','','@eliberatbuletin','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',9,'Mijloc transport','','@mijloctransport','@denmijloctransport',0,'','','','char',20,'C','AC','wMasiniExpeditie','','','',0,'','','',1,1,1,'',0,1),
('','',10,'Denumire mijloc transport','','@denmijloctransport','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',31,'Adresa 2','','@adresa2','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',15,'Telefon / fax','','@telefonfax','',0,'','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',16,'Judet','','@judet','@denjudet',0,'','','','char',20,'C','AC','wJudete','','','',0,'','','',1,1,1,'',0,1),
('','',17,'Denumire judet','','@denjudet','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',18,'Tara','','@tara','@dentara',0,'','','','char',20,'C','AC','wTari','','','',0,'','','',1,1,1,'',0,1),
('','',19,'Denumire tara','','@dentara','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',23,'E-mail','','@email','',0,'','','','char',50,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',24,'Adresa','','@adresa','',0,'','','','char',50,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',27,'Banca','','@banca','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',28,'Cont in banca','','@continbanca','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',7,'Ruta','','@ruta','@denruta',0,'','','','char',20,'C','AC','wRute','','','',0,'','','',1,1,1,'',0,1),
('','',8,'Denumire ruta','','@denruta','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',29,'Cont client','','@contclient','@dencontclient',0,'','','','char',35,'C','AC','wConturi','','','',0,'','','',1,1,1,'',0,1),
('','',30,'Denumire cont client','','@dencontclient','',0,'','','','char',80,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',32,'Indicator','','@indicator','',0,'','','','bit',1,'N','CHB','','','','',0,'','','',1,0,1,'',0,1),
('','',33,'Grupa13','','@grupa13','',0,'','','','char',13,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',34,'Sold ben','','@soldben','',0,'','','','decimal',14,'N','N','','','','',0,'','','',1,0,1,'',0,1),
('','',35,'Discount','','@discount','',0,'','','','decimal',7,'N','N','','','','',0,'','','',1,1,1,'',0,1),
('','',26,'Zile incasare','','@zileincasare','',0,'','','','int',1,'N','N','','','','',0,'','','',1,1,1,'',0,1),
('','',25,'Numar autorizatie','','@nrautorizatie','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',0,1)
#sfarsit populare
*/

GO

