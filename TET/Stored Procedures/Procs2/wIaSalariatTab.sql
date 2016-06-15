--***
CREATE procedure wIaSalariatTab @sesiune varchar(50), @parXML xml
as  
begin 
	declare @tip varchar(2), @marca varchar(6), @mesajeroare varchar(500), @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if @utilizator is null
		return -1
	select @tip=isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@marca=ISNULL(@parXML.value('(/row/@marca)[1]','varchar(6)'), '')

	select @tip as tip, rtrim(p.marca) as marca, rtrim(max(p.Nume)) as densalariat, 
		max(dbo.fVechimeAALLZZ(p.Vechime_totala)) as vechimetotala, max(ip.Vechime_la_intrare) as vechimelaintrare, max(ip.Vechime_in_meserie) as vechimeinmeserie
	from personal p 
		left outer join infopers ip on ip.marca=p.marca
	where p.Marca=@marca
	group by p.Marca
	for xml raw
end 
