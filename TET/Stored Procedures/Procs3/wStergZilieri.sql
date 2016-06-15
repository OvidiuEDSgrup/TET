--***
Create 
procedure wStergZilieri (@sesiune varchar(250), @parXML xml)
as

if exists (select 1 from sysobjects where [type]='P' and [name]='wStergZilieriSP')
	begin
		declare @returnValue int
		exec @returnValue=wStergZilieriSP @sesiune, @parXML output
		return @returnValue
	end

begin try
	declare @utilizator char(20), @mesaj varchar(80), @marca varchar(6)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	
	select @marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),'')		
	
	if exists (select 1 from SalariiZilieri where Marca=@marca)
		begin
			raiserror('Zilierul nu poate fi sters intrucat acesta are date in tabela SalariiZilieri!',11,1)
			return -1
		end
	else
		delete from Zilieri where marca=@marca	   	
end try

begin catch
	set @mesaj=ERROR_MESSAGE()
	raiserror(@mesaj,11,1) 
end catch
