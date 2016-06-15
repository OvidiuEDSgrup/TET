--***
create procedure wStergCon @sesiune varchar(50), @parXML xml 
as

declare @cSub char(9), @mesajeroare varchar(100), @eroare xml, @stare0 varchar(100) 

exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output 
set @stare0=isnull((select rtrim(val_alfanumerica) from par where tip_parametru='UC' and parametru='STAREBK0'),'')

begin try

declare @iDoc int 
exec sp_xml_preparedocument @iDoc output, @parXML  
    
select @mesajeroare= 
(case 
-- nu e stare =0
when exists (select 1 from con c, OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(20) '@numar', 
  tert char(13) '@tert',
  cod char(20) '@cod',  
  data datetime '@data'  
 ) as dx  
where c.subunitate=dx.subunitate and c.tip=dx.tip and c.contract=dx.numar and c.tert=dx.tert and c.data=convert(datetime,dx.data,103) and stare>'0') 
	then 'Starea contractului/comenzii nu este 0-'+(case when @stare0='' then ' operat' else @stare0 end)+'!' 
-- are pozitii
when exists (select 1 from pozcon c, OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(20) '@numar', 
  tert char(13) '@tert',
  cod char(20) '@cod',  
  data datetime '@data' 
 ) as dx  
where c.subunitate=dx.subunitate and c.tip=dx.tip and c.contract=dx.numar and c.tert=dx.tert and c.data=convert(datetime,dx.data,103)) 
	then 'Contractul/comanda are pozitii!'
else '' end)

if @mesajeroare<>'' 	
	raiserror(@mesajeroare, 11, 1)

--if (@simulare='0') 
delete con from con c, OPENXML (@iDoc, '/row')  
 WITH  
 (  
  subunitate char(9) '@subunitate',   
  tip char(2) '@tip',   
  numar char(20) '@numar', 
  tert char(13) '@tert',
  cod char(20) '@cod',  
  data datetime '@data' 
 ) as dx  
where c.subunitate=dx.subunitate and c.tip=dx.tip and c.contract=dx.numar and c.tert=dx.tert and c.data=convert(datetime,dx.data,103) 

end try
begin catch
	declare @mesaj varchar(255)
	if isnull(@eroare.value('(/error/@coderoare)[1]', 'int'), 0) = 0
		--set @mesajeroare='<error coderoare="1" msgeroare="' + ERROR_MESSAGE() + '"/>'
		set @mesaj = ERROR_MESSAGE() 
	raiserror(@mesajeroare, 11, 1)
end catch
