--***
create procedure wOPSchimbarePretTermene_p @sesiune varchar(50), @parXML xml 
as  
begin try
	declare @contract varchar(20),@sursa varchar(13),@mesaj varchar(500),@cod varchar(20),@dencod varchar(100),@densursa varchar(100),
		@pret_vechi float,@f_beneficiar varchar(13),@f_denbeneficiar varchar(50),@f_loc_munca varchar(13),@f_denloc_munca varchar(100),
		@tip varchar(2),@subtip varchar(2)

	select 
		@tip=ISNULL(@parXML.value('(/parametri/@tip)[1]', 'varchar(2)'), ''),	
		@subtip=ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), ''),	
		@cod=ISNULL(@parXML.value('(/row/row/@cod)[1]', 'varchar(20)'), ''),
		@pret_vechi=ISNULL(@parXML.value('(/row/row/@Tpret)[1]', 'float'), ''),
		@dencod=ISNULL(@parXML.value('(/row/row/@dencod)[1]', 'varchar(100)'), ''),
		@contract=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@f_beneficiar=ISNULL(@parXML.value('(/row/@tert)[1]', 'varchar(13)'), ''),
		@f_denbeneficiar=ISNULL(@parXML.value('(/row/@dentert)[1]', 'varchar(100)'), ''),
		@f_loc_munca=ISNULL(@parXML.value('(/row/@lm)[1]', 'varchar(13)'), ''),
		@f_denloc_munca=ISNULL(@parXML.value('(/row/@denlm)[1]', 'varchar(100)'), ''),
		@sursa=ISNULL(@parXML.value('(/row/row/@modplata)[1]', 'varchar(20)'), ''),
		@densursa=ISNULL(@parXML.value('(/row/row/@denmodplata)[1]', 'varchar(100)'), '')

	if  @tip='BF'and @subtip='PR' and isnull(@cod,'')='' or not exists (select cod from nomencl where cod=@cod)--mesaj de eroare dc. nu se selecteaza o pozitie
 			raiserror('wOPSchimbarePretTermene_p:Selectati o pozitie pentru modificare pret!',11,1)

	select CONVERT(decimal(17,5),@pret_vechi) pret, rtrim(@cod) cod_pret,rtrim(@dencod) f_dencod,RTRIM(@contract) f_contract,
		rtrim(@sursa) f_sursa,rtrim(@densursa) f_densursa, rtrim(@f_beneficiar) f_beneficiar, rtrim(@f_denbeneficiar) f_denbeneficiar,
		RTRIM(@f_loc_munca) f_loc_de_munca, RTRIM(@f_denloc_munca) f_denloc_de_munca
	for xml raw
end try	
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
