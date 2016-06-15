create procedure wOPModifDatePozDocMF @sesiune varchar(50), @parXML xml
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPModifDatePozDocMFSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPModifDatePozDocMFSP @sesiune, @parXML
	return @returnValue
end

declare @sub char(9), @lunainch int, @lunaalfainch char(20), @anulinch int, --@datainch datetime, 
	@lunabloc int, @lunaalfabloc char(20), @anulbloc int, @databloc datetime, 
	@tip varchar(2), @subtip varchar(2), @numar varchar(20), @data datetime, 
	@nrinv varchar(13), @procinch float, @contgestprim varchar(40), @contlmprim varchar(40), 
	@contamcomprim varchar(40), @indbugprim char(30), @tipdocCG char(2), @binar varbinary(128)

begin try
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	Set @lunainch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
		parametru='LUNAINC'), 1)
	Set @lunaalfainch=isnull((select max(Val_alfanumerica) from par where tip_parametru='GE' and 
		parametru='LUNAINC'), 'Ianuarie')
	Set @anulinch=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
		parametru='ANULINC'), 1901)
	Set @lunabloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
		parametru='LUNABLOC'), 1)
	Set @lunaalfabloc=isnull((select max(Val_alfanumerica) from par where tip_parametru='GE' and 
		parametru='LUNABLOC'), 'Ianuarie')
	Set @anulbloc=isnull((select max(val_numerica) from par where tip_parametru='GE' and 
		parametru='ANULBLOC'), 1901)
	if @anulbloc=0
		select @lunabloc=@lunainch, @lunaalfabloc=@lunaalfainch, @anulbloc=@anulinch
	set @databloc=dbo.eom(convert(datetime,str(@lunabloc,2)+'/01/'+str(@anulbloc,4)))

	select @tip=isnull(@parXML.value('(/parametri/@tip)[1]','varchar(2)'),''),
		@subtip=isnull(@parXML.value('(/parametri/row/@subtip)[1]','varchar(2)'),''),
		@numar=isnull(@parXML.value('(/parametri/@numar)[1]','varchar(20)'),''),
		@data=isnull(@parXML.value('(/parametri/@data)[1]','datetime'),'01/01/1901'),
		@nrinv=isnull(@parXML.value('(/parametri/@nrinv)[1]','varchar(13)'),''),
		@procinch=isnull(@parXML.value('(/parametri/@procinch)[1]','float'),0),
		@contgestprim=isnull(@parXML.value('(/parametri/@contgestprim)[1]','varchar(40)'),''),
		@contlmprim=isnull(@parXML.value('(/parametri/@contlmprim)[1]','varchar(40)'),''),
		@contamcomprim=isnull(@parXML.value('(/parametri/@contamcomprim)[1]','varchar(40)'),''),
		@indbugprim=isnull(@parXML.value('(/parametri/@indbugprim)[1]','varchar(30)'),'')
	--select @tip,@subtip,@procinch,@sub, @numar, @data-- @contgestprim	
	if @data<=@databloc
		raiserror('Data documentului este intr-o luna inchisa in CG!',16,1)

	if @nrinv='' --or @numar_pozitie=0
		raiserror('Selectati o pozitie de document!',16,1)
	else
	begin
		if @tip='MT' update mismf set Subunitate_primitoare=@contamcomprim+replace(@indbugprim,'.',''),
			Gestiune_primitoare=@contgestprim, Loc_de_munca_primitor=@contlmprim
			where subunitate=@sub and Tip_miscare=right(@tip,1)+@subtip and Numar_document=@numar 
				and Data_miscarii=@data and Numar_de_inventar=@nrinv
	
		if @procinch=6
		begin
			SET @tipdocCG=(case @tip when 'MI' then (case @subtip when 'AF' then 'RM' else 'AI' end) 
				when 'MM' then (case @subtip when 'EP' then 'AE' when 'FF' then 'RM' else 'AI' end) 
				when 'ME' then (case @subtip when 'SU' then 'AE' when 'VI' then 'AP' else 'AE' end) 
				when 'MT' then (case when 6/*@procinch*/=6 and @subtip='SE' then 'AI' else '' end) 
				else '' end)

			set @binar=cast('modificaredocdefinitivMF' as varbinary(128))--sa se poata modif.doc.din MF
			set CONTEXT_INFO @binar
			
			if @tip='MT' update pozdoc set Gestiune=@contgestprim, Loc_de_munca=@contlmprim, 
				Comanda=@contamcomprim+replace(@indbugprim,'.','')
				where subunitate=@sub and tip=@tipdocCG and numar=@numar and data=@data 
					and Cod_intrare=@nrinv and Cantitate=1
			
			set CONTEXT_INFO 0x00
		end
	end
end try

begin catch
	declare @error varchar(500)
	set @error='wOPModifDatePozDocMF: '+ERROR_MESSAGE()
	raiserror(@error,16,1)
end catch
