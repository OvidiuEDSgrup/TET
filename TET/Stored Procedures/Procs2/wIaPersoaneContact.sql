--***
create procedure wIaPersoaneContact @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wIaPersoaneContactSP' and type='P')
	exec wIaPersoaneContactSP @sesiune, @parXML 
else begin

Declare @tert varchar(13), @cautare varchar(200), @fltDenTert varchar(80), @fltDescriere varchar(30),@tip varchar(2),@subtip varchar(2)

select @tert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''), 
	@cautare = isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(200)'), ''), 
	@tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') ,
	@subtip = isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '') ,
	/* 
	filtrele pe denumire tert si descriere (=nume + prenume) pot fi folosite doar atunci cand procedura 
	e folosita pt. macheta distincta de persoane de contact (catalog), nu la chemarea dinspre Terti ca detaliere; 
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
	rtrim(p.identificator) as identificator, rtrim(p.descriere) as descriere, 
	rtrim(isnull(p.loc_munca, '')) as info3, 
	rtrim(p.pers_contact) as nume, rtrim(p.nume_delegat) as prenume, 
	rtrim(dbo.fStrToken(p.buletin, 1, ',')) as seriebuletin, 
	rtrim(dbo.fStrToken(p.buletin, 2, ',')) as numarbuletin, 
	rtrim(p.eliberat) as eliberatbuletin, rtrim(p.mijloc_tp) as functie, 
	rtrim(dbo.fStrToken(p.adresa2, 1, ',')) as judet, 
	rtrim(dbo.fStrToken(p.adresa2, 2, ',')) as localitate,
	rtrim(j.denumire) as denjudet,
	rtrim(l.oras) as denlocalitate,
	rtrim(p.telefon_fax2) as telefon, rtrim(p.e_mail) as email, 
	rtrim(p.banca2) as strada, rtrim(p.cont_in_banca2) as info1, rtrim(pl.descriere) as denpunctlivrare, 
	rtrim(dbo.fStrToken(p.banca3, 1, ',')) as numar, rtrim(dbo.fStrToken(p.banca3, 2, ',')) as bloc, 
	rtrim(dbo.fStrToken(p.banca3, 3, ',')) as scara, rtrim(dbo.fStrToken(p.banca3, 4, ',')) as apartament, 
	rtrim(p.cont_in_banca3) as info2, p.indicator as info4, rtrim(p.grupa13) as codpostal, 
	convert(char(10), (case when p.sold_ben<=693961 then '01/01/1901' else dateadd(d, p.sold_ben-693961, '01/01/1901') end), 101) as datanasterii,
	convert(decimal(7, 2), p.discount) as info6, p.zile_inc as info5, rtrim(p.observatii) as info7,
	@tip as tip,(case when @tip in ('SA','EV') then 'PX' else ''end) as subtip--> -->pentru tipul 'SA','EV'->tab de tip pozdoc
from infotert p
	left join terti t on t.subunitate=@subunitate and t.tert=p.tert
	left join judete j on j.cod_judet = dbo.fstrToken(p.Adresa2, 1, ',')
	left join Localitati l on l.cod_oras = dbo.fStrToken(p.Adresa2, 2, ',')
	left join infotert pl on pl.subunitate=@subunitate and pl.tert=p.tert and pl.identificator=p.cont_in_banca2
where p.subunitate='C'+@subunitate 
	and ((@tert='' and @tip not in ('SA','EV')) or p.tert=@tert) -->pentru tipul 'SA','EV'->tab de tip pozdoc, daca tert='' sa nu aduca nici o persoana
	and p.identificator<>''
	and (@cautare='' 
		or p.pers_contact like '%' + @cautare + '%' 
		or p.nume_delegat like '%' + @cautare + '%' 
		or p.descriere like '%' + @cautare + '%' 
		or p.mijloc_tp like '%' + @cautare + '%' 
		or p.adresa2 like '%' + @cautare + '%')
	and ((isnull(t.denumire, '') like '%' + @fltDenTert + '%') or @tip in ('SA','EV'))--pentru tipul 'SA','EV'->tab de tip pozdoc, nu trebuie filtrat dupa denumire
	and ((p.descriere like '%' + @fltDescriere + '%') or @tip not in ('SA','EV'))--pentru tipul 'SA','EV'-> tab de tip pozdoc, nu trebuie filtrat nici dupa descriere
order by p.tert, p.pers_contact, p.nume_delegat
for xml raw

end
/*
populare 1: ca submacheta de detaliere, chemata dinspre terti; nume tip/subtip ajunge sa fie completata pe o pozitie, ca apoi merge cu max()
#start populare
infotert
C, CG, T, 1
Terti (pers. de contact)
Terti (persoane de contact)

('PC','',3,'Identificator','','@identificator','',0,'','','','char',5,'C','C','','','','',0,'','','',1,0,1,'Persoane contact',1,1),
('PC','',4,'Descriere','','@descriere','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',1,1),
('PC','',24,'Info3','','@info3','',0,'','','','char',9,'C','C','','','','',0,'','','',1,0,1,'',1,1),
('PC','',5,'Nume','','@nume','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',1,1),
('PC','',6,'Prenume','','@prenume','',0,'','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',1,1),
('PC','',9,'Serie buletine','','@seriebuletin','',0,'','','','char',12,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',10,'Numar buletin','','@numarbuletin','',0,'','','','char',12,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',11,'Eliberat','','@eliberatbuletin','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',8,'Functie','','@functie','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',1,1),
('PC','',12,'Judet','','@judet','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',13,'Localitate','','@localitate','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',20,'Telefon','','@telefon','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',1,1),
('PC','',21,'E-mail','','@email','',0,'','','','char',50,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',15,'Strada','','@strada','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',22,'Info 1','','@info1','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',1,1),
('PC','',16,'Numar','','@numar','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',17,'Bloc','','@bloc','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',18,'Scara','','@scara','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',19,'Apartament','','@apartament','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',23,'Info 2','','@info2','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',1,1),
('PC','',25,'Info 4','','@info4','',0,'','','','bit',1,'N','CHB','','','','',0,'','','',1,0,1,'',1,1),
('PC','',14,'Cod postal','','@codpostal','',0,'','','','char',13,'C','C','','','','',0,'','','',1,1,1,'',1,1),
('PC','',7,'Data nasterii','','@datanasterii','',0,'','','','datetime',1,'D','D','','','','',0,'','','',1,1,1,'',1,1),
('PC','',26,'Info 6','','@info6','',0,'','','','decimal',7,'N','N','','','','',0,'','','',1,0,1,'',1,1),
('PC','',27,'Info 5','','@info5','',0,'','','','int',1,'N','N','','','','',0,'','','',1,0,1,'',1,1),
('PC','',28,'Info 7','','@info7','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,1,'',1,1)
#sfarsit populare
populare 2: ca macheta catalog "stand-alone"; tertul are vizibilitate 'false' ca sa nu apara in form-ul de adaugare din macheta de detaliere
#start populare
infotert
C, CG, PC
Persoane de contact
Persoane de contact
('','',1,'Tert','','@tert','',0,'','','','varchar',13,'C','C','','','','',1,'','','',0,0,0,'',0,1),
('','',2,'Denumire tert','','@dentert','',0,'','','','varchar',80,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Nume prenume','','@descriere','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1)

('','',1,'Tert','','@tert','@dentert',0,'','','','char',13,'C','AC','wTerti','','','',0,'','','',1,0,1,'',0,1),
('','',2,'Denumire tert','','@dentert','',0,'','','','char',80,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Identificator','','@identificator','',0,'','','','char',5,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',4,'Descriere','','@descriere','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',24,'Info3','','@info3','',0,'','','','char',9,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',5,'Nume','','@nume','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',6,'Prenume','','@prenume','',0,'','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',9,'Serie buletine','','@seriebuletin','',0,'','','','char',12,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',10,'Numar buletin','','@numarbuletin','',0,'','','','char',12,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',11,'Eliberat','','@eliberatbuletin','',0,'','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',8,'Functie','','@functie','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',12,'Judet','','@judet','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',13,'Localitate','','@localitate','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',20,'Telefon','','@telefon','',0,'','','','char',20,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',21,'E-mail','','@email','',0,'','','','char',50,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',15,'Strada','','@strada','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',22,'Info 1','','@info1','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',16,'Numar','','@numar','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',17,'Bloc','','@bloc','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',18,'Scara','','@scara','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',19,'Apartament','','@apartament','',0,'','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',23,'Info 2','','@info2','',0,'','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',25,'Info 4','','@info4','',0,'','','','bit',1,'N','CHB','','','','',0,'','','',1,0,1,'',0,1),
('','',14,'Cod postal','','@codpostal','',0,'','','','char',13,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',7,'Data nasterii','','@datanasterii','',0,'','','','datetime',1,'D','D','','','','',0,'','','',1,1,1,'',0,1),
('','',26,'Info 6','','@info6','',0,'','','','decimal',7,'N','N','','','','',0,'','','',1,0,1,'',0,1),
('','',27,'Info 5','','@info5','',0,'','','','int',1,'N','N','','','','',0,'','','',1,0,1,'',0,1),
('','',28,'Info 7','','@info7','',0,'','','','char',30,'C','C','','','','',0,'','','',1,0,1,'',0,1)
#sfarsit populare
*/
