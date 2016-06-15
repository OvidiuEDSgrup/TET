/****** Object:  StoredProcedure [dbo].[wScriuPozFactImpl]    Script Date: 01/05/2011 22:59:01 ******/

--***
create procedure wScriuPozFactImpl  @sesiune varchar(50), @parXML xml
as
declare @iDoc int,@Sub char(9),@mesaj varchar(200),@update int,@lm char(8),@comanda char(20),@indbug char(20),@ComandaDeScris char(40),@utilizator varchar(30),@factura varchar(20),
		@tip varchar(2),@data datetime,@data_scadentei datetime	,@tert varchar(13),@valoare float,@tva_11 float,@tva_22 float,@valuta varchar(3),
		@curs float,@achitat float,@cont varchar(40),@data_ultimei_achitari datetime,@tiptert varchar(1),@sold_lei float,@o_tiptert varchar(1),@o_factura varchar(20),
		@o_tert varchar(13),@an_impl int,@luna_impl int,@mod_impl int,@valoare_valuta float,@achitat_valuta float,@valoare_lei float,@achitat_lei float,
		@sold_valuta float,@valtva_lei float,@valtva_valuta float,@mesajEroare varchar(200)

begin try	
	select
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@factura = isnull(@parXML.value('(/row/row/@factura)[1]','varchar(20)'),''),
		@tert = isnull(@parXML.value('(/row/row/@tert)[1]','varchar(13)'),''),	
		@tip = isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
		@tiptert = isnull(@parXML.value('(/row/@tiptert)[1]','varchar(1)'),''),
		@data=ISNULL(@parXML.value('(/row/row/@data)[1]', 'datetime'), '1901-01-01'),
		@data_scadentei=ISNULL(@parXML.value('(/row/row/@data_scadentei)[1]', 'datetime'), '1901-01-01'),
		@data_ultimei_achitari=ISNULL(@parXML.value('(/row/row/@data_ultimei_achitari)[1]', 'datetime'), '1901-01-01'),
		@valoare=ISNULL(@parXML.value('(/row/row/@valoaref)[1]', 'float'), 0),
		@tva_11=ISNULL(@parXML.value('(/row/row/@tva_11)[1]', 'float'), 0),
		@tva_22=ISNULL(@parXML.value('(/row/row/@tva_22f)[1]', 'float'), 0),
		@valuta=@parXML.value('(/row/row/@valuta)[1]', 'varchar(3)')  ,
		@curs=ISNULL(@parXML.value('(/row/row/@curs)[1]', 'float'), 0),
		@achitat=ISNULL(@parXML.value('(/row/row/@achitatf)[1]', 'float'), 0),
		@cont=@parXML.value('(/row/row/@cont_de_tert)[1]', 'varchar(40)'),			
		@lm=@parXML.value('(/row/row/@lm)[1]', 'varchar(13)'),
		@comanda=isnull(@parXML.value('(/row/row/@comanda)[1]', 'varchar(40)'),''),
		@indbug=isnull(@parXML.value('(/row/row/@indbug)[1]', 'varchar(40)'),''),
		
		@o_tiptert = isnull(@parXML.value('(/row/row/@o_tiptert)[1]','varchar(1)'),''),
		@o_factura = isnull(@parXML.value('(/row/row/@o_factura)[1]','varchar(20)'),''),
		@o_tert = isnull(@parXML.value('(/row/row/@o_tert)[1]','varchar(13)'),'')
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''
	
	if YEAR(@data)>@an_impl or YEAR(@data)=@an_impl and MONTH(@data)>@luna_impl
		raiserror('Data facturii > data implementarii!',11,1)
		
	if @mod_impl=0
		raiserror('Modificarile pot fi efectuate doar daca sunteti in mod implementare!',11,1)	

