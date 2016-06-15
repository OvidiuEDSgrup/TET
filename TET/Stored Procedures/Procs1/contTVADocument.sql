
create procedure contTVADocument @Subunitate varchar(9)=null, @Tip varchar(2)=null, @Numar varchar(20)=null, @Data datetime=null, @datalunii datetime=null
as 
/*
Exemplu de apel:
	exec contTVADocument @subunitate='1', @Tip='AP', @Numar='125443', @Data='2013-07-02'
*/
SET NOCOUNT ON
declare 
	@cSub varchar(20),@CtTvaNeexPlati varchar(20),@CtTvaNeexIncasari varchar(20),@dataTLI datetime, @CtTvaCol varchar(20),@CtTvaDed varchar(20)
select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
--Pe baza parametrului DATA se contruiesc datajos si datasus cu BOM si EOM pentru filtrare mai departe(exemplu in PozDoc la cautare RP)
declare @dataJos datetime, @dataSus datetime
if @data is null
	select @datajos=dbo.BOM(@datalunii), @datasus=dbo.EOM(@datalunii)
else 
	select @datajos=@data, @datasus=@data
-- completare cont de TVA pe facturi TLI sau non-TLI
/*
select @CtTvaNeexPlati=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIFURN'
select @CtTvaNeexIncasari=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CNTLIBEN'
select @CtTvaCol=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CCTVA'
select @CtTvaDed=Val_alfanumerica from par where Tip_parametru='GE' and Parametru='CDTVA'

if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
if object_id ('tempdb..#facturi_parcurse') is not null drop table #facturi_parcurse

-- Selectam documentele vizate - se exclud unele conturi (avize, leasing)!!!!!!!!!!!!!!!!
create table #facturi_parcurse(tip varchar(2), tert varchar(20),factura varchar(20),suma float,baza float)
if @tip is null or @tip in ('RM','RS')
insert into #facturi_parcurse
select tip, tert,factura,sum(tva_deductibil) as suma,sum(Cantitate*Pret_valuta) as baza
	from pozdoc 
	where subunitate=@csub and tip in ('RM','RS') and data>'2012-12-31' and left(Cont_factura,3) not in ('408','167') 
		and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus
	group by tip,tert,factura

if @tip is null or @tip in ('FF','SF') 
insert into #facturi_parcurse
select tip, tert,Factura_dreapta,sum(tva22) as suma,sum(Suma) as baza
	from pozadoc 
	where subunitate=@csub and tip in ('FF','SF') and data>'2012-12-31' and left(Cont_cred,3) not in ('408','167') 
		and (@tip is null or Tip=@Tip) and (@numar is null or Numar_document=@Numar) and data between @datajos and @datasus
	group by tip,tert,Factura_dreapta

if @tip is null or @tip in ('AP','AS') 
insert into #facturi_parcurse
select tip, tert,factura,sum(tva_deductibil) as suma,sum(Cantitate*Pret_vanzare) as baza
	from pozdoc 
	where subunitate=@csub and tip in ('AP','AS') and data>'2012-12-31' and Cont_factura not like '418%' 
		and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus
	group by tip,tert,factura

if @tip is null or @tip in ('FB','IF') 
insert into #facturi_parcurse
select tip, tert,factura_stinga,sum(tva22) as suma,sum(Suma) as baza
	from pozadoc 
	where subunitate=@csub and tip in ('FB','IF') and data>'2012-12-31' and Cont_deb not like '418%' 
		and (@tip is null or Tip=@Tip) and (@numar is null or Numar_document=@Numar) and data between @datajos and @datasus
	group by tip,tert,factura_stinga

/* Identific tipul facturilor utilizand procedura tipTVAFacturi (in locul selectului de mai sus) pt. a putea apela procedura si din alte locuri */
select f.tip,(case when fct.tip=0x54 then 'F' else 'B' end) as tipf,f.tert,f.factura,'' as tip_tva
into #facturi_cu_TLI
from #facturi_parcurse f
inner join facturi fct on f.tert=fct.tert and f.factura=fct.factura and fct.tip=(case when f.tip in ('AP','AS','FB','IF') then 0x46 else 0x54 end)
exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus

-- completare cont de TVA 
declare @binar varbinary(128)
set @binar=cast('modificaredocdefinitiv' as varbinary(128))
set CONTEXT_INFO @binar -- pentru cazurile documentelor definitive, care au cont de TVA eronat

if @tip is null or @tip in ('AP','AS') 
update pozdoc set grupa=(case when tip_tva='I' and cota_tva>0 then @CtTvaNeexIncasari else @CtTvaCol end)
from #facturi_cu_TLI f 
where pozdoc.subunitate=@csub and pozdoc.tip in ('AP','AS') and data>'2012-12-31' and pozdoc.tip=f.tip and pozdoc.tert=f.tert and pozdoc.factura=f.factura 
	and left(pozdoc.grupa,3) in ('442','   ') and pozdoc.grupa<>(case when tip_tva='I' and cota_tva>0 then @CtTvaNeexIncasari else @CtTvaCol end) and Jurnal<>'MFX' 
	and (@tip is null or pozdoc.Tip=@Tip) and (@numar is null or pozdoc.Numar=@Numar) and pozdoc.data between @datajos and @datasus

