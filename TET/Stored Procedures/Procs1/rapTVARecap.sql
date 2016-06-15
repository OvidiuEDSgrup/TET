--***
create procedure rapTVARecap (@parXML xml)
/*returns @rtva table
	(codtert char(13), tara char(20), codfisc char(20), dentert char(80), tipop char(1), baza float)*/

/* Testare:
		declare @parXML xml
		select @parXML=
			(select '2013-06-01' as DataJ,
			'2013-06-30' as DataS,
			1 as IncludRP,
			1 as IncludFF,
			'' as CtCorespFF,
			1 as IncludFB,
			'' as CtCorespFB,
			1 as IncludAS
		for xml raw)

		exec rapTVARecap @parXML
*/

as
begin
declare @ValidareTara int, @DataJ datetime,@DataS datetime, @IncludRP int, @IncludFF int, @CtCorespFF varchar(200), @IncludFB int, @CtCorespFB varchar(200), @IncludAS int

select @ValidareTara=max(case when parametru='TARATERTI' then Val_logica else 0 end)
from par 
where Parametru in ('TARATERTI')
select	@DataJ=@parXML.value('(/row/@DataJ)[1]','datetime'),
		@DataS=@parXML.value('(/row/@DataS)[1]','datetime'),
		@IncludRP=isnull(@parXML.value('(/row/@IncludRP)[1]','int'),0),	--> 0,1
		@IncludFF=isnull(@parXML.value('(/row/@IncludFF)[1]','int'),0),	--> 0,1
		@CtCorespFF=isnull(@parXML.value('(/row/@CtCorespFF)[1]','varchar(200)'),''),
		@IncludFB=isnull(@parXML.value('(/row/@IncludFB)[1]','int'),0),	-->0,1
		@CtCorespFB=isnull(@parXML.value('(/row/@CtCorespFB)[1]','varchar(200)'),''),
		@IncludAS=isnull(@parXML.value('(/row/@IncludAS)[1]','int'),0)	-->0,1

if (@DataJ is null or @DataS is null) return

if object_ID('tempdb..#tvarecap') is not null drop table #tvarecap

declare @ctcor table (tip char(2), cont char(13))

insert @ctcor
select 'FF', [Item]
from dbo.Split(@CtCorespFF, ',')
where @IncludFF=1 and @CtCorespFF<>''
union all
select 'FB', [Item]
from dbo.Split(@CtCorespFB, ',')
where @IncludFB=1 and @CtCorespFB<>''

declare @Fara44 int -- pt. Rematinvest
set @Fara44=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='FARA44'),0) 

