--***
create procedure wScriuRegistruSalariati @sesiune varchar(50), @parXML xml output
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrMarca varchar(3), @AtrMarca varchar(20), 
@tip char(2),@subtip char(2), @ptupdate int, @marca varchar(6), 
@numar_carnet varchar(20), @tip_act_identitate varchar(1), @IDNationalitate varchar(2), 
@cetatenie varchar(2), @nationalitate varchar(2), @permis_munca varchar(20), @mentiuni varchar(80),
@localitate varchar(6), @data_incheiere_contract datetime, @numar_contract_itm varchar(10),
@data_contract_itm datetime, @temei_incetare char(2), @text_temei_incetare char(2),
@detalii_contract varchar(80), @motiv_modificare varchar(2), @data_modificare datetime, @explicatii_modificare varchar(80),	
@data_validarii datetime, @mesaj varchar(254), @userasis varchar(20) 

select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrMarca = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrMarca = @PrefixAtrMarca + '@marca'

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

declare @iDoc int
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
begin try  

select @tip=tip, @subtip=subtip, @Marca=Marca, @numar_carnet=numar_carnet, @tip_act_identitate=tip_act_identitate, 
@cetatenie=cetatenie, @IDNationalitate=IDNationalitate, @nationalitate=nationalitate, @permis_munca=permis_munca, @mentiuni=mentiuni, @localitate=localitate,
@data_incheiere_contract=data_incheiere_contract, @numar_contract_itm=numar_contract_itm, @data_contract_itm=data_contract_itm, 
@temei_incetare=temei_incetare, @text_temei_incetare=text_temei_incetare, @detalii_contract=detalii_contract,
@motiv_modificare=motiv_modificare, @data_modificare=data_modificare, @explicatii_modificare=explicatii_modificare, @data_validarii=data_validarii,
@ptupdate=isnull(ptupdate,0) 
from  OPENXML(@iDoc, @RowPattern)
WITH 
	(
		tip char(2) '../@tip', 
		subtip char(2) '@subtip', 
		Marca varchar(6) '../@marca',
		numar_carnet varchar(20) '@nrscarnet',
		tip_act_identitate varchar(1) '@tipactident',
		cetatenie varchar(2) '@cetatenie',
		IDNationalitate varchar(2) '@idnationalitate',
		nationalitate varchar(2) '@nationalitate',
		permis_munca varchar(20) '@permismunca',
		mentiuni varchar(80) '@mentiuni',
		localitate varchar(6) '@localitate',
		data_incheiere_contract datetime '@datainchcntr',
		numar_contract_itm varchar(10) '@nrcntritm',
		data_contract_itm datetime '@datacntritm',
		temei_incetare char(2) '@temeiincet',
		text_temei_incetare char(2) '@texttemei',
		detalii_contract varchar(80) '@detaliicntr',
		motiv_modificare varchar(2)	'@motivmodif',	
		data_modificare datetime '@datamodif',	
		explicatii_modificare varchar(80) '@explmodif',	
		data_validarii datetime '@datavalid',
		ptupdate int '@update'
	)
exec sp_xml_removedocument @iDoc 

if @numar_carnet is not null
	exec scriuExtinfop @Marca, 'NRSCARNET', @numar_carnet, '01/01/1901', 0, 2
if @tip_act_identitate is not null
	exec scriuExtinfop @Marca, 'TIPACTIDENT', @tip_act_identitate, '01/01/1901', 0, 2
if @cetatenie is not null
	exec scriuExtinfop @Marca, 'CETATENIE', @cetatenie, '01/01/1901', 0, 2
if @IDnationalitate is not null
	exec scriuExtinfop @Marca, 'NATIONALITATE', @IDnationalitate, '01/01/1901', 0, 2
if @nationalitate is not null
	exec scriuExtinfop @Marca, 'CODNATIONAL', @nationalitate, '01/01/1901', 0, 2
if @permis_munca is not null
	exec scriuExtinfop @Marca, 'PERMISMUNCA', @permis_munca, '01/01/1901', 0, 2
if @mentiuni is not null
	exec scriuExtinfop @Marca, 'MENTIUNI', @mentiuni, '01/01/1901', 0, 2
if @localitate is not null
	exec scriuExtinfop @Marca, 'CODSIRUTA', @localitate, '01/01/1901', 0, 2
if @data_incheiere_contract is not null
	exec scriuExtinfop @Marca, 'DATAINCH', '', @data_incheiere_contract, 0, 2
if @numar_contract_itm is not null or @data_contract_itm is not null
	exec scriuExtinfop @Marca, 'CNTRITM', @numar_contract_itm, @data_contract_itm, 0, 2
if @temei_incetare is not null
	exec scriuExtinfop @Marca, 'TEMEIINCET', @temei_incetare, '01/01/1901', 0, 2
if @text_temei_incetare is not null
	exec scriuExtinfop @Marca, 'TXTTEMEIINCET', @text_temei_incetare, '01/01/1901', 0, 2
if @detalii_contract is not null
	exec scriuExtinfop @Marca, 'CONTRDET', @detalii_contract, '01/01/1901', 0, 2
if @motiv_modificare is not null
	exec scriuExtinfop @Marca, 'MMODIFCNTR', @motiv_modificare, @data_modificare, 0, 2
if @explicatii_modificare is not null
	exec scriuExtinfop @Marca, 'MODIFEXPL', @explicatii_modificare, '01/01/1901', 0, 2
if @data_validarii is not null
	exec scriuExtinfop @Marca, 'DATAVALID', '', @data_validarii, 0, 2
end try  
begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
