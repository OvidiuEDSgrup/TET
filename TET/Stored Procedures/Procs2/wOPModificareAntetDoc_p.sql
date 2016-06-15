--***
create procedure [dbo].[wOPModificareAntetDoc_p] @sesiune varchar(50), @parXML xml 
as  
begin try
declare  @tip char(2), @numar char(8), @data datetime, @gestiune char(9), @gestiune_primitoare char(13), 
	@tert char(13), @factura char(20), @data_facturii datetime, @data_scadentei datetime, @lm char(9), 
	@cota_TVA float,@tipTVA int, @comanda char(20), @cont_stoc varchar(40),
	@valuta char(3), @curs float, @contract char(20),@n_numar varchar(20),@n_tert varchar(13),@n_data datetime,@n_tip varchar(2),
	@explicatii char(30), @cont_factura varchar(40), @discount float, @punct_livrare char(5), @subtip varchar(2),
	@cont_corespondent varchar(40),@categ_pret int,@cont_venituri varchar(40), @TVAnx float, @update bit,@dencontstoc varchar(50),
	@sub char(9),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3),
	@categPretProprietate varchar(20), @stare int,	@eroare xml, @mesaj varchar(254), @Bugetari int,  @indbug varchar(20),@NrAvizeUnitar int 

declare @iDoc int
	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
select 
		
	@n_numar =ISNULL(n_numar,''),
	@n_tert= ISNULL(n_tert,''),
	@n_data= ISNULL(n_data,''),
	@n_tip= ISNULL(n_tip,'')
	 
	from OPENXML(@iDoc, '/row') 
	WITH 
	(		
		n_numar varchar(20)'@numar',
		n_tert varchar(13)'@tert',
		n_data datetime '@data',
		n_tip varchar(2) '@tip'
		
	)
exec sp_xml_removedocument @iDoc 	
set @cont_stoc=(select min(cont_de_stoc) from pozdoc where Numar=@n_numar and data=@n_data and tert=@n_tert and tip=@n_tip)	
set @dencontstoc=rtrim(@cont_stoc)+'-'+(select Denumire_cont from conturi where cont=@cont_stoc)
if @update=1
	return

/*if exists(select 1 from doc where tip='BK' and Contract_coresp=@contract)
select '    Pe baza acestui contract au fost genearate comenzi de livrare prin urmare data,nr. contractului si tertul nu mai pot fi modificate!!,' as textMesaj, 'Mesaj avertizare' as titluMesaj 
		for xml raw, root('Mesaje')*/
		
select  rtrim(@n_tert) n_tert,convert(char(10),@n_data,101) n_data,@n_tip n_tip,rtrim(@n_numar) n_numar,RTRIM(@cont_stoc) cont_stoc,rtrim(@dencontstoc) dencontstoc
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
