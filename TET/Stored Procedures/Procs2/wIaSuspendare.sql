--***
CREATE procedure wIaSuspendare @sesiune varchar(50), @parXML xml
as  
begin try
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500)
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, 'SC' as subtip, 
		convert(decimal,l1.procent) as nrcrt, convert(char(10),l1.Data_inf,101) as datainceput, convert(char(10),l2.Data_inf,101) as datasf, convert(char(10),l3.Data_inf,101) as dataincetare, 
		rtrim(c.cod) as temeisusp, rtrim(c.descriere) as dentemeisusp, 
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then 'Activa' else 'Incetata' end) as staresusp, 
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then 0 else 1 end) as incetare,
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then '#000000' else '#808080' end) as culoare 
	from extinfop l1  
		left join CatalogRevisal c on l1.Val_inf=c.cod 
		left join extinfop l2 on l2.Marca=@marca and l2.Cod_inf='SCDATASF' and l2.procent=l1.procent
		left join extinfop l3 on l3.Marca=@marca and l3.Cod_inf='SCDATAINCET' and l3.procent=l1.procent
	where l1.marca=@marca and l1.Cod_inf='SCDATAINC' 
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()+' (wIaSuspendare)'
	raiserror(@mesajeroare,11,1)
end catch
