--***
/* descriere... */
create procedure [dbo].[yso_wOPModificareAntetCon](@sesiune varchar(50), @parXML xml) 
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

--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	
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
					
--/*sp
	declare @info5 float, @modifdiscpoz int
	set @info5=isnull(@parXML.value('(/*/@info5)[1]','float'),0)
	set @modifdiscpoz=isnull(@parXML.value('(/*/@modifdiscpoz)[1]','int'),0)
--sp*/
--/*sp
	UPDATE con SET --sp*/ select 
		[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else tert end),
		[Punct_livrare] =case when @punct_livrare is not null then @punct_livrare else Punct_livrare end,
		[Data] =case when  @n_data is not null then @n_data else data end ,
		[Loc_de_munca] =case when @lm is not null then @lm else Loc_de_munca end,
		[Gestiune] =case when @gestiune is not null then @gestiune else Gestiune end,
		[Termen] =case when @termen is not null then @termen else termen end,
		[Scadenta] =case when @scadenta is not null then @scadenta else Scadenta end ,
		--/*sp [Discount] = case when @discount is not null then @discount else Discount end ,
		[Discount] = case when  @info5 is not null then @info5 else Discount end ,--sp*/
		[Valuta] =case when @valuta is not null then @valuta else valuta end,
		[Curs] = case when @curs is not null then @curs else curs end,
		[Factura] =case when @factura is not null then @factura else Factura end ,
		[Contract_coresp] = case when @contractcor is not null then @contractcor else Contract_coresp end ,
		[Procent_penalizare] =case when  @procpen is not null then @procpen else Procent_penalizare end,
		[Responsabil] =case when  @responsabil is not null then @responsabil else Responsabil end ,
		[Explicatii] = case when @explicatii is not null then @explicatii else Explicatii end ,
		[Cod_dobanda]=case when @gestiune_primitoare is not null then @gestiune_primitoare else Cod_dobanda end 
	from con 
    WHERE Subunitate='1' and tip=@tip and Contract=@contract and tert=@tert and data=@data 

--/*sp 
	update pozcon set --sp*/ select d.*,n.Grupa,c.*,p.*,
		[Contract] = (case when @n_contract is not null then @n_contract else p.Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else p.tert end), 
		[Data] =case when  @n_data is not null then @n_data else p.data end ,
		[Factura] =case when @gestiune is not null then @gestiune else p.Factura end,
		[Punct_livrare] =case when @gestiune_primitoare is not null then @gestiune_primitoare else p.Punct_livrare end, 
		[Termen] =case when @termen is not null then @termen else p.termen end
		--verific daca gest prim a fost sau va fi in A,V cand pretul este de amanunt;
		,Pret=/*case when isnull(gpn.Tip_gestiune,'') in ('A','V') or isnull(gpo.Tip_gestiune,'') in ('A','V') 
						and isnull(gpn.Tip_gestiune,'')<>isnull(gpo.Tip_gestiune,'') then 
				case when isnull(gpn.Tip_gestiune,'') in ('A','V') then p.Pret*(1+p.Cota_TVA/100)
					when isnull(gpo.Tip_gestiune,'') in ('A','V') then p.Pret/(1+p.Cota_TVA/100) 
					else p.pret end
			else*/ p.Pret 
		,[Discount] = case when isnull(@modifdiscpoz,0)=1 then 
				case when isnull(@info5,0)<>0 then @info5 else isnull(d.Discount,0) end 
			else p.Discount end 
	from pozcon p 
		left join con c on c.Subunitate=p.Subunitate and c.Tip=p.Tip and c.Contract=p.Contract and c.Data=p.Data
			and p.tert=(case when @n_tert is not null then p.tert else c.tert end)
		left join nomencl n on n.Cod=p.Cod
		left join gestiuni gpo on gpo.Cod_gestiune=p.Punct_livrare
		left join gestiuni gpn on gpn.Cod_gestiune=@gestiune_primitoare
		outer apply (select top 1 * from pozcon pc where pc.Subunitate=c.Subunitate AND pc.tip='BF' AND pc.Contract=c.Contract_coresp 
				AND pc.Tert=(case when @n_tert is not null then @n_tert else c.tert end)	
				and pc.Mod_de_plata='G' and n.Grupa like RTRIM(pc.Cod)+'%' 
			order by pc.Cod desc, pc.Discount desc) d
--sp*/
	WHERE p.Subunitate='1' and p.tip=@tip and p.Contract=@contract and p.tert=@tert and p.data=@data 
	
	
	if not exists(select 1 from extcon WHERE Subunitate=1 and tip=@tip and Contract=@contract and tert=@tert and @data=@data)
	   and (ISNULL(@ext_camp4,'')<>'' or ISNULL(@ext_camp5,'')<>'' or ISNULL(@ext_modificari,'')<>'' or ISNULL(@contr_cadru,'')<>'' or ISNULL(@contclient,'')<>''
	        or ISNULL(@ext_clauze,'')<>'' or ISNULL(@procpen,'')<>'' )									
		insert extcon 
		     (Subunitate,Tip,Contract,Tert,Data,Numar_pozitie,Precizari,Clauze_speciale,Modificari,Data_modificari,Descriere_atasament,
		     Atasament,Camp_1,Camp_2,Camp_3,Camp_4,Camp_5,Utilizator,Data_operarii,Ora_operarii)
		     
		     select 1,@tip, @contract , @tert, @data,1,'','','',isnull(@ext_clauze,''),isnull(@ext_modificari,''),'',isnull(@contclient,''),isnull(@procpen,''),isnull(@contr_cadru,''),
					isnull(@ext_camp4,''),isnull(@ext_camp5,''),isnull(@utilizator,''), convert(datetime, convert(char(10), getdate(), 104), 104), 
					RTrim(replace(convert(char(8), getdate(), 108), ':', ''))
	else --/*sp     
		update extcon set --sp*/ select
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
		from extcon
		WHERE Subunitate='1' and tip=@tip and Contract=@contract and tert=@tert and data=@data 
	
	update termene set 
		[Contract] = (case when @n_contract is not null then @n_contract else Contract end) ,
		[Tert] =(case when  @n_tert is not null then @n_tert else tert end), 
		[Data] =case when  @n_data is not null then @n_data else data end
	WHERE Subunitate='1' and tip=@tip and Contract=@contract and tert=@tert and data=@data 
	
select 'Datele de pe antet au fost modificate.' as textMesaj, 'Finalizare operatie' as titluMesaj 
		for xml raw, root('Mesaje')
    end try
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch	
end
