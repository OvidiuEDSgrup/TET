--declare @sesiune varchar(30), @parXML XML 
--set @parXML=convert(xml,N'<row tert="11400355" dentert="MONDO INSTAL" codfiscal="11400355" localitate="BRASOV" denlocalitate="BRASOV" judet="BV" denjudet="BRASOV" tara="" dentara="" adresa="CODRUL COSMINULUI             56" strada="CODRUL COSMINULUI" numar="56" bloc="" scara="" apartament="" codpostal="" telefonfax="" banca="" denbanca="" continbanca="" decontarivaluta="0" grupa="4" dengrupa="INSTALATOR" contfurn="401.2" dencontfurn="Furnizori marfa intern" contben="411.1" dencontben="Clienti interni" datatert="01/31/2012" categpret="1" dencategpret="Lista-PVC15 Euro" soldmaxben="0.00" discount="0.00" termenlivrare="0" termenscadenta="0" reprezentant="" functiereprezentant="" lm="" denlm="" responsabil="" denresponsabil="" info1="" info2="" info3="" nrordreg="" tiptert="0" neplatitortva="0" nomspec="0" soldfurn="0.00" soldben="0.00" culoare="#808080" subcontractant="1" update="1" utilizator="OVIDIU" tipMacheta="C" codMeniu="T" tip="PT" TipDetaliere="PT" AIR="1" inXML="1">
--<row cod="11400355" codprop="SUBCONTRACTANT" descriere="SUBCONTRACTANT" valoare="33665" denvaloare="1" update="1" o_cod="11400355" o_codprop="SUBCONTRACTANT" o_descriere="SUBCONTRACTANT" o_valoare="1" o_denvaloare="1" o_update="1" tip="PT"/></row>')
--set @sesiune='8B6B8AD4685D5'
--***
CREATE procedure [dbo].[yso_wScriuProprietatiTerti]   @sesiune varchar(30), @parXML XML as
declare @tert varchar(13), @update bit, @valoare varchar(20), @descriere varchar(200), @codprop varchar(50), @denvaloare varchar(80)
	,@o_codprop varchar(20),@o_valoare varchar(20), @o_denvaloare varchar(80)
Select  @tert = @parXML.value('(/row/@tert)[1]','varchar(13)'),
		@update = isnull(@parXML.value('(/row/row/@update)[1]','bit'),0),
		@valoare = isnull(@parXML.value('(/row/row/@valoare)[1]','varchar(50)'),''),
		@codprop = isnull(@parXML.value('(/row/row/@codprop)[1]','varchar(50)'),''),
		@denvaloare = isnull(@parXML.value('(/row/row/@denvaloare)[1]','varchar(80)'),'')
Select @o_codprop= @parXML.value('(/row/row/@o_codprop)[1]','varchar(20)'),
		@o_valoare= isnull(@parXML.value('(/row/row/@o_valoare)[1]','varchar(20)'),''),
		@o_denvaloare= isnull(@parXML.value('(/row/row/@o_valoare)[1]','varchar(20)'),'')
begin try
	if @update=1
	begin
		update proprietati set Valoare=@valoare where tip='TERT' and cod=@tert and Cod_proprietate=isnull(@o_codprop,@codprop)
		if not exists (select 1 from valproprietati v where v.Cod_proprietate=isnull(@o_codprop,@codprop) and v.Valoare=@valoare)
			insert into valproprietati(cod_proprietate,valoare,descriere,valoare_proprietate_parinte) values (@codprop,@valoare,@denvaloare,'')
		end
	else
	begin
		if exists (select 1 from proprietati where tip='TERT' and cod=@tert and Cod_proprietate=@codprop)
			update proprietati set Valoare=@valoare where tip='TERT' and cod=@tert and Cod_proprietate=@codprop
		else
				insert into proprietati values('TERT',@tert,@codprop,@valoare,'')
				
		if not exists (select 1 from valproprietati v where v.Cod_proprietate=@codprop and v.Valoare=@valoare)
			insert into valproprietati(cod_proprietate,valoare,descriere,valoare_proprietate_parinte) values (@codprop,@valoare,@denvaloare,'')
	end
	
end try
begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
