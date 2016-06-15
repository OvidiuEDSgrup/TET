--***
CREATE procedure wIaTipAutorizatie @sesiune varchar(50), @parXML xml
as  
begin try
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500)
	select	@tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),''),
			@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, 'TA' as subtip, 
		convert(decimal,l1.procent) as nrcrt, convert(char(10),l1.Data_inf,101) as datainceput, 
		convert(char(10),l2.Data_inf,101) as datasf, rtrim(l1.Val_inf) as tipautorizatie
	from extinfop l1  
		left join extinfop l2 on l2.Marca=@marca and l2.Cod_inf='AUTDATASF' and l2.procent=l1.procent 
	where l1.marca=@marca and l1.Cod_inf='AUTDATAINC' 
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
