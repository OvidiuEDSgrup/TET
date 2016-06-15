--***
create procedure wOPDefinitivare @sesiune varchar(50), @parXML xml 
as     
 
declare @definitivare varchar(1),@subtip varchar(2),@numar varchar(20),@tip varchar(2),@tert varchar(10),@contractcor varchar(20),
		@stare int ,@stareold varchar(1),@datadoc datetime
declare @iDoc int 

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

select @numar=numar ,@tip=tip, @tert=tert ,@datadoc=datadoc, @definitivare=definitivare
from OPENXML(@iDoc, '/parametri')
WITH 
(
		numar varchar(20)'./@numar',
		tert varchar(10)'./@tert',
		tip varchar(2)'./@tip',
		datadoc datetime'./@data',
		definitivare varchar(1)'./@definitivare'		
)
 
 select @stareold=isnull((select max(stare) from doc where Tip=@tip and Numar=@numar and Cod_tert=@tert and data=@datadoc),0)
 if @definitivare=0
  	select 'Bifati "definitivare " pentru ca documentul sa fie schimbat in starea 2-Definitiv!' as textMesaj for xml raw, root('Mesaje')
  if @stareold='2'
    select 'Documentul este deja in stare 2-Definitiv!' as textMesaj for xml raw, root('Mesaje') 	
 if @tip in ('AP','TE') and @definitivare=1
 begin
    select * from doc where Numar=@numar and Cod_tert=@tert and	Tip=@tip and data=@datadoc
     update doc set Stare='2' where Numar=@numar and Cod_tert=@tert and	Tip=@tip and data=@datadoc
 end
 exec sp_xml_removedocument @iDoc 
 
 
