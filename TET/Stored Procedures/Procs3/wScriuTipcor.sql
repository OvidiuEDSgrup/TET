--***
Create 
procedure wScriuTipcor  @sesiune varchar(50), @parXML xml
as 

Declare @subtip varchar(20), @dentipcor varchar(80), @tipcor varchar(2), @eroare xml, @mesajeroare varchar(100)

Set @subtip = @parXML.value('(/row/@subtip)[1]','varchar(13)')
Set @dentipcor = @parXML.value('(/row/@densubtip)[1]','varchar(30)')
Set @tipcor = @parXML.value('(/row/@tipcor)[1]','varchar(2)')

if exists (select 1 from sys.objects where name='wScriuTipcorSP' and type='P')  
	exec wScriuTipcorSP @sesiune, @parXML
else  
begin  
begin try  
select @mesajeroare = (case when @subtip is null then 'Subtip necompletat!' 
when @dentipcor is null then 'Denumire subtip necompletata!' 
when @tipcor is null then 'Tip corectie necompletat!' else '' end)

if @mesajeroare=''	
Begin
if exists (select * from subtipcor where subtip = @subtip)
Begin  
	update subtipcor set tip_corectie_venit = @tipcor, Denumire = @DenTipcor
	where subtip = @subtip
End  
else   
Begin    
 declare @subtip_par varchar(20)    
 if (@subtip is null)  	
	exec wmaxcod 'subtip','subtipcor',@subtip_par output
 else set @subtip_par=@subtip    
 insert into subtipcor (subtip, denumire, tip_corectie_venit)  
 values (@subtip_par,@dentipcor,@tipcor)  
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
