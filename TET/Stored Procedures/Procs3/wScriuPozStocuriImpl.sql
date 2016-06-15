/****** Object:  StoredProcedure [dbo].[wScriuPozStocuriImpl]    Script Date: 01/05/2011 22:59:01 ******/

--***
create procedure wScriuPozStocuriImpl  @sesiune varchar(50), @parXML xml
as
declare @iDoc int,@mesaj varchar(200),@update int,@cod varchar(20),@cod_intrare varchar(13),@pret float,@stoc float,
	@pret_mediu_ini float,@locatie varchar(30),@comanda varchar(40),@contract varchar(20),@furnizor varchar(20),@lot varchar(20),
	@cont varchar(40),@data_ultimei_iesiri datetime,@data_expirarii datetime,@stoc_um varchar(1),
	@utilizator varchar(20),@userAsis varchar(20),@cod_gestiune varchar(13),@data datetime,@o_cod varchar(20),
	@o_cod_intrare varchar(13),@serie varchar(20),@subtip varchar(2),@o_serie varchaR(20),
	@sub varchar(9),@an_impl int,@luna_impl int,@mod_impl int,@data_impl datetime,@stocuriPeComenzi int,@stocuriPeFurnizori int,@locatii int, @capacitateLocatii int,
	@tip varchar(2),@data_lunii datetime,@o_data datetime,@lm varchar(13),@_cautare varchar(50),@data_lunii_istoric datetime

begin try
		
	select
		@tip= isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@cod_gestiune= isnull(@parXML.value('(/row/@cod_gestiune)[1]','varchar(13)'),''),
		@data_lunii= isnull(@parXML.value('(/row/@data_lunii)[1]','datetime'),''),					
	
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@data= isnull(@parXML.value('(/row/row/@data)[1]','datetime'),'1901-01-01'),	
		@cod= isnull(@parXML.value('(/row/row/@cod)[1]','varchar(20)'),''),		
		@cod_intrare = isnull(@parXML.value('(/row/row/@codintrare)[1]','varchar(13)'),''),
		@pret = isnull(@parXML.value('(/row/row/@pret)[1]','float'),0),	
		@stoc = isnull(@parXML.value('(/row/row/@stoc)[1]','float'),0),
		@pret_mediu_ini = isnull(@parXML.value('(/row/row/@pret_cu_amanuntul)[1]','float'),0),	
		@locatie= isnull(@parXML.value('(/row/row/@locatie)[1]','varchar(30)'),''),
		@lm= isnull(@parXML.value('(/row/row/@lm)[1]','varchar(13)'),''),
		@comanda= isnull(@parXML.value('(/row/row/@comanda)[1]','varchar(40)'),''),
		@contract= isnull(@parXML.value('(/row/row/@contract)[1]','varchar(20)'),''),
		@furnizor= isnull(@parXML.value('(/row/row/@furnizor)[1]','varchar(20)'),''),
		@lot= isnull(@parXML.value('(/row/row/@lot)[1]','varchar(20)'),''),
		@cont= isnull(@parXML.value('(/row/row/@cont)[1]','varchar(40)'),''),
		@data_ultimei_iesiri= isnull(@parXML.value('(/row/row/@data_ultimei_iesiri)[1]','datetime'),''),
		@data_expirarii= isnull(@parXML.value('(/row/row/@data_expirarii)[1]','datetime'),''),
		@stoc_um= isnull(@parXML.value('(/row/row/@stoc_um)[1]','varchar(1)'),'1'),
		@subtip= isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'),''),
		@serie= isnull(isnull(@parXML.value('(/row/row/@serie)[1]','varchar(20)'),@parXML.value('(/row/linie/@serie)[1]','varchar(20)')),''),
		@_cautare=isnull(@parXML.value('(/row/@_cautare)[1]', 'varchar(50)'), '') , 		
		
		@o_cod= isnull(@parXML.value('(/row/row/@o_cod)[1]','varchar(20)'),''),		
		@o_cod_intrare = isnull(@parXML.value('(/row/row/@o_codintrare)[1]','varchar(13)'),''),
		@o_serie= isnull(isnull(@parXML.value('(/row/row/@o_serie)[1]','varchar(20)'),@parXML.value('(/row/linie/row/@serie)[1]','varchar(20)')),''),
		@o_data= isnull(@parXML.value('(/row/row/@o_data)[1]','datetime'),'1901-01-01')
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	set @data_impl='1901-01-01'		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''
	exec luare_date_par 'GE', 'STOCPECOM', @stocuriPeComenzi output, 0, ''
	exec luare_date_par 'GE', 'STOCFURN', @stocuriPeFurnizori output, 0, ''
	exec luare_date_par 'GE', 'LOCATIE', @locatii output, @capacitateLocatii output, ''

	if @an_impl<>0
		set @data_impl=dbo.EOM(convert(datetime,str(@luna_impl,2)+'/01/'+str(@an_impl,4),101))
	
	if @mod_impl=0
		raiserror('Modificarile pot fi efectuate doar daca sunteti in mod implementare!!',11,1)	
	
	--select @data_lunii,@an_impl,@luna_impl
	if dbo.EOM(@data_lunii)>@data_impl and @tip not in ('SI','OF')
	begin
		set @mesaj='       Data lunii ('+convert(char(7),+convert(varchar,month(@data_lunii))+'/'+convert(varchar,year(@data_lunii))) +')'+ 
					+'este mai mare decat data de implementare('+convert(char(7),+convert(varchar,@luna_impl)+'/'+convert(varchar,@an_impl)) +')!!'
		raiserror(@mesaj,11,1)
	end
		
	if @subtip='SE' --daca subtipul este 'SE' suntem pe pozitie de serie, si atunci citim date din linie
	begin			
		set @cod=ISNULL(@parXML.value('(/row/linie/@cod)[1]', 'varchar(20)'), '')
		set @stoc_um= isnull(@parXML.value('(/row/linie/@stoc_um)[1]','varchar(1)'),'')
		set @cod_intrare=isnull(ISNULL(@parXML.value('(/row/linie/@codintrare)[1]', 'varchar(13)'), @parXML.value('(/row/linie/@codintrareS)[1]', 'varchar(13)')),'')
	end