if @tip is null or @tip in ('RM','RS') 
-- la cumparari se pune cont de TVA deductibil si pentru cota TVA=0 sau TVA nedeductibil
update pozdoc set cont_venituri= (case when tip_tva='I' and procent_vama=0 and cota_tva>0 then @CtTvaNeexPlati else @CtTvaDed end)
from #facturi_cu_TLI f where pozdoc.subunitate=@csub and pozdoc.tip in ('RM','RS') and data>'2012-12-31' and pozdoc.tip=f.tip and pozdoc.tert=f.tert and pozdoc.factura=f.factura 
	and left(pozdoc.cont_venituri,3) in ('442','   ') and pozdoc.cont_venituri<>(case when tip_tva='I' and procent_vama=0 and cota_tva>0 then @CtTvaNeexPlati else @CtTvaDed end) and Jurnal<>'MFX' 
	and (@tip is null or pozdoc.Tip=@Tip) and (@numar is null or pozdoc.Numar=@Numar) and pozdoc.data between @datajos and @datasus

set @binar=cast('modificaredocdefinitivMF' as varbinary(128))
set CONTEXT_INFO @binar -- pentru cazurile documentelor operate in MF, care au cont de TVA eronat

if @tip is null or @tip in ('AP','AS') 
update pozdoc set grupa=(case when tip_tva='I' and cota_tva>0 then @CtTvaNeexIncasari else @CtTvaCol end)
from #facturi_cu_TLI f 
where pozdoc.subunitate=@csub and pozdoc.tip in ('AP','AS') and data>'2012-12-31' and pozdoc.tip=f.tip and pozdoc.tert=f.tert and pozdoc.factura=f.factura 
	and left(pozdoc.grupa,3) in ('442','   ') and pozdoc.grupa<>(case when tip_tva='I' and cota_tva>0 then @CtTvaNeexIncasari else @CtTvaCol end) and stare<>2  
	and (@tip is null or pozdoc.Tip=@Tip) and (@numar is null or pozdoc.Numar=@Numar) and pozdoc.data between @datajos and @datasus

if @tip is null or @tip in ('RM','RS') 
-- la cumparari se pune cont de TVA deductibil si pentru cota TVA=0 sau TVA nedeductibil
update pozdoc set cont_venituri= (case when tip_tva='I' and procent_vama=0 and cota_tva>0 then @CtTvaNeexPlati else @CtTvaDed end)
from #facturi_cu_TLI f where pozdoc.subunitate=@csub and pozdoc.tip in ('RM','RS') and data>'2012-12-31' and pozdoc.tip=f.tip and pozdoc.tert=f.tert and pozdoc.factura=f.factura 
	and left(pozdoc.cont_venituri,3) in ('442','   ') and pozdoc.cont_venituri<>(case when tip_tva='I' and procent_vama=0 and cota_tva>0 then @CtTvaNeexPlati else @CtTvaDed end) and stare<>2 
	and (@tip is null or pozdoc.Tip=@Tip) and (@numar is null or pozdoc.Numar=@Numar) and pozdoc.data between @datajos and @datasus

set CONTEXT_INFO 0x00

if @tip is null or @tip in ('FB','IF') 
update pozadoc set Tert_beneficiar=(case when tip_tva='I' and TVA11>0 then @CtTvaNeexIncasari else @CtTvaCol end)
from #facturi_cu_TLI f where pozadoc.subunitate=@csub and pozadoc.tip in ('FB','IF') and data>'2012-12-31' and pozadoc.tip=f.tip and pozadoc.tert=f.tert and pozadoc.Factura_stinga=f.factura 
	and left(pozadoc.Tert_beneficiar,3) in ('442','   ') and pozadoc.Tert_beneficiar<>(case when tip_tva='I' and TVA11>0 then @CtTvaNeexIncasari else @CtTvaCol end) 
	and not(pozadoc.tip='IF' and pozadoc.Valuta<>'') 
	and (@tip is null or pozadoc.Tip=@Tip) and (@numar is null or pozadoc.Numar_document=@Numar) and pozadoc.data between @datajos and @datasus

if @tip is null or @tip in ('FF','SF') 
update pozadoc set Tert_beneficiar=(case when tip_tva='I' and stare=0 and TVA11>0 then @CtTvaNeexPlati else @CtTvaDed  end)
from #facturi_cu_TLI f where pozadoc.subunitate=@csub and pozadoc.tip in ('FF','SF') and data>'2012-12-31' and pozadoc.tip=f.tip and pozadoc.tert=f.tert and pozadoc.Factura_dreapta=f.factura 
	and left(pozadoc.Tert_beneficiar,3) in ('442','   ') and pozadoc.Tert_beneficiar<>(case when tip_tva='I' and stare=0 and TVA11>0 then @CtTvaNeexPlati else @CtTvaDed  end)
	and not(pozadoc.tip='SF' and pozadoc.Valuta<>'') 
	and (@tip is null or pozadoc.Tip=@Tip) and (@numar is null or pozadoc.Numar_document=@Numar) and pozadoc.data between @datajos and @datasus

if object_id ('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI
if object_id ('tempdb..#facturi_parcurse') is not null drop table #facturi_parcurse
*/