
create procedure contTVAPozDocument @sesiune varchar(50), @parXML xml
as 
/*
Procedura va stabili contul de TVA pentru fiecare pozitie de document pe un set de date populat anterior apelarii procedurii. 
Tabela populata va trebui sa aiba campurile tabela, idPozitieDoc, tert, factura, cont_tva
Exemplu de apel:
	exec contTVAPozDocument @sesiune='', @parXML=null
*/
Begin try
	SET NOCOUNT ON
	declare 
		@cSub varchar(20),@CtTvaNeexPlati varchar(40),@CtTvaNeexIncasari varchar(40),@CtTvaCol varchar(40),@CtTvaDed varchar(40),@CtTvaNeexDocAvans varchar(40),@CtDocFaraFact varchar(200),
		@datajos datetime, @datasus datetime, @FurnBenef char(1),
		@dinpfacturi bit	--> "dinpfacturi" pentru a se evita apelul recursiv al pFacturi - genereaza eroare datorita tabelelor temporare folosite

	select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
	set @CtTvaNeexPlati= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIFURN'),''),'4428')
	set @CtTvaNeexIncasari= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNTLIBEN'),''),'4428')
	set @CtTvaCol= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CCTVA'),''),'4427')
	set @CtTvaDed= isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CDTVA'),''),'4426')
	select @CtTvaNeexDocAvans=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CNEEXREC'
	set @CtDocFaraFact=isnull(nullif((select top 1 RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='NEEXDOCFF'),''),'408,418')
	select @CtTvaNeexDocAvans=isnull(nullif(@CtTvaNeexDocAvans,''),'4428')

	set @datajos=@parXML.value('(/row/@datajos)[1]','datetime') 
	set @datasus=@parXML.value('(/row/@datasus)[1]','datetime') 
	set @FurnBenef=@parXML.value('(/row/@furnbenef)[1]','char(1)') 
	set @dinpfacturi=@parXML.value('(/row/@dinpfacturi)[1]','bit') 

	if OBJECT_ID('tempdb..#ctdocfarafact') is not null drop table #ctdocfarafact
	if OBJECT_ID('tempdb..#facturi_cu_TLI') is not null drop table #facturi_cu_TLI

--	Punem in tabela temporara conturile pentru documente fara factura pentru a putea functiona legatura pe aceste conturi like.
	select c.cont into #ctdocfarafact
	from dbo.fSplit(@CtDocFaraFact,',') ff
		left outer join conturi c on c.subunitate=@cSub and c.cont like rtrim(ff.string)+'%'

--Lucian: utilizam procedura tipTVAFacturi (in locul selectului de mai sus) care stabileste tipul de TVA al facturii. In raport de tipul de TVA vom completa contul de TVA.
	select 
		'' as tip,ft.tipf tipf,ft.tert,ft.factura,convert(datetime,null) as data, convert(varchar(40),null) as cont,'' as tip_tva
	into #facturi_cu_TLI
	from #contTVAPozitieDoc ft
	group by tipf,tert,Factura
	declare @p xml
	select @p=(select @dinpfacturi as dinpfacturi for xml raw)
	exec tipTVAFacturi @dataJos=@dataJos, @dataSus=@dataSus, @TLI=null, @parXML=@p

	update ctva set ctva.tip_tva=isnull(f.tip_tva,'')
	from #contTVAPozitieDoc ctva
		left outer join #facturi_cu_TLI f on ctva.tipf=f.tipf and ctva.tert=f.tert and ctva.factura=f.factura

--	RM, RS, AP, AS, FF, SF, FB, IF
	update ctva 
		set ctva.contTVA=isnull(nullif(pd.detalii.value('/row[1]/@cont_tva','varchar(50)'),''),(case when cdff.cont is not null then @CtTvaNeexDocAvans 
			when ctva.tipf='B' then (case when ctva.tip_tva='I' and pd.cota_tva>0 then @CtTvaNeexIncasari else @CtTvaCol end)
			else (case when ctva.tip_tva='I' and pd.procent_vama=0 and pd.cota_tva>0 then @CtTvaNeexPlati else @CtTvaDed end) end))
	from #contTVAPozitieDoc ctva
		inner join pozdoc pd on ctva.tabela='pozdoc' and pd.idpozdoc=ctva.idPozitieDoc
		left outer join #ctdocfarafact cdff on cdff.cont=pd.cont_factura

	update ctva 
		set ctva.contTVA=(case when pd.tip='FF' and cdff.cont is not null or pd.tip='FB' and cdfb.cont is not null then @CtTvaNeexDocAvans 
			when ctva.tipf='B' then (case when ctva.tip_tva='I' and pd.TVA11>0 then @CtTvaNeexIncasari else @CtTvaCol end)
			else (case when ctva.tip_tva='I' and pd.stare=0 and pd.TVA11>0 then @CtTvaNeexPlati else @CtTvaDed end) end)
	from #contTVAPozitieDoc ctva
		inner join pozadoc pd on ctva.tabela='pozadoc' and pd.idpozadoc=ctva.idPozitieDoc
			and not(pd.tip='IF' and pd.Valuta<>'') and not(pd.tip='SF' and pd.Valuta<>'') 
		left outer join #ctdocfarafact cdff on pd.tip='FF' and cdff.cont=pd.cont_cred
		left outer join #ctdocfarafact cdfb on pd.tip='FB' and cdfb.cont=pd.cont_deb
end try

begin catch
	declare @mesaj varchar(2000)
	set @mesaj = ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 11, 1)
end catch
