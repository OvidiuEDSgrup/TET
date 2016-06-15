--***
CREATE procedure wIaDetasari @sesiune varchar(50), @parXML xml
as  
begin try
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500)
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'),''),
		@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, 'DS' as subtip, 
		convert(decimal,l1.procent) as nrcrt, convert(char(10),l1.Data_inf,101) as datainceput, convert(char(10),l2.Data_inf,101) as datasf, 
		rtrim(l1.Val_inf) as cuiang, rtrim(l2.Val_inf) as nume_ang, rtrim(l3.Val_inf) as nationalitate, 
		convert(char(10),l3.Data_inf,101) as dataincetare,
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then 'Activa' else 'Incetata' end) as staredet, 
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then 0 else 1 end) as incetare, 
		(case when isnull(convert(char(10),l3.Data_inf,102),'')<='1901/01/01' then '#000000' else '#808080' end) as culoare 
	from extinfop l1  
		left join extinfop l2 on l2.Marca=@marca and l2.Cod_inf='DETDATASF' and l2.procent=l1.procent 
		left join extinfop l3 on l3.Marca=@marca and l3.Cod_inf='DETNATIONAL' and l3.procent=l1.procent
	where l1.marca=@marca and l1.Cod_inf='DETDATAINC' 
	for xml raw
end try

begin catch
	set @mesajeroare=ERROR_MESSAGE()
	raiserror(@mesajeroare,11,1)
end catch
