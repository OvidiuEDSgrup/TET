create procedure wIaGP @sesiune varchar(50), @parXML xml  
as   
declare @f_dentert varchar(20), @f_nrordin varchar(20),@f_datajos datetime,@f_datasus datetime,@tip varchar(2),@tert varchar(20), @data datetime,
		@nrdoc varchar(20), @f_nrdoc varchar(20),@subtip varchar(10),@_cautare varchar(50)
  
select @f_nrdoc=ISNULL(@parXML.value('(/row/@f_nrdoc)[1]', 'varchar(20)'), ''),  
	   @f_datajos=ISNULL(@parXML.value('(/row/@datajos)[1]', 'varchar(20)'), '1901-01-01'),  
	   @f_datasus=ISNULL(@parXML.value('(/row/@datasus)[1]', 'varchar(20)'), '2999-01-01'),  
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
	   @data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '1901-01-01'),
	   @nrdoc=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
       @subtip=ISNULL(@parXML.value('(/row/@subtip)[1]', 'varchar(20)'), ''),
       @_cautare=ISNULL(@parXML.value('(/row/@_cautare)[1]', 'varchar(20)'), '')
       	
select  distinct RTRIM(gp.Numar_document) as numar,  
			    RTRIM(@tip) as tip,
			     rtrim('G') as subtip,  
                convert(char(10),gp.Data,101) as data,
				(select COUNT (g.Factura) from generareplati g where g.Numar_document=gp.Numar_document) as pozitii,
				max(RTRIM(gp.stare)) as stare,
				rtrim(sum(gp.val1)) as valoare,
				max(case gp.Stare	when '1' then 'OP Generat' 
									when '2' then 'PF Generat' when '0' then 'Operabil' else 'In Lucru ' end) as denstare,
				max(case when gp.stare='1' then 'blue' when gp.stare='2' then '#808080' end ) as culoare,
				--max(case when gp.stare='2' then 1 else 0 end) as _nemodificabil,
				RTRIM(@_cautare) AS _cautare
				
	from generareplati gp  
	where gp.Data between @f_datajos and @f_datasus	
	and gp.Numar_document like '%'+@f_nrdoc+'%'
	and (gp.Numar_document=@nrdoc or @nrdoc='' )
	and (gp.Data=@data or @data='1901-01-01')
	group by gp.Numar_document, gp.Data--, gp.stare
    order by numar
	for xml raw


