--***
/* descriere... */
create procedure [dbo].[wOPModificareAntetCon](@sesiune varchar(50), @parXML xml) 
as     
begin
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @termen datetime, @lm char(9),
	@valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5), 
	@sub char(9),@TermPeSurse int, @userASiS varchar(20), 
	@stare char(1), @subtip char(2), @contractcor varchar(20),@responsabil varchaR(50),
	@eroare xml, @utilizator char(10),@contclient varchar(20),@procpen float,@update int, @nr int, @scadenta int , @periodicitate int,@mesaj varchar(200),
	@contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),
	@n_contract varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2)
        
begin try
--exec luare_date_par 'UC', 'POZSURSE', @TermPeSurse output, 0, ''
	
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT
	
declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
select @tip=tip, @contract=[contract], @data=data,
    @gestiune=gestiune_antet,
	@gestiune_primitoare=gestiune_primitoare, 
	@tert=(case when isnull(tert, '')<>'' then tert when tip in ('BF', 'BK', 'BP') then ''/*@clientProprietate*/ else '' end), 
	@stare=stare,
	@punct_livrare=punct_livrare,
	@factura=factura, 
	@contractcor=contractcor, 	
	
	--extcon
	@contclient=contclient ,
	@procpen=procpen,
	@contr_cadru=contr_cadru,
	@ext_camp4=ext_camp4,
	@ext_camp5=ext_camp5,
	@ext_modificari=ext_modificari ,
	@ext_clauze=ext_clauze,
	
	@termen=termen_antet, 
	@subtip=subtip , 
	@scadenta=scadenta,
	
	@valuta=valuta, 
	@curs= curs,
	@explicatii= explicatii, 
	@discount= discount,
	@responsabil =responsabil,
	@lm=lm,
	
	@n_contract =n_contract,
	@n_tert= n_tert,
	@n_data= n_data,
	@n_tip= n_tip
	
		
	from OPENXML(@iDoc, '/parametri') 
	WITH 
	(
		tip char(2) '@tip', 
		[contract] char(20) '@numar',
		data datetime '@data',
		gestiune_antet char(9) '@gestiune',
		gestiune_primitoare char(13) '@gestprim', 
		tert char(13) '@tert',
		stare char(13) '@stare',
		punct_livrare char(5) '@punctlivrare', 
		factura char(20) '@factura',
		contractcor varchar(20) '@contractcor',
		
		--extcon
		contclient varchar(10) '@contclient',
		procpen varchar(10) '@procpen',
		contr_cadru varchar(50) '@contr_cadru',
		ext_camp4 varchar(50) '@ext_camp4',
		ext_camp5 datetime '@ext_camp5',
		ext_modificari varchar(50) '@ext_modificari',
		ext_clauze varchar(500)'@ext_clauze',
		
		
		termen_antet datetime '@termen',
		subtip char(2) '@subtip',
		scadenta int '@scadenta', 
		
		lm char(9) '@lm',
		explicatii char(50) '@explicatii', 
		
		valuta char(3) '@valuta', 
		curs float '@curs', 
		discount float '@discount', 
		responsabil varchar(20) '@info6',
		
		n_contract varchar(20)'@n_contract',
		n_tert varchar(13)'@n_tert',
		n_data datetime '@n_data',
		n_tip varchar(2) '@n_tip'
	) 
