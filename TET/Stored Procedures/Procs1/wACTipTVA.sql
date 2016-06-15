--***
create procedure wACTipTVA @sesiune varchar(50), @parXML XML
as
	declare @tip varchar(2), @subtip varchar(2)
	select @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''), 
		@subtip=ISNULL(@parXML.value('(/row/row/@subtip)[1]', 'varchar(2)'), '')
	
	select '0' as cod,(case when @tip in ('RM','RC','RS') then '0-TVA Deductibil' else '0-TVA Colectat' end) as denumire
	union all
	select '1' ,(case when @tip in ('RM','RC','RS') then '1-TVA Compensat' else '1-TVA Compensat' end) as denumire
	union all
	select '2' , (case when @tip in ('RM','RC','RS') then '2-TVA Nedeductibil' else '2-TVA Neinregistrat' end) as denumire
	union all
	select '3' , (case when @tip in ('RM','RC','RS','FF') or @tip='RE' and @subtip='PC' then '3-TVA Neded. cont intr.' else '3' end) as denumire
	order by 1
	for xml raw
