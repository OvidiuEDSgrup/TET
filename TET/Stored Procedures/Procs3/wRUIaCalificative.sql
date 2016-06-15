--**
Create procedure wRUIaCalificative @sesiune varchar(50), @parXML XML
as
-- apelare procedura specifica daca aceasta exista.
if exists (select 1 from sysobjects where [type]='P' and [name]='wRUIaCalificativeSP')
begin 
	declare @returnValue int
	exec @returnValue = wRUIaCalificativeSP @sesiune, @parXML output
	return @returnValue
end

declare @filtruAn int, @utilizator char(10), @mesaj varchar(200)
begin try
	select @filtruAn = @parXML.value('(/row/@f_an)[1]', 'int')

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@Utilizator OUTPUT
	IF @Utilizator IS NULL
		RETURN -1
		
	select top 100 a.ID_Calificativ as id_calificativ, convert(char(4),year(a.Data_sfarsit)) as an, 
		convert(char(10),a.Data_inceput,101) as data_inceput, convert(char(10),a.Data_sfarsit,101) as data_sfarsit, 
		rtrim(a.Calificativ) as calificativ, rtrim(Nivel_realizare) as nivel_realizare, convert(decimal(8,2),a.Nota_inferioara) as nota_inf, convert(decimal(8,2),a.Nota_superioara) as nota_sup
	from RU_Calificative a 
	where (@filtruAn is null or year(a.Data_sfarsit)=@filtruAn)
	order by Data_inceput desc, Calificativ 
	for xml raw
end try

begin catch
	set @mesaj = '(wRUIaCalificative) '+ERROR_MESSAGE()
end catch
if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