--	validari campuri
	if not exists (select 1 from nomencl where Cod=@Cod) 
		raiserror('Cod inexistent!',11,1)
	if @cod_intrare='' 
		raiserror('Introduceti cod intrare pentru pozitie!',11,1)
	if @pret<=0	
		raiserror('Introduceti pretul!',11,1)
	if @stoc=0	
		raiserror('Introduceti stocul!',11,1)
	if @Cont='' 
		raiserror('Cont necompletat!',11,1)
	if not exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont) 
		raiserror('Cont inexistent!',11,1)
	if exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont and Are_analitice=1) 
		raiserror('Contul are analitice!',11,1)
	if not exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont and Sold_credit=3) 
		raiserror('Contul trebuie sa fie atribuit 3-Stocuri!',11,1)
	if @lm<>'' and not exists (select 1 from lm where Cod=@lm) 
		raiserror('Loc de munca inexistent!',11,1)
	if @stocuriPeComenzi=1 and @comanda<>'' and not exists (select 1 from Comenzi where Subunitate=@sub and Comanda=@comanda) 
		raiserror('Comanda inexistenta!',11,1)
	if @stocuriPeFurnizori=1 and @furnizor<>'' and not exists (select 1 from Terti where Subunitate=@sub and Tert=@furnizor) 
		raiserror('Furnizor inexistent!',11,1)
	if @locatii=1 and @capacitateLocatii=1 and @locatie<>'' and not exists (select 1 from locatii where Cod_locatie=@locatie) 
		raiserror('Locatie inexistenta!',11,1)

	set @data_lunii_istoric=(case when @tip in ('SI','OF') then @data_impl else dbo.EOM(@data_lunii) end)
	if @update=1--pe ramura de update
	begin
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=@o_Cod), '')='Y'  and @cod<>@o_cod 
			and exists (select 1 from istoricserii where Subunitate=@sub and Gestiune=@cod_gestiune  and Cod=@o_cod and Cod_intrare=@o_cod_intrare) 
			raiserror('Inainte de modificarea acestui cod trebuie sterse toate pozitiile de serii introduse pe el!!',11,1)
		
		if @subtip<>'SE'--in istoricstocuri nu se face update dc suntem pe subtip de serie
			update istoricstocuri
			set Cod=(case when isnull(@cod,'')<>'' then @cod else cod end), Cod_intrare=(case when isnull(@cod_intrare,'')<>'' then @cod_intrare else Cod_intrare end),
				Pret=(case when isnull(@pret,0)<>0 then @pret else pret end), Pret_cu_amanuntul=(case when isnull(@pret_mediu_ini,0)<>0 then @pret_mediu_ini else Pret_cu_amanuntul end),
				Stoc=(case when @stoc_um='1' and @stoc<>0 then convert(decimal(12,4),@stoc) else stoc end), Cont=(case when isnull(@cont,'')<>'' then @cont else cont end),
				Locatie=(case when isnull(@locatie,'')<>'' then @locatie else locatie end), Data_expirarii=@data_expirarii,
				Loc_de_munca=(case when isnull(@lm,'')<>'' then @lm else Loc_de_munca end),
				Comanda=(case when isnull(@comanda,'')<>'' then @comanda else comanda end), Contract=(case when isnull(@contract,'')<>'' then @contract else Contract end),
				Furnizor=(case when isnull(@furnizor,'')<>'' then @furnizor else Furnizor end), Lot=(case when isnull(@lot,'')<>'' then @lot else lot end),
				Stoc_UM2=(case when @stoc_um='2' and @stoc<>0 then convert(decimal(12,4),@stoc) else Stoc_UM2 end),
				Data=(case when ISNULL(@data,'1901-01-01')<>'1901-01-01' then @data else data end)
			where cod=@o_cod and Cod_intrare=@o_cod_intrare and Cod_gestiune=@cod_gestiune and data=@o_data
	
		--daca codul pe care se face update are serii atunci se fac updateurile necesare si in istoricserii
		if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and (isnull(@Serie,'')<>'' or isnull(@o_serie,'')<>'') 
		begin
			if @subtip='SE'	
			begin	
				update istoricserii set Serie=(case when isnull(@serie,'')<>'' then @serie else Serie end), 
					Stoc=(case when @stoc<>0 then convert(decimal(12,4),@stoc) else stoc end),
					Cod_intrare=(case when isnull(@cod_intrare,'')<>'' then @cod_intrare else Cod_intrare end)
				where Subunitate=@Sub and Data_lunii=@data_lunii_istoric and Gestiune=@cod_gestiune and cod=@cod and Cod_intrare=@cod_intrare and Serie=@o_serie				
			end
		else
				update istoricserii set Serie=(case when isnull(@serie,'')<>'' then @serie else Serie end), 
					Stoc=(case when @stoc<>0 then convert(decimal(12,4),@stoc) else stoc end),
					Cod_intrare=(case when isnull(@cod_intrare,'')<>'' then @cod_intrare else Cod_intrare end)
				where Subunitate=@Sub and Data_lunii=@data_lunii_istoric and Gestiune=@cod_gestiune and cod=@o_cod and Cod_intrare=@o_cod_intrare and Serie=@o_serie	
		end	
		
		--se face update pe stoc in istoric serii
		update istoricstocuri  set Stoc=isnull((select SUM(i.stoc) from istoricserii i where Subunitate=@sub and i.Gestiune=@cod_gestiune 
																					  and i.Cod=@cod and i.Cod_intrare=@cod_intrare),stoc),
								   Stoc_UM2=isnull((case when @stoc_um=2 then (select SUM(i.stoc) from istoricserii i where Subunitate=@sub and i.Gestiune=@cod_gestiune 
																					  and i.Cod=@cod and i.Cod_intrare=@cod_intrare) else 0 end	),Stoc_UM2)										  
		where Subunitate=@sub and Data_lunii=@data_lunii_istoric and Cod_gestiune=@cod_gestiune and cod=@cod and Cod_intrare=@cod_intrare		
	end
	
	else
	begin
		if @subtip<>'SE'	
			INSERT INTO istoricstocuri ([Subunitate],[Data_lunii],[Tip_gestiune],[Cod_gestiune],[Cod],[Data],[Cod_intrare],[Pret],[TVA_neexigibil],[Pret_cu_amanuntul]
				,[Stoc],[Cont],[Locatie],[Data_expirarii],[Pret_vanzare],[Loc_de_munca],[Comanda],[Contract],[Furnizor],[Lot],[Stoc_UM2],[Val1],[Alfa1],[Data1])
			SELECT
				@Sub, @data_lunii_istoric, (case when @subtip in ('OI','OF') then 'F' else (select Tip_gestiune from gestiuni where Cod_gestiune=@cod_gestiune) end), 
				@cod_gestiune, @cod, @data, @cod_intrare, @pret, /*@tva_neexigibil*/'', @pret_mediu_ini
				,(case when @stoc_um='1' or isnull(@stoc_um,'')='' then convert(decimal(12,4),@stoc) else 0 end), @cont, @locatie, @data_expirarii,/*@pret_vanzare*/0, 
				@lm, @comanda, @contract, @furnizor, @lot, (case when @stoc_um='2' then convert(decimal(12,4),@stoc) else 0 end)  ,0,  '' ,'1901-01-01'
		
		---daca pe acest cod se lucreaza cu serii se face insert si in istoricstocuri
    	if isnull((select max(left(UM_2, 1)) from nomencl where cod=@Cod), '')='Y' and isnull(@Serie,'')<>''
    	begin
    		INSERT INTO istoricserii ([Subunitate],[Data_lunii],[Tip_gestiune],[Gestiune],[Cod],[Cod_intrare],[Serie],[Stoc])
			SELECT @Sub,@data_lunii_istoric,(select Tip_gestiune from gestiuni where Cod_gestiune=@cod_gestiune), @cod_gestiune, @cod,
				   @cod_intrare,@serie,convert(decimal(12,4),@stoc)
			
			update istoricstocuri set Stoc=(select SUM(i.stoc) from istoricserii i where Subunitate=@sub and i.Gestiune=@cod_gestiune 
																					  and i.Cod=@cod and i.Cod_intrare=@cod_intrare),
										Stoc_UM2=(case when @stoc_um=2 then (select SUM(i.stoc) from istoricserii i where Subunitate=@sub and i.Gestiune=@cod_gestiune 
																					  and i.Cod=@cod and i.Cod_intrare=@cod_intrare)	else 0 end	)										  
			where Subunitate=@sub and Cod_gestiune=@cod_gestiune and cod=@cod and Cod_intrare=@cod_intrare	
		end																  
	end

	declare @docXML xml
	set @docXML='<row tip="'+rtrim(@tip)+'" cod_gestiune="'+rtrim(@cod_gestiune)+'" data_lunii="'+convert(varchar(10),@data_lunii_istoric,101)
		+'" _cautare="'+rtrim(@_cautare)+'"/>'
	exec wIaPozStocuriImpl @sesiune=@sesiune, @parXML=@docXML
end try
begin catch
	set @mesaj = '(wScriuPozStocuriImpl): '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
