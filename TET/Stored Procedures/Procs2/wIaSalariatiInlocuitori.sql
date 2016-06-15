--***
CREATE procedure wIaSalariatiInlocuitori @sesiune varchar(50), @parXML xml
as  
begin try
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500)
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, 'SN' as subtip,  
		convert(decimal,e1.procent) as nrcrt, convert(char(10),e1.Data_inf,101) as datainceput, convert(char(10),e2.Data_inf,101) as datasfarsit, 
		rtrim(e1.Val_inf) as marcainloc, rtrim(p.Nume) as densalinloc, rtrim(e2.Val_inf) as motiv, 
		(case when e2.Data_inf>getdate() then '#000000' else '#808080' end) as culoare 
	from extinfop e1
		left join extinfop e2 on e2.Marca=@marca and e2.Cod_inf='SALINLOCSF' and e2.procent=e1.procent
		left outer join personal p on p.Marca=e1.Val_inf
	where e1.marca=@marca and e1.Cod_inf='SALINLOCIN' 
	for xml raw
end try

begin catch
	set @mesajeroare='(wIaSalariatiInlocuitori) '+ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
