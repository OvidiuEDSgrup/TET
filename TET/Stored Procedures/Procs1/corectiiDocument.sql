
create procedure corectiiDocument @Subunitate varchar(9)=null, @Tip varchar(2)=null, @Numar varchar(20)=null, @Data datetime=null, @datalunii datetime=null
as 
/*
Apelata din prg. 25 din CGplus
Exemplu de apel:
	exec corectiiDocument @subunitate='1', @Tip='AP', @Numar='125443', @Data='2013-07-02'
*/
SET NOCOUNT ON
declare @cSub varchar(20), @bugetari int, @CtTvaDed varchar(40), @StocLot int
select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
select @bugetari=val_logica from par where Tip_parametru='GE' and Parametru='BUGETARI'
select @StocLot=val_logica from par where Tip_parametru='GE' and Parametru='STOCLOT'

--Pe baza parametrului DATA se contruiesc datajos si datasus cu BOM si EOM pentru filtrare mai departe(exemplu in PozDoc la cautare RP)
declare @dataJos datetime, @dataSus datetime
if @data is null
	select @datajos=dbo.BOM(@datalunii), @datasus=dbo.EOM(@datalunii)
else 
	select @datajos=@data, @datasus=@data
-- completare idIntrare / idIntrareFirma 
update pozdoc set 
	idIntrare=(case when Tip_miscare='E' and tip not in ('TE','DF','PI') then s.idIntrare else pozdoc.idIntrare end), 
	idIntrareFirma=s.idIntrareFirma
from stocuri s 
where pozdoc.tip in ('CM','TE','AP','AC','AE','AI','DF','PF','CI') and pozdoc.tip_miscare in ('I','E')
	and pozdoc.subunitate=@csub and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and pozdoc.data between @datajos and @datasus
	and s.subunitate=pozdoc.Subunitate and s.Cod_gestiune=pozdoc.Gestiune and s.cod=pozdoc.cod and s.cod_intrare=pozdoc.cod_intrare

-- completare cont TVA exceptie pentru bugetari in pozdoc.detalii.cont_tva daca s-a completat cont TVA in doc.gestiune_primitoare.
if @bugetari=1 and @Tip in ('RM','RS')
Begin
	select @CtTvaDed=RTRIM(Val_alfanumerica) from par where Tip_parametru='GE' and Parametru='CDTVA'

	update pozdoc set pozdoc.detalii='<row />'
	from doc 
	where pozdoc.subunitate=@csub and pozdoc.Tip=@Tip and pozdoc.Numar=@Numar and pozdoc.data between @datajos and @datasus
		and doc.subunitate=pozdoc.Subunitate and doc.Tip=pozdoc.Tip and doc.Numar=pozdoc.Numar and doc.Data=pozdoc.Data
		and doc.gestiune_primitoare not in ('',@CtTvaDed) and pozdoc.detalii is null 

	update pozdoc set detalii.modify('insert attribute cont_tva {sql:column("doc.gestiune_primitoare")} into (/row)[1]') 
	from doc 
	where pozdoc.subunitate=@csub and pozdoc.Tip=@Tip and pozdoc.Numar=@Numar and pozdoc.data between @datajos and @datasus
		and doc.subunitate=pozdoc.Subunitate and doc.Tip=pozdoc.Tip and doc.Numar=pozdoc.Numar and doc.Data=pozdoc.Data
		and doc.gestiune_primitoare not in ('',@CtTvaDed) and pozdoc.detalii.value('(/row/@cont_tva)[1]','varchar(40)') is null 

	update pozdoc set detalii.modify('replace value of (/row/@cont_tva)[1] with sql:column("doc.gestiune_primitoare")') 
	from doc 
	where pozdoc.subunitate=@csub and pozdoc.Tip=@Tip and pozdoc.Numar=@Numar and pozdoc.data between @datajos and @datasus
		and doc.subunitate=pozdoc.Subunitate and doc.Tip=pozdoc.Tip and doc.Numar=pozdoc.Numar and doc.Data=pozdoc.Data
		and doc.gestiune_primitoare not in ('',@CtTvaDed) and pozdoc.detalii.value('(/row/@cont_tva)[1]','varchar(40)')=''
End

-- calcul si completare diferenta de curs si cont diferenta de curs la Stornare avans in pozdoc.detalii. 
if @Tip in ('RM','RS','AP','AS') 
	and exists (select 1 from pozdoc p where p.subunitate=@csub and p.Tip=@Tip and p.Numar=@Numar and p.data between @datajos and @datasus 
				and p.valuta!='' and p.cantitate<0 and p.tip_miscare='V') 
Begin
	if object_id('tempdb..#documente') is not null drop table #documente
	select p.* into #documente
	from pozdoc p 
		left outer join conturi c on c.subunitate=@cSub and c.cont=p.cont_de_stoc
	where p.subunitate=@csub and (@tip is null or p.Tip=@Tip) and (@numar is null or p.Numar=@Numar) and p.data between @datajos and @datasus 
		and p.valuta!='' and p.cantitate<0 and p.tip_miscare='V'
		and (p.tip in ('RM','RS') and c.Sold_credit=1 or p.tip in ('AP','AS') and c.Sold_credit=2)

	alter table #documente add val_valuta_storno float, cont_dif_av varchar(40), dif_curs_av float

	exec pDifCursStornareAvans @sesiune=null, @parXML=null

	update p set p.detalii=d.detalii
	from pozdoc p
	inner join #documente d on d.idPozdoc=p.idPozdoc
End

	
-- preluare lot la intrari 
if @StocLot=1
	update pozdoc 
		set lot=(case when tip='RM' then cont_corespondent when tip in ('PP','AI') then grupa end)
		where subunitate=@csub and tip in ('RM','PP','AI') and isnull(lot,'')='' and isnull((case when tip='RM' then cont_corespondent when tip in ('PP','AI') then grupa end),'')<>''
			and subunitate=@csub and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus

-- procedura specifica
if exists (select * from sysobjects where name ='corectiiDocumentSP')
	exec corectiiDocumentSP @Subunitate, @Tip, @Numar, @Data, @datalunii 