--***
create procedure initializareLunaStocuri (@anulinit int,@lunainit int,@inchidlunaant int=0,
@faracalcstocinit int=0,@calculrapid int=0,@farainlocpretdoc int=0)
as
begin
declare @eroare varchar(1000)
begin try
	if exists (select valoare, cod_proprietate from fPropUtiliz(null) where cod_proprietate='GESTIUNE' and valoare<>'')
	begin
		raiserror('Accesul este restrictionat pe anumite gestiuni! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end

	if (dbo.f_arelmfiltru(dbo.fIaUtilizator(null))=1)
	begin
		raiserror('Accesul este restrictionat pe anumite locuri de munca! Nu este permisa operatia in aceste conditii!',16,1)
		return
	end
	declare @pretmediu int, @serii int
	select	@pretmediu=isnull((case when Parametru='MEDIUP' then Val_logica else @pretmediu end),0),
			@serii=isnull((case when Parametru='SERII' then Val_logica else @serii end),0)
		from par
		where (Tip_parametru='GE' and Parametru in ('MEDIUP','SERII')) 

	if exists (select 1 from sysobjects where type='P' and name='initializareLunaStocuriRia') and @pretmediu=0 and @serii=0--daca pret mediu sau serii sa mearga pe varianta anterioara.
	begin
		declare @pXML xml
		set @pXML=(select @anulinit as 'an',@lunainit as 'luna' for xml raw)
		exec initializareLunaStocuriRia @sesiune='',@parXML=@pXML
		return
	end
	else
	begin
		declare @sub char(9),@pretmedium int,@inlocpret int,
			@lunainch int,/*@lunainchalfa char(20),*/@anulinch int,@datainch datetime,
			@lunadeinch int,@lunadeinchalfa char(20),@anuldeinch int,@datadeinch datetime,
			@lunabloc int,/*@lunablocalfa char(20),*/@anulbloc int,@databloc datetime
		select @sub=isnull((case when Parametru='SUBPRO' then rtrim(Val_alfanumerica) else @sub end),''),
			@pretmediu=isnull((case when Parametru='MEDIUP' then Val_logica else @pretmediu end),0),
			@lunainch=isnull((case when Parametru='LUNAINC' then Val_numerica else @lunainch end),1),
			@anulinch=isnull((case when Parametru='ANULINC' then Val_numerica else @anulinch end),1901),
			@lunabloc=isnull((case when Parametru='LUNABLOC' then Val_numerica else @lunabloc end),1),
			@anulbloc=isnull((case when Parametru='ANULBLOC' then Val_numerica else @anulbloc end),1901)
			--@=isnull((case when Parametru= then Val_numerica else @ end),0),
			from par
			where (Tip_parametru='GE' and Parametru in ('SUBPRO','SERII','MEDIUP','LUNABLOC','ANULBLOC',
			'LUNAINC','ANULINC')) --or (Tip_parametru='UC' and Parametru in ('CNAZBKBP','POZSURSE'))
		set @anuldeinch=@anulinit---(case when @lunainit=1 then 1 else 0 end)
		set @lunadeinch=@lunainit --(case when @lunainit=1 then 12 else @lunainit-1 end)
		set @datadeinch=dbo.eom(convert(varchar(20),@anuldeinch)+'-'+convert(varchar(20),@lunadeinch)+'-1')
		select @lunadeinchalfa=LunaAlfa from fCalendar(@datadeinch,@datadeinch)
		set @datainch=dbo.eom(convert(varchar(20),@anulinch)+'-'+convert(varchar(20),@lunainch)+'-1')
		set @databloc=@datainch
		if @anulbloc>0 set @databloc=dbo.eom(convert(varchar(20),@anulbloc)+'-'+convert(varchar(20),@lunabloc)+'-1')
	
		--Stoc final luna ce se inchide = ...	
		if @faracalcstocinit=0
		begin
			set @pretmedium=@pretmediu
			set @inlocpret=(case when @pretmediu=1 and @farainlocpretdoc=0 then 1 else 0 end)
			exec RefacereStocuri @cgestiune=null, @ccod=null, @cmarca=null, @ddata=@datadeinch, 
				@pretmed=@pretmedium, @inlocpret=@inlocpret
			if @serii=1 exec RefacereSerii @cgestiune=null, @ccod=null, @ddata=@datadeinch
		end
		--... = stoc initial luna ce se initializeaza
		delete from istoricstocuri where subunitate=@sub and data_lunii=@datadeinch 
		insert into istoricstocuri (Subunitate, Data_lunii, Tip_gestiune, Cod_gestiune, Cod, Data, Cod_intrare, Pret, TVA_neexigibil, Pret_cu_amanuntul, Stoc, Cont, Locatie, Data_expirarii, Pret_vanzare, Loc_de_munca, Comanda, Contract, Furnizor, Lot, Stoc_UM2, Val1, Alfa1, Data1,idIntrareFirma)
			select subunitate, @datadeinch, tip_gestiune, cod_gestiune, cod, data, cod_intrare, pret, 
			TVA_neexigibil, pret_cu_amanuntul, stoc, cont, locatie, data_expirarii, pret_vanzare, 
			Loc_de_munca, Comanda, Contract, Furnizor, Lot, Stoc_UM2, Val1, Alfa1, Data1,idIntrareFirma
			from stocuri where subunitate=@sub and (abs(stoc)>=0.001 or abs(stoc_UM2)>=0.001)
		if @serii=1
		begin
			delete istoricserii where subunitate=@sub and data_lunii=@datadeinch 
			insert istoricserii (Subunitate, Data_lunii, Tip_gestiune, Gestiune, Cod, Cod_intrare, Serie, Stoc) 
				select subunitate, @datadeinch, tip_gestiune, gestiune, cod, cod_intrare, serie, stoc
				from serii where subunitate=@sub and abs(stoc)>=0.001
		end
		--memorare luna inchisa si pun in par ca sa stiu ca am scris SF al lunii ce s-a inchis
		if @inchidlunaant=1
		begin
			exec setare_par 'GE','SCRSFLINC','Scris stoc final luna inchisa',1,0,''
			exec setare_par 'GE','LUNAINC','Luna inchisa',0,@lunadeinch,@lunadeinchalfa
			exec setare_par 'GE','ANULINC','Anul lunii inchise',0,@anuldeinch,''
		end
		--memorare luna blocata daca era anterioara noii luni inchise
		if @inchidlunaant=1 and @databloc<@datadeinch
		begin
			exec setare_par 'GE','LUNABLOC','Luna blocata',0,@lunadeinch,@lunadeinchalfa
			exec setare_par 'GE','ANULBLOC','Anul lunii blocate',0,@anuldeinch,''
		end

		set @pretmedium=(case when @pretmediu=1 and @calculrapid=0 then 1 else 0 end)
		set @inlocpret=(case when @pretmediu=1 and @calculrapid=0 and @farainlocpretdoc=0 then 1 else 0 end)
		exec RefacereStocuri @cgestiune=null, @ccod=null, @cmarca=null, @ddata=null, 
			@pretmed=@pretmedium, @inlocpret=@inlocpret
		if @serii=1 exec RefacereSerii @cgestiune=null, @ccod=null, @ddata=null
	end
end try
begin catch
	set @eroare='initializareLunaStocuri (linia '+convert(varchar(20),ERROR_LINE())+'):'+char(10)+
			rtrim(ERROR_MESSAGE())
	raiserror(@eroare,16,1)
end catch
end
