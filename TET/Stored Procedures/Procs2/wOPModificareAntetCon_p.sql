--***
create procedure [dbo].[wOPModificareAntetCon_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare @tip char(2), @contract char(20), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @termen datetime, @lm char(9),
	@valuta char(3), @curs float, @explicatii char(50), @discount float, @punct_livrare char(5), 
	@sub char(9),@TermPeSurse int, @userASiS varchar(20), @mesaj varchar(200),
	@stare char(1), @subtip char(2), @contractcor varchar(20),@responsabil varchaR(50),
	@eroare xml, @utilizator char(10),@contclient varchar(20),@procpen varchar(10),@update int, @nr int, @scadenta int ,
	@contr_cadru varchar(50),@ext_camp4 varchar(50),@ext_camp5 datetime,@ext_modificari varchar(50),@ext_clauze varchar(500),
	@n_contract varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2)

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select @tip=tip, @contract=rtrim([contract]), @data=data,
    @gestiune=isnull(rtrim(gestiune_antet), ''),
	@gestiune_primitoare=isnull(rtrim(gestiune_primitoare), '') , 
	@tert=rtrim(tert),
	@punct_livrare=isnull(rtrim(punct_livrare), ''),
	@factura=isnull(rtrim(factura), '') , 
	@contractcor=isnull(rtrim(contractcor), ''), 	
	
	--extcon
	@contclient=isnull(rtrim(contclient),'') ,
	@procpen=isnull(procpen,''),
	@contr_cadru=isnull(rtrim(contr_cadru),''),
	@ext_camp4=isnull(rtrim(ext_camp4),''),
	@ext_camp5=isnull(ext_camp5,'1901-01-01'),
	@ext_modificari=isnull(rtrim(ext_modificari),'') ,
	@ext_clauze=isnull(rtrim(ext_clauze),''),
	
	@termen=isnull(termen_antet, data), 
	@subtip=isnull(subtip, tip) , 
	@scadenta=isnull(scadenta,0),
	
	@valuta= isnull(rtrim(valuta), '') , 
	@curs= isnull(curs, 0),
	@explicatii= isnull(rtrim(explicatii),''), 
	@discount= discount,
	@responsabil =ISNULL(rtrim(responsabil),''),
	@lm=ISNULL(rtrim(lm),'')	,
	
	----datele care mi le trimit la operatie-----
	@n_tip=tip, @n_contract=[contract], 
	@n_data=data,@n_tert=tert
		
	from OPENXML(@iDoc, '/row') 
	WITH 
	(
		tip char(2) '@tip', 
		[contract] char(20) '@numar',
		data datetime '@data',
		gestiune_antet char(9) '@gestiune',
		gestiune_primitoare char(13) '@gestprim', 
		tert char(13) '@tert',
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
		responsabil varchar(20) '@info6'
		
	) 
		
if @update=1
	return

if exists(select 1 from con where tip='BK' and Contract_coresp=@contract)
select '    Pe baza acestui contract au fost genearate comenzi de livrare prin urmare data,nr. contractului si tertul nu mai pot fi modificate!!,' as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')
		
select @tip tip, rtrim(@contract) numar, convert(char(10),@data,101) data , rtrim(@gestiune) gestiune, rtrim(@gestiune_primitoare) gestprim,rtrim(@tert) tert, rtrim(@factura) factura , @termen termen_antet,
	 rtrim(@lm) lm,rtrim(@valuta) valuta, @curs curs, rtrim(@explicatii) explicatii, @discount discount, rtrim(@punct_livrare) punctlivrare, rtrim(@n_contract) n_contract,
	 @sub subunitate , @subtip subtip,rtrim(@contractcor) contractcor,rtrim(@responsabil) info6,rtrim(@contclient) contclient,@procpen procpen, @scadenta scadenta , 
	 rtrim(@contr_cadru) contr_cadru,rtrim(@ext_camp4) ext_camp4,rtrim(@ext_camp5) ext_camp5,rtrim(@ext_modificari) ext_modificari,rtrim(@ext_clauze) ext_clauze,
	 rtrim(@n_tert) n_tert,convert(char(10),@n_data,101) n_data,@n_tip n_tip
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
