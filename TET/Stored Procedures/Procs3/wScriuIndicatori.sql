--***
/* Procedura apartine machetelor de configurare TB (categorii, indicatori )- adauga sau face update pe un indicator
verificand in cazul update existenta lui */

CREATE procedure  wScriuIndicatori  @sesiune varchar(50), @parXML XML
as
declare @update bit, @expresie varchar(4000), @codInd varchar(20), @denumire varchar(60),  @o_codInd varchar(20),
		@cuData varchar(5), @msgEroare varchar(500), @gaugeInvers varchar(1), @descriere varchar(3000)

begin try

	set @update = isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)
	set	@cuData = rtrim(isnull(@parXML.value('(/row/@cudata)[1]', 'varchar(5)'), ''))
	set	@denumire = rtrim(isnull(@parXML.value('(/row/@denumire)[1]', 'varchar(60)'), ''))
	set	@expresie = rtrim(isnull(@parXML.value('(/row/@expresie)[1]', 'varchar(4000)'), ''))
	set	@codInd = rtrim(isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), ''))
	set	@o_codInd = rtrim(isnull(@parXML.value('(/row/@o_cod)[1]', 'varchar(20)'), ''))
	set @gaugeInvers = rtrim(isnull(@parXML.value('(/row/@gaugeinvers)[1]', 'varchar(1)'), ''))
	set @descriere = rtrim(isnull(@parXML.value('(/row/@descriere)[1]', 'varchar(3000)'), ''))

	if (@update=0 or @codInd!=@o_codInd) and exists (select 1 from indicatori where cod_indicator=@codInd)
	begin
		select @o_codInd, @codInd
		select * from indicatori where cod_indicator=@codInd
		set @msgEroare = 'Indicatorul ('+@codInd+') este deja configurat!'
		RAISERROR(@msgEroare,16,1)
	end
	
	if @update=0
		insert into indicatori (Cod_Indicator,Denumire_Indicator,Expresia,Unitate_de_masura,Expresie,Descriere_expresie,Total,Modificat,Ordine_in_raport)
			values (@codInd, @denumire, @expresie, '','',@descriere,@gaugeInvers,1,@cuData )
	else
		if not exists (select 1 from indicatori where cod_indicator=@o_codInd)
		begin
			set @msgEroare = 'Nu exista indicatorul cu cod: '+@codInd
			RAISERROR(@msgEroare,16,1)
		end
		
		else 
			update indicatori set Cod_Indicator=@codInd, Denumire_Indicator=@denumire, Expresia=@expresie, Descriere_expresie=@descriere, 
					Ordine_in_raport=@cuData, Total= @gaugeInvers
				where Cod_Indicator= @o_codInd
			update compcategorii set Cod_Ind=@codInd where cod_ind=@o_codInd
			update colind set cod_indicator=@codInd where cod_indicator=@o_codInd
			update expval set cod_indicator=@codind where cod_indicator=@o_codInd
			
end try
begin catch
	set @msgEroare=ERROR_MESSAGE()+'(wScriuIndicatori)'
	raiserror(@msgEroare,11,1)

end catch
