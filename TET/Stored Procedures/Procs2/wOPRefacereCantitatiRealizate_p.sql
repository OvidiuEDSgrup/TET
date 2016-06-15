--***
create procedure wOPRefacereCantitatiRealizate_p @sesiune varchar(50), @parXML xml 
as  
begin try
declare @fltContract varchar(20),@mesaj varchar(500),@tip varchar(2), @subtip varchar(2)

select 
	@fltContract=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
	@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '')	


select (case when @tip in ('BF','FA','BK','FC','BP') then  @fltContract else '' end) as fltContract, 1 as stergereRealizari, 1 as recalculareRealizari,
	(case when @tip='BF' then  1 else 0 end) as contracteBF, (case when @tip='FA' then  1 else 0 end) as contracteFA, (case when @tip='BK' then  1 else 0 end) as comenziLivrBK,
	(case when @tip='FC' then  1 else 0 end) as comenziAprovFC,(case when @tip='BP' then  1 else 0 end) as proformeBP
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
