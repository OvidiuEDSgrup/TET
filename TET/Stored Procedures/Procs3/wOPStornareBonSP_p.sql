
CREATE PROCEDURE wOPStornareBonSP_p @sesiune varchar(50), @parXML XML
AS
begin try

	declare
		@utilizator varchar(100), @gestiune varchar(20), @lm varchar(20), @data datetime, @tert varchar(20), @mesaj varchar(max), 
		@cont_casa varchar(20), @denlm varchar(100), @dengestiune varchar(100), @idantetbon int, 
		@sub varchar(9), @DetaliereBonuri int, @numar_PozDoc varchar(20), @databon datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT	

	select	@sub=(case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else isnull(@sub,'') end),
			@DetaliereBonuri=(case when Parametru='DETBON' then Val_logica else isnull(@DetaliereBonuri, 0) end)
	from par
	where Tip_parametru='GE' and Parametru in ('SUBPRO')
		or Tip_parametru='PO' and Parametru in ('DETBON') 

	set @idantetbon= @parXML.value('(/*/@idantetbon)[1]','int')

	if @idantetbon is null
		raiserror('Nu s-a putut identifica bonul! Selectati un bon din tabel !',16,1)

	select 
		@gestiune=dbo.wfProprietateUtilizator('GESTPV',@utilizator),
		@lm=dbo.wfProprietateUtilizator('LOCMUNCASTABIL',@utilizator),
		@cont_casa=dbo.wfProprietateUtilizator('CONTCASA',@utilizator)

	if isnull(@gestiune,'')=''
		raiserror('Verificati proprietatea GESTPV (gestiune pentru vanzare) a utilizatorului curent!',16,1)
	--if isnull(@lm,'')=''
	--	raiserror('Verificati proprietatea LOCMUNCA (locul de munca) a utilizatorul curent!',16,1)
	if isnull(@cont_casa,'')=''
		raiserror('Verificati proprietatea CONTCASA (contul asociat) a utilizatorul curent!',16,1)
		
	select top 1 
		@numar_PozDoc= bon.value('(/date/document/@numar_in_pozdoc)[1]','varchar(20)'),
		@databon=Data_bon
	from antetBonuri where IdAntetBon=@idantetbon

	IF OBJECT_ID('tempdb..#pozdocAC') is not null
		drop table #pozdocAC

	select pd.*
	into #pozdocAC
	from PozDoc pd where pd.Subunitate=@sub and pd.tip='AC' and pd.Numar=@numar_PozDoc and Data=@databon

	/*	sugeram in antet max(gestiune) din pozdoc, iar in procedura de stornare punem in /row/row gestiunea din pozdoc */
	select @gestiune=max(gestiune) from #pozdocAC
	select @dengestiune=rtrim(denumire_gestiune) from gestiuni g where g.Cod_gestiune=@gestiune
	select @denlm=RTRIM(denumire) from lm where lm.cod=@lm 

	select 
		rtrim(@gestiune) gestiune_storno, rtrim(@lm) lm_storno, rtrim(@denlm) denlm_storno, rtrim(@dengestiune) dengestiune_storno	
	for xml raw, ROOT('Date')

	/*	daca @DetaliereBonuri=1 (s-a generat pentru fiecare bon un AC), se va face stornarea pana la nivel de cod intrare de pe AC-ul initial. 
		Afisam in Grid  codul de intrare si pretul de stoc pt. identificarea mai usor a pozitiei de pe care sa se storneze partial */
	if @DetaliereBonuri=1
		select (   
			select 
				rtrim(pd.Cod) as cod_produs,
				rtrim(n.Denumire) as denumire,
				@dengestiune as gestiune,
				convert(decimal(17,2),pd.Cantitate) as cantitate,
				convert(decimal(17,5),pd.Pret_de_stoc) as pstoc,
				convert(decimal(17,2),pd.Pret_cu_amanuntul) as pret,
				convert(decimal(17,2),pd.Cantitate*(-1)) as cant_storno,
				rtrim(pd.Cod_intrare) as codintrare,
				idPozdoc as idPozdoc
			from #pozdocAC pd
				left join nomencl n ON n.Cod=pd.Cod
			for xml raw, type
		  )  
		for xml path('DateGrid'), root('Mesaje')
	else
		select (   
			select 
				rtrim(b.Cod_produs) as cod_produs,
				rtrim(n.Denumire) as denumire,
				@dengestiune as gestiune,
				convert(decimal(17,2),b.Cantitate) as cantitate,
				convert(decimal(17,2),b.Pret) as pret,
				convert(decimal(17,2),b.Cantitate*(-1)) as cant_storno,
				numar_linie as nrlinie
			from bonuri b
				left join nomencl n ON n.Cod=b.Cod_produs
			where idAntetBon=@idantetbon and b.Tip=21 and isnull(Cod_produs,'')<>''
			for xml raw, type
		  )  
		for xml path('DateGrid'), root('Mesaje')

end try
begin catch
	select 
		'1' as inchideFereastra
	for xml raw, ROOT('Mesaje')

	set @mesaj=ERROR_MESSAGE()+ ' (wOPStornareBonSP_p)'
	RAISERROR(@mesaj, 11, 1)
end catch