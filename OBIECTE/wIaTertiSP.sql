
drop procedure [wIaTertiSP]
--***
CREATE procedure [wIaTertiSP] @sesiune varchar(50), @parXML xml
as
--if exists(select * from sysobjects where name='wIaTertiSP' and type='P')
--	exec wIaTertiSP @sesiune, @parXML 
--else 
--begin
set transaction isolation level READ UNCOMMITTED
Declare @fltTert varchar(13), @fltDenumire varchar(80), @fltCodFiscal varchar(16), 
@fltGrupa varchar(3), @fltDenGrupa varchar(30), @fltJudet varchar(20), @fltDenJudet varchar(30), 
@fltTara varchar(20), @fltDenTara varchar(30), @fltLocalitate varchar(35), @fltDenLocalitate varchar(30), 
@fltTipTert int

select @fltTert = isnull(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
	@fltDenumire = isnull(@parXML.value('(/row/@dentert)[1]', 'varchar(80)'), ''),
	@fltCodFiscal = isnull(@parXML.value('(/row/@codfiscal)[1]', 'varchar(16)'), ''),
	@fltGrupa = isnull(@parXML.value('(/row/@grupa)[1]', 'varchar(3)'), ''),
	@fltDenGrupa = isnull(@parXML.value('(/row/@dengrupa)[1]', 'varchar(30)'), ''),
	@fltJudet = isnull(@parXML.value('(/row/@judet)[1]', 'varchar(20)'), ''),
	@fltDenJudet = isnull(@parXML.value('(/row/@denjudet)[1]', 'varchar(30)'), ''),
	@fltTara = isnull(@parXML.value('(/row/@tara)[1]', 'varchar(20)'), ''),
	@fltDenTara = isnull(@parXML.value('(/row/@dentara)[1]', 'varchar(30)'), ''),
	@fltLocalitate = isnull(@parXML.value('(/row/@localitate)[1]', 'varchar(35)'), ''),
	@fltDenLocalitate = isnull(@parXML.value('(/row/@denlocalitate)[1]', 'varchar(30)'), ''),
	@fltTipTert = @parXML.value('(/row/@tiptert)[1]', 'int')

declare @subunitate varchar(9), @AdrComp int
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
exec luare_date_par 'GE', 'ADRCOMP', @AdrComp output, 0, ''

select @fltDenumire=replace(@fltDenumire, ' ', '%'), 
	@fltDenGrupa=replace(@fltDenGrupa, ' ', '%'), 
	@fltJudet=replace(@fltJudet, ' ', '%'), 
	@fltDenJudet=replace(@fltDenJudet, ' ', '%'), 
	@fltTara=replace(@fltTara, ' ', '%'), 
	@fltDenTara=replace(@fltDenTara, ' ', '%'), 
	@fltLocalitate=replace(@fltLocalitate, ' ', '%'), 
	@fltDenLocalitate=replace(@fltDenLocalitate, ' ', '%')

select top 100 rtrim(t.tert) as tert
into #terti100
from terti t   
left join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=t.judet
left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=t.judet
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join gterti g on t.grupa=g.grupa
where t.subunitate=@subunitate and t.tert like @fltTert+'%' 
and t.denumire like '%'+@fltDenumire+'%'
and t.cod_fiscal like @fltCodFiscal+'%'
and t.grupa like @fltGrupa+'%'
and isnull(g.denumire, '') like '%'+@fltDenGrupa+'%' 
and (case when isnull(it.zile_inc, 0)=0 then t.judet else '' end) like '%'+@fltJudet+'%'
and isnull(j.denumire, t.judet) like '%'+@fltDenJudet+'%'
and (case when isnull(it.zile_inc, 0)>0 then t.judet else '' end) like '%'+@fltTara+'%'
and isnull(tari.denumire, '') like '%'+@fltDenTara+'%'
and t.localitate like '%'+@fltLocalitate+'%'
and isnull(l.oras, t.localitate) like '%'+@fltDenLocalitate+'%'
and (@fltTipTert is null or isnull(it.zile_inc, 0) = @fltTipTert)

select t1.tert, sum(sold) as sold into #ff from facturi,#terti100 t1 
where t1.tert=facturi.tert and subunitate=@subunitate and tip=0x54 group by t1.tert
select t1.tert, sum(sold) as sold into #fb from facturi,#terti100 t1 
where t1.tert=facturi.tert and subunitate=@subunitate and tip=0x46 group by t1.tert
   
select rtrim(t.tert) as tert, rtrim(t.denumire) as dentert, rtrim(t.cod_fiscal) as codfiscal, 
rtrim(t.localitate) as localitate, rtrim(isnull(l.oras, t.Localitate)) as denlocalitate, 
rtrim(case when isnull(it.zile_inc, 0)=0 then t.judet else '' end) as judet, rtrim(isnull(j.denumire, t.judet)) as denjudet, 
rtrim(case when isnull(it.zile_inc, 0)>0 then t.judet else '' end) as tara, rtrim(isnull(tari.denumire, '')) as dentara, 
rtrim(t.adresa) as adresa, 
rtrim(case when @AdrComp=1 then left(t.adresa, 30) else '' end) as strada,
rtrim(case when @AdrComp=1 then substring(t.adresa, 31, 8) else '' end) as numar,
rtrim(case when @AdrComp=1 then substring(t.adresa, 39, 6) else '' end) as bloc,
rtrim(case when @AdrComp=1 then substring(t.adresa, 45, 5) else '' end) as scara,
rtrim(case when @AdrComp=1 then substring(t.adresa, 50, 3) else '' end) as apartament,
rtrim(case when @AdrComp=1 then substring(t.adresa, 53, 8) else '' end) as codpostal,
rtrim(telefon_fax) as telefonfax, 
rtrim(t.banca) as banca, rtrim(isnull(b.denumire, '')) as denbanca, rtrim(t.cont_in_banca) as continbanca, 
convert(int, t.tert_extern) as decontarivaluta, rtrim(t.grupa) as grupa, rtrim(isnull(g.denumire, '')) as dengrupa, 
rtrim(t.cont_ca_furnizor) as contfurn, rtrim(isnull(cf.denumire_cont, '')) as dencontfurn, 
rtrim(t.cont_ca_beneficiar) as contben, rtrim(isnull(cb.denumire_cont, '')) as dencontben, 
convert(char(10), (case when t.sold_ca_furnizor<=693961 then '01/01/1901' when t.sold_ca_furnizor>1000000 then '12/31/2999' else dateadd(d, t.sold_ca_furnizor-693961, '01/01/1901') end), 101) as datatert,
convert(int, t.sold_ca_beneficiar) as categpret, rtrim(isnull(categpret.denumire, '')) as dencategpret,
convert(decimal(14, 2), t.sold_maxim_ca_beneficiar) as soldmaxben, convert(decimal(7, 2), t.disccount_acordat) as discount, 
convert(int, isnull(it.sold_ben, 0)) as termenlivrare, convert(int, isnull(it.discount, 0)) as termenscadenta, 
rtrim(isnull(it.nume_delegat, '')) as reprezentant, rtrim(isnull(it.eliberat, '')) as functiereprezentant, 
rtrim(isnull(it.loc_munca, '')) as lm, rtrim(isnull(lm.denumire, '')) as denlm,
rtrim(isnull(it.descriere, '')) as responsabil, rtrim(isnull(p.nume, '')) as denresponsabil,
rtrim(isnull(it.cont_in_banca2, '')) as info1, rtrim(isnull(it.cont_in_banca3, '')) as info2, rtrim(isnull(it.observatii, '')) as info3, 
rtrim(isnull(it.banca3, '')) as nrordreg, isnull(it.zile_inc, 0) as tiptert,
(case when isnull(it.grupa13, '')='1' then 1 else 0 end) as neplatitortva,
isnull(it.indicator, 0) as nomspec,
convert(decimal(13, 2), isnull(ff.sold, 0)) as soldfurn, convert(decimal(13, 2), isnull(fb.sold, 0)) as soldben, 
(case when isnull(ff.sold, 0)=0 and isnull(fb.sold, 0)=0 then '#808080' -- fara sold
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='42' and cod=t.Tert) then'#0000FF' 
	when exists(select 1 from proprietati where Cod_proprietate='CI8' and tip='TERT' and valoare='43' and cod=t.Tert) then'#FF0000' 
	else '#000000' end)  as culoare,
