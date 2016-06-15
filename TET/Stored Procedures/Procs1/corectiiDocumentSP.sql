
create procedure corectiiDocumentSP @Subunitate varchar(9)=null, @Tip varchar(2)=null, @Numar varchar(20)=null, @Data datetime=null, @datalunii datetime=null
as 
/*
Apelata din prg. 25 din CGplus
Exemplu de apel:
	exec corectiiDocumentSP @subunitate='1', @Tip='AP', @Numar='125443', @Data='2013-07-02'
*/
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON
	declare @cSub varchar(20), @bugetari int, @CtTvaDed varchar(40), @StocLot int
	select @cSub=val_alfanumerica from par where Tip_parametru='GE' and Parametru='SUBPRO'
	select @bugetari=val_logica from par where Tip_parametru='GE' and Parametru='BUGETARI'
	select @StocLot=val_logica from par where Tip_parametru='GE' and Parametru='STOCLOT'
	
	--Pe baza parametrului DATA se contruiesc datajos si datasus cu BOM si EOM pentru filtrare mai departe(exemplu in PozDoc la cautare RP)
	declare @dataJos datetime, @dataSus datetime
	if @data is not null
		select @datajos=@data, @datasus=@data
	else
		if @datalunii is not null
			select @datajos=dbo.BOM(@datalunii), @datasus=dbo.EOM(@datalunii)
		else 
			select top 1 @dataJos=dbo.eom(rtrim(anul)+'-'+rtrim(luna)+'-01')+1, 
				@dataSus=dbo.EOM(CURRENT_TIMESTAMP)
			from 
				(select anul=a.Val_numerica,luna=l.val_numerica, l.Denumire_parametru 
				from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
					and a.Parametru='ANULINC' where l.Tip_parametru='GE' and l.Parametru='LUNAINC'
				union 
				select a.Val_numerica,l.val_numerica, l.Denumire_parametru 
				from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
					and a.Parametru='ANULBLOC' where l.Tip_parametru='GE' and l.Parametru='LUNABLOC'
				union 
				select a.Val_numerica,l.val_numerica, l.Denumire_parametru 
				from par l inner join par a on a.Tip_parametru=l.Tip_parametru 
					and a.Parametru='ANULIMPL' where l.Tip_parametru='GE' and l.Parametru='LUNAIMPL') par
				where isdate(rtrim(anul)+'-'+rtrim(luna)+'-01')=1
			order by anul desc, luna desc

	alter table pozdoc disable trigger all

	/* completare idIntrare / idIntrareFirma
	select p.idIntrareFirma,s.idIntrareFirma,p.idpozdoc,@datajos,@datasus,*,
	--*/update p set 
	idIntrareFirma=nullif(s.idIntrareFirma,p.idpozdoc)
	from pozdoc p join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
	where p.tip in ('CM','TE','AP','AC','AE','AI','DF','PF','CI') and p.tip_miscare in ('I','E')
		and p.subunitate=@csub and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and p.data between @datajos and @datasus
		and NOT(p.Tip_miscare='I' and p.Cantitate>0 or p.Tip_miscare='E' and p.Cantitate<0)
		and nullif(s.idIntrareFirma,p.idpozdoc) is not null 
		and p.idIntrareFirma is null
		
	/*
	select p.idIntrare,s.idIntrare,p.idpozdoc,*, 
	--*/update p set 
	idintrare=nullif(s.idintrare,p.idpozdoc)
	from pozdoc p join stocuri s on s.Subunitate=p.Subunitate and s.Cod_gestiune=p.Gestiune and s.Cod=p.Cod and s.Cod_intrare=p.Cod_intrare
	where p.tip in ('CM','TE','AP','AC','AE','AI','DF','PF','CI') and p.tip_miscare in ('I','E')
		and p.subunitate=@csub and (@tip is null or Tip=@Tip) and (@numar is null or Numar=@Numar) and p.data between @datajos and @datasus
		and NOT(p.Tip_miscare='I' and p.Cantitate>0 or p.Tip_miscare='E' and p.Cantitate<0)
		and nullif(s.idIntrare,p.idpozdoc) is not null
		and p.idIntrare is null 
		
	-- preluare lot la intrari 
	if @StocLot=1
	begin
		update pozdoc 
		set cont_corespondent=(case when p.tip='RM' then cod_intrare else cont_corespondent end)
			,grupa=(case when p.tip in ('PP','AI') then cod_intrare else grupa end)
		from pozdoc p
			JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
		where subunitate=@csub and p.tip in ('RM','PP','AI') 
			and isnull(cod_intrare,'')<>'' 
			and isnull((case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end),'')=''
			and (@tip is null or p.Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus
	/*
	select *, 
	--*/update pozdoc set 
			lot=(case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end)
		from pozdoc p
			JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
		where subunitate=@csub and p.tip in ('RM','PP','AI') 
			and isnull(lot,'')<>(case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end)
			--and isnull((case when p.tip='RM' then cont_corespondent when p.tip in ('PP','AI') then grupa end),'')<>''
			and (@tip is null or p.Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus
			
		update pozdoc 
		set lot=cod_intrare
		from pozdoc p
			JOIN proprietati pr on pr.Tip='NOMENCL' and pr.Cod_proprietate='ARESERII' and pr.Cod=p.Cod and pr.Valoare='DA' and pr.Valoare_tupla=''
		where subunitate=@csub and p.tip<>'TE' and Tip_miscare='E' and Cantitate<0
			and isnull(lot,'')='' 
			and isnull(cod_intrare,'')<>''
			and (@tip is null or p.Tip=@Tip) and (@numar is null or Numar=@Numar) and data between @datajos and @datasus
	end
	alter table pozdoc enable trigger all
end try
begin catch
	alter table pozdoc enable trigger all
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch