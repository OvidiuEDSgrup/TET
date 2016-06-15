--***
Create 
procedure wScriuTipret @sesiune varchar(50), @parXML xml
as 

Declare @subtip varchar(20), @dentipret varchar(80), @tipret varchar(1), @eroare xml, @mesajeroare varchar(100)

Set @subtip = @parXML.value('(/row/@subtip)[1]','varchar(13)')
Set @dentipret = @parXML.value('(/row/@densubtip)[1]','varchar(30)')
Set @tipret = @parXML.value('(/row/@tipret)[1]','varchar(1)')

if exists (select 1 from sys.objects where name='wScriuTipretSP' and type='P')  
	exec wScriuTipretSP @sesiune, @parXML
else  
begin  
begin try  
select @mesajeroare = (case when @subtip is null then 'Subtip necompletat!' 
when @dentipret is null then 'Denumire subtip necompletata!' 
when @tipret is null then 'Tip retinere necompletat!' else '' end)

if @mesajeroare=''	
Begin
if exists (select * from tipret where subtip = @subtip)
Begin  
	update tipret set tip_retinere = @tipret, Denumire = @DenTipret
	where subtip = @subtip
End  
else   
Begin    
 declare @subtip_par varchar(20)    
 if (@subtip is null)  	
	exec wmaxcod 'subtip','tipret',@subtip_par output
 else set @subtip_par=@subtip    
 insert into tipret (subtip, denumire, tip_retinere, obiect_subtip_retinere)  
 values (@subtip_par,@dentipret,@tipret,'')  
End  
End
--Select @mesajeroare as mesajeroare for xml raw  
end try  
BEGIN CATCH  
	declare @mesaj varchar(254)
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
--SELECT  ERROR_MESSAGE() AS mesajeroare FOR XML RAW  
END CATCH  
end