rtrim(isnull((select top 1 pr.valoare from proprietati pr where pr.Tip='TERT' and pr.Cod_proprietate='SUBCONTRACTANT' and pr.Cod=t.Tert),'')) as subcontractant
from terti t   
inner join #terti100 t1 on t.Tert=t1.tert
left join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
left join judete j on isnull(it.zile_inc, 0)=0 and j.cod_judet=t.judet
left join tari on isnull(it.zile_inc, 0)>0 and tari.cod_tara=t.judet
left join localitati l on l.cod_judet=t.judet and l.cod_oras=t.localitate
left join bancibnr b on b.cod=t.banca
left join gterti g on t.grupa=g.grupa
left join conturi cf on cf.subunitate=t.subunitate and cf.cont=t.cont_ca_furnizor
left join conturi cb on cb.subunitate=t.subunitate and cb.cont=t.cont_ca_beneficiar
left join categpret on categpret.categorie=t.sold_ca_beneficiar
left join lm on lm.cod=it.loc_munca
left join personal p on p.marca=it.descriere
left join #ff ff on ff.tert=t.tert
left join #fb fb on fb.tert=t.tert
where t.subunitate=@subunitate 
order by t.tert
for xml raw

drop table #fb
drop table #ff
drop table #terti100
--end

/*
#start populare
Terti
C, CG, T
Terti
Terti
('','',1,'Tert','','@tert','',0,'','','','varchar',13,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',2,'Denumire','','@dentert','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',3,'Cod fiscal','','@codfiscal','',0,'','','','varchar',16,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',4,'Grupa','','@grupa','',0,'','','','varchar',3,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',5,'Denumire grupa','','@dengrupa','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',6,'Judet','','@judet','',0,'','','','varchar',20,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',7,'Denumire judet','','@denjudet','',0,'','','','varchar',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',8,'Tara','','@tara','',0,'','','','varchar',20,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',9,'Denumire tara','','@dentara','',0,'','','','varchar',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',10,'Localitate','','@localitate','',0,'','','','varchar',35,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',11,'Denumire localitate','','@denlocalitate','',0,'','','','varchar',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',12,'Tip tert','','@tiptert','',0,'','','','int',1,'C','C','','','','',0,'','','',1,0,0,'',0,1)

('','',1,'Tert','','@tert','','','','','','char',13,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',2,'Denumire','','@denumire','@dentert','','','','','char',30,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',6,'Cod fiscal','','@codfiscal','','','','','','char',16,'C','C','','','','',1,'','','',1,1,1,'',0,1),
('','',11,'Localitate','','@localitate','@denlocalitate','','','','','char',35,'C','AC','wLocalitati','','','',0,'','','',1,1,1,'',0,1),
('','',12,'Denumire localitate','','@denlocalitate','','','','','','char',30,'C','C','','','','',1,'','','',1,0,0,'',0,1),
('','',7,'Judet','','@judet','@denjudet','','','','','char',20,'C','AC','wJudete','','','',0,'','','',1,1,1,'',0,1),
('','',8,'Denumire judet','','@denjudet','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',9,'Tara','','@tara','@dentara','','','','','char',20,'C','AC','wTari','','','',0,'','','',1,1,1,'',0,1),
('','',10,'Denumire tara','','@dentara','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',14,'Adresa','','@adresa','','','','','','char',60,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',15,'Strada','','@strada','','','','','','char',30,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',16,'Numar','','@numar','','','','','','char',8,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',17,'Bloc','','@bloc','','','','','','char',6,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',18,'Scara','','@scara','','','','','','char',5,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',19,'Apartament','','@apartament','','','','','','char',3,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',20,'Cod postal','','@codpostal','','','','','','char',8,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',21,'Telefon/fax','','@telefonfax','','','','','','char',20,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',22,'Banca','','@banca','@denbanca','','','','','char',20,'C','AC','wBanci','','','',0,'','','',1,1,1,'',0,1),
('','',23,'Denumire banca','','@denbanca','','','','','','char',50,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',24,'Cont in banca','','@continbanca','','','','','','char',35,'C','C','','','','',0,'','','',1,1,1,'',0,1),
('','',4,'Decontari in valuta','','@decontarivaluta','','','','','','bit',1,'N','CHB','','','','',0,'','','',1,1,1,'',0,1),
('','',25,'Grupa','','@grupa','@dengrupa','','','','','char',3,'C','AC','wGterti','','','',0,'','','',1,1,1,'',0,1),
('','',26,'Denumire grupa','','@dengrupa','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',42,'Cont ca furnizor','','@contfurn','@dencontfurn','','','','','char',13,'C','AC','wConturi','','','',0,'','','',1,0,1,'',0,1),
('','',43,'Denumire cont furnizor','','@dencontfurn','','','','','','char',80,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',44,'Cont ca beneficiar','','@contben','@dencontben','','','','','char',13,'C','AC','wConturi','','','',0,'','','',1,0,1,'',0,1),
('','',45,'Denumire cont beneficiar','','@dencontben','','','','','','char',80,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',29,'Data tert','','@datatert','','','','','','datetime',1,'D','D','','','','',0,'','','',1,0,1,'',0,1),
('','',46,'Categorie de pret','','@categpret','@dencategpret','','','','','int',1,'C','AC','wCategPret','','','',0,'','','',1,1,1,'',0,1),
('','',47,'Denumire categ. pret','','@dencategpret','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',28,'Sold maxim beneficiar','','@soldmaxben','','','','','','decimal',14,'N','N','','','','',0,'','','',1,0,1,'',0,1),
('','',27,'Discount','','@discount','','','','','','decimal',7,'N','N','','','','',0,'','','',1,1,1,'',0,1),
('','',30,'Termen livrare','','@termenlivrare','','','','','','int',1,'N','N','','','','',0,'','','',1,0,1,'',0,1),
('','',31,'Termen scadenta','','@termenscadenta','','','','','','int',1,'N','N','','','','',0,'','','',1,1,1,'',0,1),
('','',32,'Reprezentant','','@reprezentant','','','','','','char',30,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',33,'Functie reprezentant','','@functiereprezentant','','','','','','char',30,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',34,'Loc de munca','','@lm','@denlm','','','','','char',9,'C','AC','wLocm','','','',0,'','','',1,1,1,'',0,1),
('','',35,'Denumire loc de munca','','@denlm','','','','','','char',30,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',36,'Responsabil','','@responsabil','@denresponsabil','','','','','char',30,'C','AC','wSalariati','','','',0,'','','',1,0,1,'',0,1),
('','',37,'Nume responsabil','','@denresponsabil','','','','','','char',50,'C','C','','','','',0,'','','',1,0,0,'',0,1),
('','',38,'Info 1','','@info1','','','','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',39,'Info 2','','@info2','','','','','','char',35,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',40,'Info 3','','@info3','','','','','','char',30,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',41,'Nr. ord. reg.','','@nrordreg','','','','','','char',20,'C','C','','','','',0,'','','',1,0,1,'',0,1),
('','',3,'Tip tert','','@tiptert','','','','','','int',1,'N','CB','','0,1,2','Intern,UE,Extern','',0,'','','',1,1,1,'',0,1),
('','',5,'Neplatitor TVA','','@neplatitortva','','','','','','int',1,'N','CHB','','','','',0,'','','',1,1,1,'',0,1),
('','',13,'Nomenclator special','','@nomspec','','','','','','int',1,'N','CHB','','','','',0,'','','',1,0,1,'',0,1),
('','',48,'Sold ca furnizor','','@soldfurn','','','','','','decimal',13,'N','N','','','','',1,'','','',1,0,0,'',0,1),
('','',49,'Sold ca beneficiar','','@soldben','','','','','','decimal',13,'N','N','','','','',1,'','','',1,0,0,'',0,1)
#sfarsit populare
*/

GO

