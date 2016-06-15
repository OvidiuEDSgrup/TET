--***
create procedure [dbo].[wStergMPdocpoz] @sesiune varchar(50), @parXML xml 
as  
  
Declare @mesajeroare varchar(100), @eroare xml 
declare @iDoc int 

begin try

exec sp_xml_preparedocument @iDoc output, @parXML  
    
select @mesajeroare= 
(case 
when exists (select 1 from mpdoc c, OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(8) '@numar', 
  data datetime '@data',    
  pozitie int '@pozitie'  
 ) as dx  
where c.subunitate=dx.subunitate and c.tip=dx.tip and c.numar=dx.numar and c.data=convert(datetime,dx.data,103) and (stare='I' or ISNULL((select count(1) from pozdoc where subunitate=c.subunitate and tip in ('CM', 'PP') and numar=c.numar and data=c.data), 0)>0)) 
	then 'Doc. este inchis!' 
else '' end)

if @mesajeroare<>'' 	
	raiserror(@mesajeroare, 11, 1)
	
delete mpdocpoz
from mpdocpoz p, 
OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(8) '@numar', 
  data datetime '@data', 
  pozitie int '@pozitie'
 ) as dx  
where p.subunitate = dx.subunitate and p.tip = dx.tip and p.numar = dx.numar and 
p.data = dx.data and (dx.pozitie is null or p.nr_pozitie = dx.pozitie)

update mpdoc set nr_pozitii=nr_pozitii-1
from OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(8) '@numar', 
  data datetime '@data'
 ) as dx  
where mpdoc.subunitate = dx.subunitate and mpdoc.tip = dx.tip and mpdoc.numar = dx.numar and 
mpdoc.data = dx.data

exec sp_xml_removedocument @iDoc   
  
exec wIaMPdocpoz @sesiune=@sesiune, @parXML=@parXML

end try
begin catch
	--ROLLBACK TRAN
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		set @mesaj = ERROR_MESSAGE() 
		--set @mesaj='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
	
	raiserror(@mesaj, 11, 1)
end catch
