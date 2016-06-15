--***
CREATE function wfValidarePozplin (@document xml) returns xml
as begin
	declare @eroare xml,@subtip varchar(2),@efect varchar(20),@tert varchar(13),@data datetime,@tip varchar(2),@tipefect varchar(1)
	set @eroare='<error coderoare="0" msgeroare=""/>'
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@subtip)[1]', 'char(2)'), '') = ''
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Tip pozitie incorect"')
		set @eroare.modify ('insert attribute camp {"@subtip"} into (/error)[1]')
	end
	
	select @subtip = isnull(@document.value('(/row/row/@subtip)[1]', 'varchar(2)'), ''), 
		@tip = isnull(@document.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@efect = isnull(isnull(@document.value('(/row/row/@efect)[1]', 'varchar(20)'), @document.value('(/row/@efect)[1]', 'varchar(20)')),''), 
		@tipefect = ISNULL(@document.value('(/row/@tipefect)[1]','varchar(1)'), ''), 
		@tert = isnull(ISNULL(@document.value('(/row/row/@tert)[1]', 'varchar(13)'), @document.value('(/row/@tert)[1]', 'varchar(13)')),''),
		@data = @document.value('(/row/@data)[1]', 'datetime')
	
	if LEFT(@subtip,1)<>@tipefect and @tip='EF' and ISNULL(@tipefect,'')<>''-->validare constituire efect
	begin		
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Nu se pot pune si plati si incasari pe acelasi efect!"')
		set @eroare.modify ('insert attribute camp {"@efect"} into (/error)[1]')
	end
	
	if exists (select 1 from efecte where Subunitate='1' and Nr_efect=@efect and tert=@tert and LEFT(@subtip,1)<>tip) 
		and @subtip in ('IE','PE')-->validare plata/incasare efect
	begin		
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Nu se pot pune si plati si incasari pe acelasi efect!"')
		set @eroare.modify ('insert attribute camp {"@efect"} into (/error)[1]')
	end
	
	if @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@valuta)[1]', 'char(3)'), '')<>''
	and isnull(@document.value('(/row/row/@valuta)[1]', 'char(3)'), '') not in (select valuta from valuta)
	begin
		
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Valuta selectata este invalida!"')
		set @eroare.modify ('insert attribute camp {"@valuta"} into (/error)[1]')
	end
	-- validarea de mai jos trebuie sa fie "contul operat trebuie sa fie atribuit <Furnizor>" - deocamdata am scos-o
	else if 1=0 and @document.exist('/row/row')=1 and isnull(@document.value('(/row/row/@subtip)[1]', 'char(2)'), '') = 'PN' 
		and (isnull(@document.value('(/row/row/@contcorespondent)[1]', 'varchar(40)'), '') = '' 
		or isnull(@document.value('(/row/row/@contcorespondent)[1]', 'varchar(40)'), '') not like '401%')
	begin
		set @eroare.modify('replace value of (/error/@coderoare)[1]	with "1"')
		set @eroare.modify('replace value of (/error/@msgeroare)[1]	with "Alegeti un analitic al contului 401!"')
		set @eroare.modify ('insert attribute camp {"@contcorespondent"} into (/error)[1]')
	end
	
	return @eroare
end



--sp_help efecte