--	validare campuri
	if @factura='' 
		raiserror('Introduceti numarul facturii!',11,1)
	if not exists (select 1 from Terti where Subunitate=@sub and Tert=@tert) 
		raiserror('Tert inexistent!',11,1)
	if @indbug<>'' and not exists (select 1 from indbug where Indbug=@indbug) 
		raiserror('Indicator bugetar inexistent!',11,1)
	if @lm<>'' and not exists (select 1 from lm where Cod=@lm) 
		raiserror('Loc de munca inexistent!',11,1)
	if @comanda<>'' and not exists (select 1 from Comenzi where Subunitate=@sub and Comanda=@comanda) 
		raiserror('Comanda inexistenta!',11,1)
	if @Cont='' 
		raiserror('Cont necompletat!',11,1)
	if not exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont) 
		raiserror('Cont inexistent!',11,1)
	if exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont and Are_analitice=1) 
		raiserror('Contul are analitice!',11,1)
	if not exists (select 1 from conturi where Subunitate=@sub and Cont=@Cont and Sold_credit=(case when @tiptert='F' then 1 else 2 end)) 
	Begin
		set @mesajEroare='Contul trebuie sa fie atribuit '+(case when @tiptert='F' then '1-Furnizori' else '2-Beneficiari' end)+'!'
		raiserror(@mesajEroare,11,1)
	End
	if @valuta<>'' and not exists (select 1 from valuta where Valuta=@valuta) 
		raiserror('Valuta inexistenta!',11,1)

	set @ComandaDeScris=@comanda+@indbug
		
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output		
	set @valoare_lei=round((case when isnull(@valuta,'')='' then @valoare when isnull(@valuta,'')<>'' and isnull(@curs,0)<>0 then @valoare*@curs else 0 end),4)
	set @valoare_valuta=round((case when isnull(@valuta,'')='' then 0 when isnull(@valuta,'')<>'' and isnull(@curs,0)<>0 then @valoare else 0 end),4)
	set @achitat_lei=round((case when isnull(@valuta,'')='' then @achitat when isnull(@valuta,'')<>'' and isnull(@curs,0)<>0 then @achitat*@curs else 0 end),4)
	set @achitat_valuta=round((case when isnull(@valuta,'')='' then 0 when isnull(@valuta,'')<>'' and isnull(@curs,0)<>0 then @achitat else 0 end),4)
	set @valtva_lei=round((case when isnull(@valuta,'')='' then @tva_22 when isnull(@valuta,'')<>'' and isnull(@curs,0)<>0 then @tva_22*@curs else 0 end),4)
		
	set @sold_lei=round(@valoare_lei+@valtva_lei-@achitat_lei,4)
	set @sold_valuta=round(case when ISNULL(@valuta,'')<>'' and ISNULL(@curs,0)<>0 then @valoare_valuta+(@valtva_lei/@curs)-@achitat_valuta else 0 end,4)
		
	if @update=1
	begin
	--select @achitat,@tiptert,@o_factura,@o_tert
		UPDATE factimpl set Factura=(case when ISNULL(@factura,'')<>'' then @factura else factura end),
			Loc_de_munca=(case when @lm is not null then @lm else Loc_de_munca end),
			Tip=(case @tiptert when 'B' then 0x46 when 'F' then 0x54 else tip end),
			Tert=(case when ISNULL(@tert,'')<>'' then @tert else tert end),
			Data=@data,
			Data_scadentei=@data_scadentei,
			Valoare=@valoare_lei,
			TVA_11=@tva_11 ,TVA_22=@valtva_lei,
			Valuta=(case when @valuta is not null then @valuta else valuta end),
			Curs=(case when isnull(@valuta,'')<>'' then @curs else 0 end),
			Valoare_valuta=@valoare_valuta,
			Achitat=@achitat_lei,
			Sold=@sold_lei,
			Cont_de_tert=(case when @cont is not null then @cont else Cont_de_tert end),
			Achitat_valuta=@achitat_valuta,
			Sold_valuta=@sold_valuta,
			Comanda=(case when @ComandaDeScris is not null then @ComandaDeScris else Comanda end),
			Data_ultimei_achitari=@data_ultimei_achitari
		WHERE Subunitate=@Sub and tip=(case @tiptert when 'B' then 0x46 when 'F' then 0x54 else 0 end)
			and Factura=@o_factura and tert=@o_tert
	end
	else
	begin
		INSERT INTO factimpl ([Subunitate] ,[Loc_de_munca] ,[Tip] ,[Factura],[Tert],[Data] ,[Data_scadentei],
			[Valoare],[TVA_11],[TVA_22],[Valuta],[Curs],[Valoare_valuta],
			[Achitat],[Sold] ,[Cont_de_tert],[Achitat_valuta] ,
			[Sold_valuta],[Comanda] ,[Data_ultimei_achitari])
		SELECT
			@sub,isnull(@lm,''),(case @tiptert when 'B' then 0x46 when 'F' then 0x54 else 0 end), @factura,@Tert,@Data,@Data_scadentei,
			@valoare_lei,@TVA_11, @TVA_22, isnull(@Valuta,''),@Curs,@valoare_valuta,
			@achitat_lei,@sold_lei,@Cont,@achitat_valuta,
			@sold_valuta,@ComandaDeScris,@Data_ultimei_achitari
	end
	declare @docXML xml
	set @docXML='<row tiptert="'+RTRIM(@tiptert)+'"/>'
	exec wIaPozFactImpl @sesiune=@sesiune, @parXML=@docXML
end try
begin catch
	set @mesaj = '(wScriuPozFactImpl): '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
--select * from factimpl
--sp_help factimpl
