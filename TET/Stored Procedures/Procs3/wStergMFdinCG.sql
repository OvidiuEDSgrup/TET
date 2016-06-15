--***
create procedure wStergMFdinCG @sesiune varchar(50), @parXML xml output
as

declare @userAsis varchar(13), @subunitate varchar(9), @tip varchar(2), @subtip varchar(2),
		@numar varchar(20), @data datetime, @gestiune varchar(9), @gestiunePrim varchar(9), @nrinv varchar(20), @eroare xml

begin try
	exec wValidareMFdinCG @sesiune, @parXML

	select
		@subunitate=isnull(@parXML.value('(/row/@subunitate)[1]','varchar(9)'), ''),
		@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'), ''),
		@subtip=isnull(@parXML.value('(/row/row/@subtip)[1]','varchar(2)'), ''),
		@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'), ''),
		@data=isnull(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01'),
		@gestiune=isnull(@parXML.value('(/row/@gestiune)[1]', 'varchar(9)'), ''),
		@gestiunePrim=isnull(@parXML.value('(/row/@gestprim)[1]', 'varchar(9)'), '')
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

	if @tip in ('RM','RF','RA') and @subtip in ('MF','MM')
	begin
		declare @parXMLMF xml
		set @nrinv=isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(13)'),'')
		
		set @parXMLMF=(select @subunitate as '@sub', (case when @subtip='MF' then 'MI' when @subtip='MM' then 'MM' end) as '@tip', 
			(case when @subtip='MF' then 'AF' when @subtip='MM' then 'FF' end) as '@subtip', 
			@numar as '@numar', @data as '@data', @nrinv as '@nrinv', dbo.EOM(@data) as '@datal', 
			(select @numar as '@numar', @data as '@data', @nrinv as '@nrinv', 1 as '@farapozdoc' for XML path,type) 
			for XML path,type) 
		exec wStergPozdocMF @sesiune, @parXMLMF
	end

	if @tip='TE'
	begin	
		if @subtip='TE' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiunePrim),'')='I'
		begin
			set @nrinv=isnull(@parXML.value('(/row/row/@codiprimitor)[1]', 'varchar(13)'),'')

			delete from mismf where	subunitate=@subunitate and Data_lunii_de_miscare=dbo.EOM(@data) and Tip_miscare='IAL' and Numar_de_inventar=@nrinv and Numar_document=@numar
			delete from fisamf where subunitate=@subunitate and Numar_de_inventar=@nrinv and Data_lunii_operatiei=dbo.EOM(@data) and Felul_operatiei in ('1','3')
			delete from mfix where subunitate in (@subunitate,'DENS') and Numar_de_inventar=@nrinv 
		end
	
		if @subtip='TR' and isnull((select tip_gestiune from gestiuni where Subunitate=@subunitate and Cod_gestiune=@gestiune),'')='I'
		begin
			set @nrinv=isnull(@parXML.value('(/row/row/@codintrare)[1]', 'varchar(13)'),'')

			delete from mismf where	subunitate=@subunitate and Data_lunii_de_miscare=dbo.EOM(@data) and Tip_miscare in ('EAE','MEP') and Numar_de_inventar=@nrinv and Numar_document=@numar
			delete from fisamf where subunitate=@subunitate and Numar_de_inventar=@nrinv and Data_lunii_operatiei=dbo.EOM(@data) and Felul_operatiei in ('4','5')
			update fisamf 
			set Valoare_de_inventar=f.Valoare_de_inventar, Valoare_amortizata=f.Valoare_amortizata+f.Amortizare_lunara, cantitate=f.cantitate
			from fisamf, fisamf f 
				where f.Subunitate=fisamf.Subunitate and f.Numar_de_inventar=fisamf.Numar_de_inventar and f.Data_lunii_operatiei=dbo.EOM(DateADD(month,-1,fisamf.Data_lunii_operatiei)) and f.Felul_operatiei='1'
					and fisamf.subunitate=@subunitate and fisamf.Numar_de_inventar=@nrinv and fisamf.Data_lunii_operatiei=dbo.EOM(@data) and fisamf.Felul_operatiei='1'
		end
	end
	
end try
begin catch
	declare @mesaj varchar(255)
	set @mesaj=ERROR_MESSAGE()+' (wStergMFdinCG)'
	raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