if @stare<>0 raiserror('Nu sunteti in starea de operabilitate, nu aveti dreptul de modificare antet!',16,1)
if exists(select 1 from con where tip='BK' and Contract_coresp=@contract) and ( @contract<>@n_contract or @data<>@n_data or @tert<>@n_tert or @tip<>@n_tip)
	raiserror ('    Pe baza acestui contract au fost genearate comenzi de livrare prin urmare data,nr. contractului si tertul nu mai pot fi modificate!!,',11,1)
		
	if not exists (select 1 from terti where tert=@n_tert)
		raiserror('     Tertul introdus nu exista in baza de date!!',11,1)
	if not exists (select 1 from conturi where cont=@contclient) and ISNULL(@contclient,'')<>'' --or not exists (select 1 from conturi where cont=@cont_stoc)
		raiserror('     Contul introdus nu exista in baza de date!!',11,1)	
					
	
	UPDATE con SET 
		[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else tert end),
		[Punct_livrare] =case when @punct_livrare is not null then @punct_livrare else Punct_livrare end,
		[Data] =case when  @n_data is not null then @n_data else data end ,
		[Loc_de_munca] =case when @lm is not null then @lm else Loc_de_munca end,
		[Gestiune] =case when @gestiune is not null then @gestiune else Gestiune end,
		[Termen] =case when @termen is not null then @termen else termen end,
		[Scadenta] =case when @scadenta is not null then @scadenta else Scadenta end ,
		[Discount] = case when @discount is not null then @discount else Discount end ,
		[Valuta] =case when @valuta is not null then @valuta else valuta end,
		[Curs] = case when @curs is not null then @curs else curs end,
		[Factura] =case when @factura is not null then @factura else Factura end ,
		[Contract_coresp] = case when @contractcor is not null then @contractcor else Contract_coresp end ,
		[Procent_penalizare] =case when  @procpen is not null then @procpen else Procent_penalizare end,
		[Responsabil] =case when  @responsabil is not null then @responsabil else Responsabil end ,
		[Explicatii] = case when @explicatii is not null then @explicatii else Explicatii end ,
		[Cod_dobanda]=case when @gestiune_primitoare is not null then @gestiune_primitoare else Cod_dobanda end 
    WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data 
	
	update pozcon set 
		[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else tert end), 
		[Data] =case when  @n_data is not null then @n_data else data end ,
		[Punct_livrare] =case when @punct_livrare is not null then @punct_livrare else Punct_livrare end, 
		[Termen] =case when @termen is not null then @termen else termen end
	WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data 
	
	
	if not exists(select 1 from extcon WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data)
	   and (ISNULL(@ext_camp4,'')<>'' or ISNULL(@ext_camp5,'')<>'' or ISNULL(@ext_modificari,'')<>'' or ISNULL(@contr_cadru,'')<>'' or ISNULL(@contclient,'')<>''
	        or ISNULL(@ext_clauze,'')<>'' or ISNULL(@procpen,'')<>'' )									
		insert extcon 
		     (Subunitate,Tip,Contract,Tert,Data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,
		     Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,Utilizator,Data_operarii,Ora_operarii)
		     
		     select 1,@tip, @contract , @tert, @data,1,'','','',isnull(@ext_clauze,''),isnull(@ext_modificari,''),'',isnull(@contclient,''),isnull(@procpen,''),isnull(@contr_cadru,''),
					isnull(@ext_camp4,''),isnull(@ext_camp5,''),isnull(@utilizator,''), convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
	else	     
		update extcon set 
			[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
			[Tert] =(case when  @n_tert is not null then @n_tert else tert end), 
			[Data] =case when  @n_data is not null then @n_data else data end ,
			[Camp_4]=case when @ext_camp4 is not null then @ext_camp4 else Camp_4 end,
			[Camp_5]=case when @ext_camp5 is not null then @ext_camp5 else Camp_5 end,
			[Modificari]=case when @ext_modificari is not null then @ext_modificari else Modificari end,
			[Camp_3]=case when @contr_cadru is not null then @contr_cadru else Camp_3 end,
			[Camp_1]=case when @contclient is not null then @contclient else Camp_1 end,
			[Clauze_speciale]=case when @ext_clauze is not null then @ext_clauze else Clauze_speciale end,
			[Camp_2]=case when @procpen is not null then @procpen else Camp_2 end
		WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data 
	
	
	update termene set 
		[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else tert end), 
		[Data] =case when  @n_data is not null then @n_data else data end
	WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data 
	
select 'Datele de pe antet au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