--	pun datele in tabela temporara pentru a putea fi prelucrate daca este cazul prin procedura specifica (rapTVARecapSP)
select d.subunitate, d.tert, isnull(t.judet, '') as tara, 
isnull((case when left(t.cod_fiscal,2)=(case when @ValidareTara=1 then isnull(t.Judet,'') else isnull(tn.cod_tara,'') end) then SUBSTRING(t.cod_fiscal,3,14) else t.cod_fiscal end), '') as codfisc, 
isnull(t.denumire, '') as dentert,
(case when isnull(i.tip_miscare,'')='T' then 'T' when isnull(n.tip, '') in ('R', 'S', '') /*and left(d.cont_coresp,3)!='701'*/ and left(d.cont_coresp,3)!='419' 
	and not (d.tipD='IF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '')<>0) or left(d.cont_coresp, 3) in ('704') or d.tipD='FB' and @IncludFB=0 then 'P' else 'L' end) as tipop, 
round(convert(decimal(15,3), d.valoare_factura*(case when @DataJ<'01/01/2010' and d.tipD='IF' and d.factadoc<>'' 
	then dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') / dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 0, '') else 1 end)), 2) as baza, 
d.numar, d.numarD, d.tipD, d.data, d.factura, d.valoare_factura, d.baza_22, d.tva_22, d.explicatii, d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, d.drept_ded, d.cont_TVA, d.cont_coresp, 
d.exonerat, d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf
into #tvarecap
from dbo.docTVAVanz(@DataJ,@DataS,'',0,'','',0,'','',0,0,'','',0,'2',0,1,0,0,0,0,'','',0,0, '<row />') d
	left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert and d.TipD<>'FA'
	left outer join infotert it on it.subunitate=t.subunitate and it.tert=t.tert and it.identificator=''
	left outer join nomencl n on n.cod=d.cod
	left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
	left outer join tari on cod_tara=i.cont_intermediar
	left outer join tari tn on tn.denumire=t.judet
where isnull(it.zile_inc, 0)=1 and d.vanzcump='V' and (d.exonerat in (1, 2) or @Fara44=1 and d.exonerat=0)
	and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.Tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' --and isnull(it.grupa13, '')<>'1'
	and (isnull(n.tip, '') not in ('R', 'S', '') and left(d.cont_coresp, 3) not in ('704')
		or @IncludAS=1 and d.tipD='AS'
		or d.tipD in ('ME') 
		or d.tipD='IF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') <> 0
		or @IncludFB=1 and d.tipD='FB' 
			--and charindex(RTrim(d.cont_coresp), @CtCorespFB)>0
			and exists (select 1 from @ctcor cc where cc.tip=d.tipD and d.cont_coresp like RTrim(cc.cont)+'%')
		or @DataJ>='01/01/2010'
		)

union all

select d.subunitate, d.tert, isnull(t.judet, '') as tara, 
isnull((case when left(t.cod_fiscal,2)=(case when @ValidareTara=1 then isnull(t.Judet,'') else isnull(tn.cod_tara,'') end) then SUBSTRING(t.cod_fiscal,3,14) else t.cod_fiscal end), '') as codfisc, 
isnull(t.denumire, '') as dentert,
(case when isnull(n.tip, '') in ('R', 'S', '') and left(d.cont_coresp,3)!='409' and not (d.tipD='SF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '')<>0 
	or d.tipDoc='RP' and @IncludRP=1 or d.tipD='FF' and @IncludFF=1) or d.tipDoc='RP' and @IncludRP=0 or d.tipD='FF' and @IncludFF=0 then 'S' else 'A' end) as tipop, 
round(convert(decimal(15,3), d.valoare_factura*(case when @DataJ<'01/01/2010' and d.tipD='SF' and d.factadoc<>'' 
	then dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') / dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 0, '') else 1 end)), 2) as baza, 
d.numar, d.numarD, d.tipD, d.data, d.factura, d.valoare_factura, d.baza_22, d.tva_22, d.explicatii, d.tip, d.cota_tva, d.discFaraTVA, d.discTVA, d.data_doc, d.ordonare, d.drept_ded, d.cont_TVA, d.cont_coresp, 
d.exonerat, d.vanzcump, d.numar_pozitie, d.tipDoc, d.cod, d.factadoc, d.contf
from dbo.docTVACump(@DataJ,@DataS,'','','',0,'','',0,0,1,'2','2',0,1,0,0,0,'','',0,0,2,'<row />') d
	left outer join terti t on t.subunitate=d.subunitate and t.tert=d.tert
	left outer join infotert it on it.subunitate=d.subunitate and it.tert=d.tert and it.identificator=''
	left outer join nomencl n on n.cod=d.cod
	left outer join pozdoc i on i.subunitate='INTRASTAT' and i.tip=d.tipdoc and i.numar=d.numar and i.data=d.data_doc and i.numar_pozitie=0
	left outer join tari on cod_tara=i.cont_intermediar
	left outer join tari tn on tn.denumire=t.judet
where isnull(it.zile_inc, 0)=1 and d.vanzcump='C' and d.exonerat in (0, 1)
	and isnull((select top 1 tt.tip_tva from tvapeterti tt where tt.tert=d.Tert and tt.tipf='F' and tt.dela<=@DataS and isnull(tt.factura,'')='' order by tt.dela desc),'P')<>'N' --and isnull(it.grupa13, '')<>'1'
	and (isnull(n.tip, '') not in ('R', 'S', '') or d.tipD in ('MI', 'MM') or (@IncludRP = 1 and d.tipDoc='RP')
		or d.tipD='SF' and d.factadoc<>'' and dbo.valApRmAdoc(d.subunitate, d.tipD, d.tert, d.factadoc, null, 1, '') <> 0
		or @IncludFF=1 and d.tipD='FF' 
			--and charindex(RTrim(d.cont_coresp), @CtCorespFF)>0
			and exists (select 1 from @ctcor cc where cc.tip=d.tipD and d.cont_coresp like RTrim(cc.cont)+'%')
		or @DataJ>='01/01/2010'
		)

if exists (select * from sysobjects where name ='rapTVARecapSP' and xtype='P')
	exec rapTVARecapSP @parXML

--	grupare date din tabela temporara dupa tert si tip operatie
select d.tert, max(rtrim(case when len(d.tara)>2 then isnull(t.cod_tara,'') else d.tara end)) as tara, 
	max(d.codfisc) as codfisc, max(d.dentert) as dentert, d.tipop, convert(decimal(20),sum(d.baza)) as baza, row_number() over (order by max(d.dentert)) as ordine
from #tvarecap d
	left join tari t on rtrim(t.denumire)=rtrim(d.tara)
group by d.tert, d.tipop
having abs(sum(d.baza))>=0.01

--delete @rtva where abs(baza)<0.01

end
