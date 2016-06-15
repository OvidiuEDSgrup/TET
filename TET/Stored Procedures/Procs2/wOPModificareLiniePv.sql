--***
create procedure wOPModificareLiniePv @sesiune varchar(50),@parXML xml
as
if exists(select * from sysobjects where name='wOPModificareLiniePvSP' and type='P')  
begin    
	exec wOPModificareLiniePvSP @sesiune,@parXML output
	if @parxml is null
		return 0
end     

declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @tert varchar(50), @gest varchar(50), @lm varchar(50), @categPret varchar(50), @comanda varchar(50),
	@dengestiune varchar(100), @denlm varchar(100), @dencategpret varchar(100), @user varchar(100), @sub varchar(50)

begin try
	exec wIaUtilizator @sesiune,@user output
	
	--set @parxml.modify('replace value of (/row/@pretcatalog)[1] with "5"')

	select @parXML
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch

	
	
