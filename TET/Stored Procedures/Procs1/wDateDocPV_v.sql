--***
create procedure wDateDocPV_v @sesiune varchar(50),@parXML xml
as
declare @returnValue int
if exists(select * from sysobjects where name='wDateDocPV_vSP' and type='P')  
begin    
	exec @returnValue =  wDateDocPV_vSP @sesiune,@parXML
	return @returnValue 
end     

declare @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT, @tert varchar(50), @gest varchar(50), @lm varchar(50), @categPret varchar(50), @comanda varchar(50),
	@dengestiune varchar(100), @denlm varchar(100), @dencategpret varchar(100), @user varchar(100)

begin try

	exec wIaUtilizator @sesiune,@user output

	select	@categPret=ISNULL(@parXML.value('(/row/@categoriePret)[1]', 'int'), '1'), 
			@comanda=ISNULL(@parXML.value('(/row/@comanda)[1]', 'varchar(20)'), ''), 
			@gest=ISNULL(@parXML.value('(/row/@GESTPV)[1]', 'varchar(100)'),''),
			@lm=isnull(@parXML.value('(/row/@lm)[1]', 'varchar(100)'),'')
		
	if @lm<>'' and not exists (select * from lm where cod=@lm)
	begin
		set @ErrorMessage='Locul de munca operat('+@lm+') nu exista in catalogul de locuri de munca.'
		raiserror(@ErrorMessage,11,1)
	end
		
	--de facut validari...	
	select @parXML
		
end try
begin catch 
	SELECT @ErrorMessage = ERROR_MESSAGE()+' (wDateDocPV_v)', @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
	RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState )

end catch

	
	
