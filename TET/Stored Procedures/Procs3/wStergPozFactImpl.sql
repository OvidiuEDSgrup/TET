--***
create procedure wStergPozFactImpl @sesiune varchar(50), @parXML xml
as

declare @factura varchar(20),@tip varchar(2),@data datetime,@tert varchar(13),@tiptert varchar(1),@Sub char(9),@mesaj varchar(200),
		@userAsis varchar(20),@an_impl int,@luna_impl int,@mod_impl int		

begin try
begin transaction
if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozFactImplSP')
	exec wStergPozFactImplSP @sesiune, @parXML output

select
		@factura = isnull(@parXML.value('(/row/row/@factura)[1]','varchar(20)'),''),
		@tert = isnull(@parXML.value('(/row/row/@tert)[1]','varchar(13)'),''),	
		@tip = isnull(@parXML.value('(/row/row/@tip)[1]','varchar(2)'),''),
		@tiptert = isnull(@parXML.value('(/row/row/@tiptert)[1]','varchar(1)'),''),
		@data=ISNULL(@parXML.value('(/row/row/@data)[1]', 'datetime'), '1901-01-01')
		
	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output	
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''
	
	if @mod_impl=0
		raiserror('Stergerea poate fi efectuata doar daca sunteti in mod implementare!!',11,1)	
	
	delete from factimpl where Subunitate=@Sub and tip=(case @tiptert when 'B' then 0x46 when 'F' then 0x54 else 0 end)
				and Factura=@factura and tert=@tert
		
	declare @docXML xml
	set @docXML='<row tiptert="'+RTRIM(@tiptert)+'"/>'
	exec wIaPozFactImpl @sesiune=@sesiune, @parXML=@docXML

commit transaction
end try
begin catch
   ROLLBACK TRAN	
		set @mesaj=ERROR_MESSAGE() 
		raiserror(@mesaj, 11, 1)
	--select @eroare FOR XML RAW
end catch
